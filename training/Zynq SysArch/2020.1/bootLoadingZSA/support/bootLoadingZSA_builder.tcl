#
###############################################################################
#
# software project builder for BootLoading lab
#
# todo:
#    update to Vitis
#
# history
#   2020/03/06 - WK - updated for Vitis in 2019.2
#   2019/12/03 - LR - updated to use sharedResources hardware and 2019.1
#   2018/01/09 - WK - cleaned up for 2018.1 release (and 2017.3 re-release)
#
###############################################################################
#

set badEnv 0

if {[catch {variable bootLoadingZSA $::env(bootLoadingZSA)} emsg]} {
   puts "ERROR!!! bootLoading environment variable not defined!";
   #set badEnv 1;
} else {
   regsub -all {\\} $bootLoadingZSA / bootLoadingZSA;
}

if {[catch {set trainingPath $::env(TRAINING_PATH)} emsg]} {
   puts "ERROR!!! TRAINING_PATH environment variable not defined!"
   set badEnv 1
} else {
   regsub -all {\\} $trainingPath / trainingPath;
   if {[string first : $trainingPath] == 1} {
      set trainingPath [string range $trainingPath 2 [string length $trainingPath]]; # strip the drive: from the path
   }
}

puts "Version 2020.1 - 2020/08/30";

# load the helper script (-quiet not supported in XSCT)
source $trainingPath/CustEdIP/vitis_helper.tcl

if {[info exists helper_loaded] != 1} {
   echo "Helper.tcl failed to load!";
   exit;
}

# set up description of projects
variable tcName        bootLoadingZSA
variable labName       $tcName
variable labOrDemo     lab
variable platName      bootLoadingZSA_plat
variable sysName       bootLoadingZSA_sys
variable domName       bootLoadingZSA_dom
variable appName       bootLoadingZSA_app
variable appTemplate  {Empty Application};
variable hwName        zed_hw;
variable hwSpec        $trainingPath/$tcName/support/sharedResources_zed.xsa;
variable processorName ps7_cortexa9_0;

variable projectPath          $trainingPath/$tcName/$labOrDemo;
variable supportPath          $trainingPath/$tcName/support;
variable workspaceName        $projectPath;

variable verbose              1;

# can't do the following from within the tool - only when running in the XSCT shell
# create a new workspace
#   puts "creating workspace";
#   setws -switch $workspace
#   puts "workspace created";

# clear the workspace
projRemove all;

# create a platform project from the XSA - if the project to build can't be found in the existing projects list, then ...	
platBuild;
 
# next build the Domain for this hardware
set libList ""; # for reference as to what this list looks like: { { xilffs fs_interface 2 } { xilffs ramfs_size 2098152000 } }
domBuild $libList;

platform generate;

# then build the application and load the provided files
set labSourceList  { bootLoadingZSA_main.c utils_print.c utils_print.h platform.c platform.h platform_config.h};
set demoSourceList { bootLoadingZSA_main.c utils_print.c utils_print.h platform.c platform.h platform_config.h};
if {[string compare -nocase $labOrDemo lab] == 0} { set filesToCopy $labSourceList; } else { set filesToCopy $demoSourceList; }
appBuild $filesToCopy;

# now that the projects are created, build everything related to this application
#app build -name $appName;

proc bootGenRun {} {
   variable verbose;
   if {$verbose} { puts "bootLoadingZSA_builder.bootGenRun"; }
   set bifPath $::env(bootLoadingZSA)/lab/bootLoadingZSA_app/_ide/bootimage/bootLoadingZSA_app.bif;
   set cmd "bootgen"; # -image $bifPath -arch zynq -o $::env(bootLoadingZSA)/lab/BOOT.bin";
   set args "-image $bifPath -arch zynq -o $::env(bootLoadingZSA)/lab/BOOT.bin -w";
   exec $cmd $args;
}

proc QEMUverBuild {} {
   variable verbose;
   if {$verbose} { puts "bootLoadingZSA_builder.QEMUverBuild"; }
   variable tcName;

   cd $::env($tcName)/lab;
   set cmd dd;
   set args "if=/dev/zero of=qemu_spi.bin bs=64M count=1";
   exec $cmd $args;
   set args "if=BOOT.bin of=qemu_spi.bin bs=1 seek=0 conv=notrunc";
   exec $cmd $args;
   
   # execute script script4.sh

}

# done
puts "Done with bootLoadingZSA_builder.tcl";
