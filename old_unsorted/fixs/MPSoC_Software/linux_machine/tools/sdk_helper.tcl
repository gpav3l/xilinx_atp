#
###############################################################################
#
# software helper procs for building SDK projects
#
# includes:
#   createWorkspace
#   createHWprojectFromHDF
#   createBSP
#   addLibraryToBSP
#   createApp
#
# Notes:
#    importSources seems to have problems under 2017.1. Workaround is to force a copy using the OS
#
# History:
#    2017-10-26 - WK - updated for 2017.3 (with tweaks to importSources)
#    2017-04-17 - WK - updated for 2017.1
#    2016-12-30 - LR - Added multiple commands
#    2016-07-11 - WK - initial
#
###############################################################################
#

#!/usr/bin/tclsh

# identify if this script is being run from windows or linux
if {[file isdirectory /media/sf_training]} {
   source /media/sf_training/tools/helper.tcl;     # load the helper script 
} else {
   source c:/training/tools/helper.tcl;            # load the helper scripts
}

variable failedOperation 
set failedOperation none

variable debug
set debug 1
proc displayVersion {} { puts "Version: 2017-10-26 1722"; }
puts [displayVersion]

#
# templates for stand-alone applications
# use "repo -apps" to see all applicaitons
variable helloWorld_template  {Hello World}
variable empty_app_template   {Empty Application}
variable periphTest_template  {Peripheral Tests}
variable fsbl_template        {Zynq FSBL}
variable PMU_fw_template      {ZynqMP PMU Firmware}

#########################################################################
#
# proc for removing directory and everything in it
#
#    recursive directory wipe - equivalent to rm -r
#
#########################################################################
proc clearWorkspace { target } {
   variable debug
   if {$debug} { puts "clearing workspace"; }
   if {[file isdirectory $target]} {
      file delete -force $target
   } else {
      puts "Directory $target does not exist therefore clearWorkspace has nothing to work on"
   }
}

proc createWorkspace { workspaceName } {
   variable debug
   if {$debug} { puts "Setting SDK workspace to: '$workspaceName'" }
	  
   # 
   setws -switch $workspaceName
}

# this whole proc may not be needed as the default hwproj names may be used
proc createHWprojectFromDefaults { HWprojName platformName } {
   variable debug
   if {$debug} { puts "Building the HW project named '$HWprojName' from defaults for: '$platformName'" }
   
   # select hardware spec option based on platform name
   set HDFname ""
   set xilinxToolInstallPath /Xilinx1/SDK/2017.1/data/embeddedsw/lib/hwplatform_templates/   
   if {[strsame ZC702  $platformName]} { 
      append HDFname $xilinxToolInstallPath "ZC702_hw_platform/system.hdf" 
   } elseif {[strsame Zed    $platformName]} { 
      append HDFname $xilinxToolInstallPath "zed_hw_platform/system.hdf" 
   } elseif {[strsame ZCU102 $platformName]} { 
      append HDFname $xilinxToolInstallPath "ZCU102_hw_platform/system.hdf" 
   } else {
      puts "Unsupported platform! $platformName\nCannot generate hardware project\nSupported platforms: Zed, ZC702, ZCU102"
	  exit 1
   }
   
   # build the command - much cleaner code when run
   set cmd ""
   append cmd sdk " " createhw " " -name " " $HWprojName " " -hwspec " " $HDFname
   
   # run the command and catch/report errors
   if {[catch $cmd resultingText]} {
      set einfo $::errorInfo
      set ecode $::errorCode
      puts stderr "could not create the hardware project!"
	  set failedOperation "hardware creation: $resultingText\n\t$einfo, $ecode"
   } else {
      puts "hardware project successfully created"
	  puts "returned message: $resultingText"
	  set failedOperation none
   }
} 

proc createHWprojectFromHDF {HWprojName HDFname} {	
   variable debug
   if {$debug} { puts "Building the HW project named '$HWprojName' from HDF file: '$HDFname'" }
   sdk createhw -name $HWprojName -hwspec $HDFname
}

proc createBSP {bspName HWprojName processor OS} {
   variable debug
   if {$debug} { puts "Building the BSP project named '$bspName' based on: '$HWprojName'" }
   sdk createbsp -name $bspName -hwproject $HWprojName -proc $processor -os $OS
}

# proc addLibraryToBSP {bspName HWprojName libraryName} {
# Changed by LR in 2016.3 - original command made no sense
proc addLibraryToBSP {bspName libraryName} {
   variable debug
   if {$debug} { puts "Adding library service '$libraryName' to BSP '$bspName'" }
#   sdk configbsp -lib $libraryName -hw $HWprojName -bsp $bspName
# Changed by LR in 2016.3 - original command made no sense
   setlib -bsp $bspName -lib $libraryName
}

proc updateMssAndRegenerateBSP {mssLocation} {
   variable debug
   if {$debug} { puts "Updating the system.mss file '$mssLocation' and regenerating the bsp" }
   updatemss -mss $mssLocation
   regenbsp -bsp $mssLocation
}

proc createApp {appName templateName HWprojName bspName processor OS} {
   variable debug
   if {$debug} { puts "Building Application project named '$appName' based on '$templateName' template and existing '$bspName' BSP" }
   if {[catch {sdk createapp -name $appName -hwproject $HWprojName -proc $processor -os $OS -lang C -app $templateName -bsp $bspName} errString]} {
      puts "Error caught when creating application $appName: $errString"
	  puts "errorInfo: $::errorInfo"
	  puts "errorCode: $::errorCode"
   } else {
      puts "successfully created application $appName"
   } 
}

proc createAppAndBSP {appName templateName HWprojName processor OS} {
   variable debug
   if {$debug} { puts "Building Application project named '$appName' based on '$templateName' template and created BSP" }
   set cmd [concat sdk createapp -name $appName -app \{$templateName\} -proc $processor -hwproject $HWprojName -os $OS]
   puts "createAppAndBSP: $cmd"
   
   # run the command
   #$cmd
   sdk createapp -name $appName -app $templateName -proc $processor -hwproject $HWprojName -os $OS
#   sdk createapp -name $appName -app \{$templateName\} -proc $processor -hwproject $HWprojName -os $OS
   
   # if {[catch {sdk createapp -name $appName -app \{$templateName\} -proc $processor -hwproject $HWprojName -os $OS} errString]} {
      # puts "Error caught when creating application and BSP $appName: $errString"
	  # puts "errorInfo: $::errorInfo"
	  # puts "errorCode: $::errorCode"
   # } else {
      # puts "successfully created application and BSP: $appName"
   # }     
}

proc importSources {appNamePath sourceFileList} {
   puts "sdk_helper.importSources"
   variable debug
   if {$debug} { 
      puts "Importing into $appNamePath from $sourceFileList' "; 
      puts "sdk_helper.importSources *patch - retest with sdk importsources*"; 
   }
   # doesn't seem to work in 2017.1
  # sdk importsources -name $appName -path $importSourceFile
   # copying the source files into the proper project directory
   # note: appName is used as a path to where the source files are to be loaded
   foreach sourceFile $sourceFileList {
     # pull the source file name from the full path of the source file
	  set pos [strLastIndex $sourceFile /]
	  set len [string length $sourceFile]
	  set fileName [string range $sourceFile [expr $pos + 1] $len]
     puts "copy $fileName from given source to destination"
     
     # set the destination path and append the fileName that we just extracted
	  set destinationFile ""
	  append destinationFile $appNamePath / $fileName
     
     # is this a valid source file name?
     if {[isFile $sourceFile]} {
        # is there a destination directory to place this file?
        if {[directoryExists $appNamePath]} {
     	     # add the name to the end of the appNamePath
	        copyIfNewer $sourceFile $destinationFile
        } else {
           puts "=====>>>>> Don't see the destination directory: $appNamePath"
        }
     } else {
        puts "=====>>>>> Can't find the source file: $sourceFile";
     }
     
   }   
}

proc sourcesAdd {appNamePath sourceFilePath sourceFileList} {
   puts "sdk_helper.sourcesAdd"
   variable debug
   if {$debug} { 
      puts "adding into $appNamePath from $sourceFilePath' "; 
      puts "sdk_helper.sourcesAdd *patch - retest with sdk importsources*"; 
   }
   
   set usingDED 0
   
   # doesn't seem to work in 2017.1
  # sdk importsources -name $appName -path $importSourceFile
   # copying the source files into the proper project directory
   # note: appName is used as a path to where the source files are to be loaded
   foreach sourceFile $sourceFileList {
      # does this file need to be modified by a ded script?
      set firstCharacterOfFileName [string index $sourceFile 0]
      if {$firstCharacterOfFileName == '*'} {
         # remove the asterisk and use the directedEditor
         set sourceFile [string range $sourceFile 1 [string length $sourceFile]]
         set usingDED 1
      } else {
         usingDED 0
      }
      
     # pull the source file name from the full path of the source file
	  #set pos [strLastIndex $sourceFile /]
	  #set len [string length $sourceFile]
	  #set fileName [string range $sourceFile [expr $pos + 1] $len]
     #puts "copy $fileName from given source to destination"
     set sourceFileName $sourceFilePath/$sourceFile
     
     # set the destination path and append the fileName that we just extracted
	  set destinationFile ""
	  append destinationFile $appNamePath / $sourceFile
     
     # is this a valid source file name?
     if {[isFile $sourceFileName]} {
        # is there a destination directory to place this file?
        if {[directoryExists $appNamePath]} {
     	     # add the name to the end of the appNamePath
	        copyIfNewer $sourceFileName $destinationFile
        } else {
           puts "=====>>>>> Don't see the destination directory: $appNamePath"
        }
     } else {
        puts "=====>>>>> Can't find the source file: $sourceFile";
     }
     
   }   
}

proc buildAll {} {
   variable debug
   if {$debug} { puts "Building entire workspace" }
   sdk projects -build -type all
}

proc buildBspProject {bspName} {
   variable debug
   if {$debug} { puts "Building BSP '$bspName'" }
   sdk projects -build -type bsp -name $bspName
}

proc buildAppProject {appName} {
   variable debug
   if {$debug} { puts "Building application '$appName'" }
   sdk projects -build -type app -name $appName
}

proc InsertELfinBitstream {BitFileBlockRamConfig BitFileBlank BitFileBlockRamElf processor BitFileWithELF} {
   variable debug
   if {$debug} { puts "Inserting ELF application '$BitFileBlockRamElf'into bitstream" }
   exec updatemem -force -meminfo $BitFileBlockRamConfig -bit $BitFileBlank -data $BitFileBlockRamElf -proc $processor -out $BitFileWithELF
}

proc linkLibraryToApplication { app library } {
   variable debug
   if {$debug} { puts "Inserting library '$library' into application '$app'" }
   configapp -app $app -add libraries $library
}

proc GenerateBinFile {BootImageBIF BootImageBIN} {
   variable debug
   if {$debug} { puts "Generating BOOT.bin for SD Card or Flash" }
   exec bootgen -arch zynq -image $BootImageBIF -w -o $BootImageBIN
}

proc getPlatforms {} {
   set platformList {}
   if {[catch {set successState [createapp -name a9_hello -proc ps7_cortexa9_0 -hwproj xxx]} result]} {
      # pull off error message portion by searching for "platforms are "
      set loc [expr [strPosition $result "platforms are "] + 14]
      set platforms [substr $result $loc [strlen $result]]
      # remove spaces
      set cleaned [strReplace $platforms ", " ","]
      # break string into a list
      set list [commaSeparatedStringToList $cleaned]
   }  
   return $list
}