#
# ***********************************************************************
#
# script for performing the common tasks that completer scripts require
#    
#   originally written to support the rapid development of both generic designs as well as the Unified Embedded Design
#
# ----- Alphabetic Listing of Procs -----
#
#       applyZynqProcessorPreset { }
#       bitstreamRun { }
#       blockDesignCreate { }
#       blockDesignSave { }
#       blockDesignWrap { }
#       BRAMadd { }
#       buildStartingPoint { }
#       buttonsRosettaAdd { }
#       clearAll { }
#       constraintFilesAdd { constraintFileList }
#       constraintFilesDefaultAdd { }
#       designExport { }
#       hardwareManagerOpen { }
#       implementationRun { }
#       LEDsLinearAdd { }
#       LEDsRosettaAdd { }
#       make { stopAfterStep }
#       makeStep { stepToDo }
#       MIGadd { }
#       XXXnextTerminator { str } - moved to helper and obsoleted
#       processorAdd { }
#       processorBlockAutomationRun { }
#       processorConfigure { }
#       processorDefaultConnect { }
#       projectCreate { }
#       reGenLayout { }
#       SDKlaunch { }
#       simSourceListAdd { sourceList }
#       simulationRun { }
#       sourcesAdd { sourceList }
#       switchesLinearAdd { }
#       synthesisRun { }
#       UARTadd { }
#       UARTaddConditional { }
#       use { }
#       VIOadd { }
#       VivadoClose { }
#       VivadoCloseProject { }
#
# ----------
#
#   note naming convention - nounVerb. This organizes the information by item then by what happens to that item
#   index: ("global" varaibles identified in curly braces)
#      projectCreate - {tcName, labName, language, verbose, platform, demoOrLab} to assemble a project
#      blockDesignCreate - {blockDesignName} to create an empty block design
#      sourcesAdd sourceList - adds HDL source files. If extension not specified then $language is used to append proper extension
#      processorAdd      - {platform, processor, tcName, verbose} to add the designated processor to the block design
#      processorConfigure - uses variable activePeripheralsList to enable selected peripherals
#      reGenLayout
#      processorBlockAutomationRun
#      blockDesignWrap
#      constraintFilesAdd(comma separated list of file names)
#      synthesisRun
#      implementationRun
#      bitstreamRun
#      designExport
#      SDKlaunch
#      VivadoClose
#
#     procs specific to the Embedded ULD 
#      VIOadd
#      LEDsLinearAdd
#      buttonsRosettaAdd
#      LEDsRosettaAdd
#      switchesLinearAdd
#      UARTadd
#      BRAMadd
#
# *** assistance routines:
#    makeStep # - builds only step #
#    make # | all - builds everything upto and including #. "all" will build everything
#
# **************** "global" variables ******************
#    platform
#    tcName
#    language
#    processor
#    labOrDemo  (--> isLab?)
#
#
# History:
#    2020.1    - AM - 2020/07/16 - Fixed sourcing failure due to wrong variable check custEdIP instead of CustEdIP - line 144
#    2020.1    - WK - 2020/06/05 - migrated use, loadedProcs, and make to helper script (as helper script loaded when this script is opened)
#    2019.2    - WK - 2020/01/22 - fixed designExport
#    2019.2    - WK - 2020/01/14 - moved "USE" to script; tests for helper script being loaded and if not, loads it
#    2019.2    - WK - 2019/11/21 - added BRAMadd
#    2019.1    - LR - 2019/11/12 - added additional terms for zeroing the MPSoC
#    2019.1    - WK - 2019/10/28 - added support for environment variables, removed extra /training layer as it is now defined by $trainingPath
#    2019.1    - WK - 2019/06/09 - fixed make All (issue with dealing with arguments in the list)
#    2019.1    - WK - 2019/06/11 - updated LEDsLinearAdd for ZCU102
#    2019.1    - WK - 2019/05/06 - added support for ZCU111 and ZCU102. minor code cleanup. 
#    2019.1    - OB,NK,WK - 2019/03/?? - documenting and general cleanup
#    2018.3    - LR - 2019/02/06 - fixed Xparernt cell gneration and unused interrupt input
#    2018.3    - WK - 2019/01/22 - cleaned up problems associated with MicroBlaze processor selection
#    2018.3    - AM - 2019/01/16 - Added Linux paths 
#    2018.1a   - WK - 2018/05/02 - added RFSoC support in USE
#    2018.1    - LR - 2018/04/16 - Fixed blockDesignWrap for proper operation
#    2017.3    - WK - 2017/10/16 - "make" now works with comma separated list of arguments within parenthesis constraintFilesAdd(file1,file2,...); got constraintFilesAdd working
#    2017.3    - WK - 2017/09/14 - deprecation of "makeTo" and "makeToEndOfStep"
#    2016.3    - WK - 2017/01/13 - addition of new procs, further testing of existing procs, includsion of UED similar capabilities
#    initial   - WK - 2016/11/10 - based on many other completer scripts
#
# ***********************************************************************
#

# todo: test is helper.tcl is loaded, if not, source it.

set completer_helper_loaded 0;      # have a defineable variable to check for success or failure of this load
set suppressLogErrors       1;

puts "2020.1 - preliminary";

if {![info exists loadedProcs]} {
   puts "loadedProcs variable not defined - will define it in completer_helper";
   variable loadedProcs {};
}

# the vitisHelper script needs the helper.tcl script
if {![info exists trainingPath]} {
   puts "trainingPath variable not found. this needs to be defined before loading completer_helper.";
   puts "cannot continue...";
   exit 0;
} 

puts "Starting load of completer_helper.tcl";
if {![info exists helper_loaded]} {
   puts "loading helper.tcl which includes supporting procs used by the completer_helper script";
   source $trainingPath/CustEdIP/helper.tcl
} else {
   puts "helper.tcl already loaded. Continuing with the loading of completer_helper."
}   

if {[catch {set custEdIP $::env(CustEdIP)} emsg]} {
   puts "ERROR!!! custEdIP environment variable not defined!"
   set badEnv 1
} else {
   regsub -all {\\} $custEdIP / custEdIP;
      if {[string first : $custEdIP] == 1} {
      set custEdIP [string range $custEdIP 2 [string length $custEdIP]]; # strip the drive: from the path
   }
}

if {[catch {set Version $::env(VERSION)} emsg]} {
   puts "ERROR!!! VERSION environment variable not defined!"
   set badEnv 1
} else {
   regsub -all {\\} $Version / Version
}

if {$badEnv} {
    puts -nonewline "Hit Enter to exit ==> "
    flush stdout
    gets stdin
	exit 1
}

# 
# data set to turn everything in the Zynq device off (except clock and reset which may be needed by the microBlaze)
variable ZynqAllOff {CONFIG.PCW_USE_M_AXI_GP0                     0
                     CONFIG.PCW_USE_M_AXI_GP1                     0
                     CONFIG.PCW_USE_S_AXI_GP0                     0
                     CONFIG.PCW_USE_S_AXI_GP1                     0
                     CONFIG.PCW_USE_S_AXI_ACP                     0
                     CONFIG.PCW_USE_S_AXI_HP0                     0
                     CONFIG.PCW_USE_S_AXI_HP1                     0
                     CONFIG.PCW_USE_S_AXI_HP2                     0
                     CONFIG.PCW_USE_S_AXI_HP3                     0
                     CONFIG.PCW_EN_CLK0_PORT                      0
                     CONFIG.PCW_EN_CLK1_PORT                      0
                     CONFIG.PCW_EN_CLK2_PORT                      0
                     CONFIG.PCW_EN_CLK3_PORT                      0
                     CONFIG.PCW_EN_RST0_PORT                      0
                     CONFIG.PCW_EN_RST1_PORT                      0
                     CONFIG.PCW_EN_RST2_PORT                      0
                     CONFIG.PCW_EN_RST3_PORT                      0
                     CONFIG.PCW_QSPI_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_NAND_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_NOR_PERIPHERAL_ENABLE             0
                     CONFIG.PCW_ENET0_PERIPHERAL_ENABLE           0
                     CONFIG.PCW_ENET1_PERIPHERAL_ENABLE           0
                     CONFIG.PCW_SD0_PERIPHERAL_ENABLE             0
                     CONFIG.PCW_SD1_PERIPHERAL_ENABLE             0
                     CONFIG.PCW_USB0_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_USB1_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_UART0_PERIPHERAL_ENABLE           0
                     CONFIG.PCW_UART1_PERIPHERAL_ENABLE           0
                     CONFIG.PCW_SPI0_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_SPI1_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_CAN0_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_CAN1_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_WDT_PERIPHERAL_ENABLE             0
                     CONFIG.PCW_TTC0_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_TTC1_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_USB0_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_USB1_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_I2C0_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_I2C1_PERIPHERAL_ENABLE            0
                     CONFIG.PCW_GPIO_MIO_GPIO_ENABLE              0
                     CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE             0        
                    }
#
# data set for the MPSoC ZUS+ device - turns off all of the options
variable MPSoCallOff { CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE  0   
                       CONFIG.PSU__ENET1__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__ENET2__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__ENET3__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE    0
                       CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE    0
                       CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE    0
                       CONFIG.PSU__GPIO2_MIO__PERIPHERAL__ENABLE    0
                       CONFIG.PSU__CAN0__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__CAN1__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__I2C0__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__I2C1__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__PCIE__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__PJTAG__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__PMU__PERIPHERAL__ENABLE          0
                       CONFIG.PSU__QSPI__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__SATA__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__SD0__PERIPHERAL__ENABLE          0
                       CONFIG.PSU__SD1__PERIPHERAL__ENABLE          0
                       CONFIG.PSU__SPI0__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__SPI1__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__SWDT0__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__SWDT1__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__TTC0__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__TTC1__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__TTC2__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__TTC3__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__UART0__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__UART1__PERIPHERAL__ENABLE        0
                       CONFIG.PSU__USB0__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__USB1__PERIPHERAL__ENABLE         0
                       CONFIG.PSU__FPGA_PL0_ENABLE                  0
                       CONFIG.PSU__USE__IRQ0                        0
                       CONFIG.PSU__USE__M_AXI_GP0                   0
                       CONFIG.PSU__USE__M_AXI_GP1                   0
                       CONFIG.PSU__USE__M_AXI_GP2                   0
                       CONFIG.PSU__USE__S_AXI_GP0                   0
                       CONFIG.PSU__USE__S_AXI_GP1                   0
                       CONFIG.PSU__USE__S_AXI_GP2                   0
                       CONFIG.PSU__USE__S_AXI_GP3                   0
                       CONFIG.PSU__USE__S_AXI_GP4                   0
                       CONFIG.PSU__USE__S_AXI_GP5                   0
                       CONFIG.PSU__USE__S_AXI_GP6                   0
                       CONFIG.PSU__USE__FABRIC__RST                 0
               }
lappend loadedProcs ZynqAllOff MPSoCallOff

#
# ********** Create the New Project
#

#/**
# * proc:  projectCreate
# * descr: 
# * @meta <list of searchable terms> 
# */
proc projectCreate {} {
   # get the globally defined variables
   variable tcName
   variable labName
   variable language
   variable verbose
   variable platform
   variable processor 
   variable demoOrLab
   variable trainingPath
   variable projName
   
   if {$verbose} { puts "completer_helper.projectCreate"; }   
   
   # close the project if one is open
   if { [catch { set nProjects [llength [get_projects -quiet -verbose *]]} fid] } {
      puts stderr "error caught!"
      puts $fid
   } else {
      if {$nProjects > 0} {
        if {$verbose} { puts "project is open and will try to close it" }
           close_project
      } else {
       #if {$verbose} { puts "no projects to close. Continuing with creation of new project" }
     }
   }   
   
   # check if both a language and platform has been selected
   set isLangNotSelected [strsame $language "undefined"]
   set isPlatNotSelected [strsame $platform "undefined"]
   
   set isverilog    [string compare -nocase $language "verilog"]
   set isvhdl       [string compare -nocase $language "vhdl"]
   
   set isZed             [strsame $platform "ZED"]
   set isZC702           [strsame $platform "ZC702"]
   set isUBlaze          [strsame $processor "MicroBlaze"]; #   -- processor not carried into this proc
   set isZCU102          [strsame $platform "ZCU102"]
   set isZCU104          [strsame $platform "ZCU104"]
   set isZCU111          [strsame $platform "ZCU111"]
   
   # obsoleted boards
   set isKCU105          [strsame $platform "KCU105"]
   set isKC705           [strsame $platform "KC705"]
   set isKC7xx           [strsame $platform "KC7xx"]
      
   # ensure that the language has been selected
   if {$isLangNotSelected} {
      puts "Please type: use VHDL | Verilog"
      puts "   then rerun the projectCreate"
   } elseif {$isPlatNotSelected} {
      puts "Please type: use ZCU102 | ZCU111 | ZC702 | Zed | ZCU104 -- note: other boards exist, but have been deprecated";  
      puts "   then rerun the projectCreate"
   } else {
     # future - verify that "latestVersion" will work for the boards
     if {$isZed} {
         create_project -force $labName $trainingPath/$tcName/$demoOrLab -part xc7z020clg484-1
         set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
     } elseif {$isZC702} {
         create_project -force $labName $trainingPath/$tcName/$demoOrLab -part xc7z020clg484-1
         set_property board_part xilinx.com:zc702:part0:1.2 [current_project] 
     } elseif {$isZCU102} {
         create_project -force $labName $trainingPath/$tcName/$demoOrLab -part xczu9eg-ffvb1156-2-e
         set_property board_part xilinx.com:zcu102:part0:3.2 [current_project]       
     } elseif {$isZCU104} {
         create_project -force $labName $trainingPath/$tcName/$demoOrLab -part xczu7ev-ffvc1156-2-e
         set_property board_part xilinx.com:zcu104:part0:1.1 [current_project]
    } elseif {$isZCU111} {
         create_project -force $labName $trainingPath/$tcName/$demoOrLab -part xczu25dr-ffve1156-1-i
         set_property target_language VHDL [current_project]     
     } elseif {$isKCU105} {
         create_project -force $projName $trainingPath/$tcName/$demoOrLab/$platform/$language -part xcku040-ffva1156-2-e
         set_property board_part xilinx.com:kcu105:part0:1.5 [current_project]
    } elseif {$isKC705} {
         create_project -force $projName $trainingPath/$tcName/$demoOrLab/$platform/$language -part xc7k325tffg900-2
       set_property board_part xilinx.com:kc705:part0:1.6 [current_project] 
    } elseif {$isKC7xx} {
         create_project -force $projName $trainingPath/$tcName/$demoOrLab/$platform/$language -part xc7k70tfbg484-2 
    }
    
     # with the project now open, set the default language
      set_property target_language $language [current_project]
   }

   markLastStep projectCreate
}
lappend loadedProcs {projectCreate "creates a project based on the globally defined variables"};
#
# ********** Create a Block Design
#
#/**
# * proc:  blockDesignCreate
# * descr: 
# * @meta <list of searchable terms> 
# */
proc blockDesignCreate {} {
   variable verbose
   if {$verbose} { puts "completer_helper.blockDesignCreate"; } 
   variable blockDesignName
   
   # create Block Design - test to see if "blkDsgn" exists and skip if it does
   # note: this only tests to see if a block design exists - it doesn't test for the specific block design name
   set blkDsgns [get_bd_designs -quiet]
   if {[llength $blkDsgns] == 0} {
      create_bd_design $blockDesignName 
      update_compile_order -fileset sources_1     
   }
  
   markLastStep blockDesignCreate
}
lappend loadedProcs {blockDesignCreate "creates a block design based on the globally defined variables"};
#
# *********** save the block design
#
#/**
# * proc:  blockDesignSave
# * descr: 
# * @meta <list of searchable terms> 
# */
proc blockDesignSave {} {
   variable verbose
   if {$verbose} { puts "completer_helper.blockDesignSave"; } 
   save_bd_design
   markLastStep save_bd_design;
}
lappend loadedProcs {blockDesignSave "saves the current block design"};
#/**
# * proc: moduleCreateFromHDL
# * descr: creates an IP block from an HDL file and adds it to the canvas
# * @meta HDL block module create make 
# * @param hdlFileName - name of file to convert to an IP module (typically with path and extension)
# * @param moduleName  - name of the module
# * @return - true if successful, false if not (typically file not found)
# **/
proc moduleCreateFromHDL {hdlFileName moduleName} {
   variable tcName
   variable verbose
   if {$verbose} { puts "completer_helper.moduleCreateFromHDL"; } 
   #update_compile_order -fileset sources_1
   if {[fileExists $hdlFileName]} {
      # extract IPname from the file name
      set onlyFileName [getLastHierarchy $hdlFileName]
      set IPname       [stripExtension $onlyFileName]
      add_files -norecurse $hdlFileName
      update_compile_order -fileset sources_1
      create_bd_cell -type module -reference $IPname $moduleName
      return true
   }
   return false
}
lappend loadedProcs {moduleCreateFromHDL "turns an HDL file into an IP block"};
#
# ********** add source files
#   source files in list may include extensions or not
#   if no extensions are found, then the language is used to identify what the extension should be and this extension is appended to the file name
#/**
# * proc:  sourcesAdd
# * descr: 
# * @meta <list of searchable terms> 
# * @param sourceList   if the elements in the list don't have the hierarchy path, then the $tcName/support directory is assumed
# */
proc sourcesAdd { sourceList } {
   variable trainingPath
   variable verbose 
   if {$verbose} { puts "completer_helper.sourcesAdd $sourceList"; } 
   variable language
   variable tcName
   
   # set selected language
   set isVHDL [strcmp $language vhdl]
   set isVerilog [strcmp $language verilog]
   
   # load all the files from the source list from the support directory unless a full path is specified
   foreach fileName $sourceList { 
      # is there a full path provided? - Does not make corrections for langauage - assumes user knows what he/she's doing
     set hierarchyList [hierarchyToList $fileName]
     if {[llength $hierarchyList] > 1} {        # a hierarchy has been presented so use it instead of the support directory 
        set useThisFile $ 
     } else {  
        # no, so assume that we are pulling from the support directory
        set fullFileName ""
        append fullFileName $trainingPath/$tcName/support/ $fileName
        #if there isn't an extension, then add one based on the selected language    
         set isVHDLsource [strEndsWith $fileName .vhd]
         set isVerilogSource [strEndsWith $fileName .v]
         set isTextSource [strEndsWith $fileName .txt]
         
        if {$isVHDLsource == 0 && $isVerilogSource == 0 && $isTextSource == 0} {    
           if {$isVHDL == 1} { append fullFileName .vhd }
           if {$isVerilog == 1} { append fullFileName .v }
        }
         
        # this line copies the file to the local working directory keeping the original file unchanged     
        set useThisFile $fullFileName
      }
     import_files -norecurse $useThisFile
   }   
}
lappend loadedProcs {sourcesAdd "adds the list of sources to the project"};
#
# ********** add simulation files
#   simulation source files in list may include extensions or not
#   if no extensions are found, then the language is used to identify what the extension should be and this extension is appended to the file name
#/**
# * proc:  simSourceListAdd
# * descr: 
# * @meta <list of searchable terms> 
# * @param sourceList  
# */

# debug: why is this here? todo: remove?
proc ssla { sourceList } {
 variable verbose 
   if {$verbose} { puts "completer_helper.ssla $sourceList"; } 
   variable language
   variable tcName
   variable trainingPath                            
   
   # set selected language
   set isVHDL [strsame $language vhdl]
   set isVerilog [strsame $language verilog]
   
   # load all the files from the source list from the support directory unless a full path is specified
   foreach fileName $sourceList { 
      # is there a full path provided? - Does not make corrections for langauage - assumes user knows what he/she's doing
      puts "simSourcesListAdd: adding $fileName"
   }
}
lappend loadedProcs {ssla "adds simulation files"};
#/**
# * proc:  simSourceListAdd
# * descr: 
# * @meta <list of searchable terms> 
# * @param sourceList  if the elements in the list don't have the hierarchy path, then the $tcName/support directory is assumed
# */
proc simSourceListAdd { sourceList } {
   variable verbose 
   if {$verbose} { puts "completer_helper.simSourceListAdd $sourceList"; } 
   variable language
   variable tcName
   variable trainingPath                            
   
   # set selected language
   set isVHDL [strsame $language vhdl]
   set isVerilog [strsame $language verilog]
   
   # load all the files from the source list from the support directory unless a full path is specified
   foreach fileName $sourceList { 
      # is there a full path provided? - Does not make corrections for langauage - assumes user knows what he/she's doing
      puts "simSourcesListAdd: adding $fileName"
      set hierarchyList [hierarchyToList $fileName]
      #puts "length of heirarchy list = [llength $hierarchyList]"
      if {[llength $hierarchyList] > 1} {        # a hierarchy has been presented so use it instead of the support directory         
        set useThisFile $fileName;   #[stripLastHierarchy $fileName]
        puts "using $useThisFile as the file name and path"
      } else {  
        # no, so assume that we are pulling from the support directory
        set fullFileName ""
        append fullFileName $trainingPath/$tcName/support/ $fileName
        #if there isn't an extension, then add one based on the selected language    
         set isVHDLsource    [strEndsWith $fileName .vhd]
         set isVerilogSource [strEndsWith $fileName .v]
         set isTextSource [strEndsWith $fileName .txt]                                      
        if {!($isVHDLsource) && !($isVerilogSource) && !($isTextSource)} {     
           if {$isVHDL}    { append fullFileName .vhd }
           if {$isVerilog} { append fullFileName .v }
        }
        # the following line uses the source from where it is
        #add_files -norecurse $fullFileName
        # this line copies the file to the local working directory keeping the original file unchanged     
        set useThisFile $fullFileName
      }
     import_files -fileset sim_1 -norecurse $useThisFile
     update_compile_order -fileset sim_1
   }   
   markLastStep simSourceListAdd
}
lappend loadedProcs {simSourceListAdd "adds a list of files as simulation sources"};
#/**
# * proc:  constraintFilesDefaultAdd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc constraintFilesDefaultAdd {} {
   variable tcName
   variable trainingPathproces
   variable trainingPath
   variable processor
   variable platform
   variable verbose
   if {$verbose} { puts "completer_helper.constraintFilesDefaultAdd"}
   
   # default constraint files
   set isZed        [strsame $platform ZED]
   set isZC702      [strsame $platform ZC702]
   set isZCU104     [strsame $platform ZCU104]
   
   if {$isZCU104} {
      add_files -fileset constrs_1 -norecurse $trainingPath/CustEdIP/ZCU104_base.xdc
   } elseif {$isZC702} {
     #add_files -fileset constrs_1 -norecurse $trainingPath/training/$tcName/support/ZC702_base.xdc
     add_files -fileset constrs_1 -norecurse $trainingPath/CustEdIP/ZC702_base.xdc
   } elseif {$isZed} {
     #add_files -fileset constrs_1 -norecurse $trainingPath/training/$tcName/support/Zed_base.xdc
     add_files -fileset constrs_1 -norecurse $trainingPath/CustEdIP/ZED_base.xdc
   }
   
   # if it's a microblaze, then we have to connect the sys_diff_clk
   set isUBlaze [strsame $processor MicroBlaze]
   
   if {$isUBlaze} {
     if {$isZC702} {
       set clkConstraintFile $trainingPath/$tcName/support/ZC702_sys_clk.xdc
       if {[fileExists $clkConstraintFile]} {
         add_files -fileset constrs_1 -norecurse $clkConstraintFile
       }
     } elseif {$isZed == 0} {
       set clkConstraintFile $trainingPath/$tcName/support/zed_sys_clk.xdc
       if {[fileExists $clkConstraintFile]} {
         add_files -fileset constrs_1 -norecurse $clkConstraintFile
       }
     }
   } else {
      # it is not a MicroBlaze processor, no need to do anything.
     # puts "***** Unsupported platform! $platform in constraintFilesAdd"
   }
      
   markLastStep constraintFilesDefaultAdd;      
}
lappend loadedProcs {constraintFilesDefaultAdd "adds the default (_base.xdc) to the project"};
#/**
# * proc:  constraintFilesAdd
# * descr: 
# * @meta <list of searchable terms> 
# * @param constraintFileList  if the elements in the list don't have the hierarchy path, then the $tcName/support directory is assumed
# */
proc constraintFilesAdd { constraintFileList } {
    variable tcName
    variable trainingPath
    variable verbose
    if {$verbose} { puts "completer_helper.constraintFilesAdd - $constraintFileList"}
   
    # if a list is provided, use it and ignore the embedded defaults
    if {[llength $constraintFileList] > 0 } {      
       foreach fileName $constraintFileList {   
         # is this a full path or just the name - if it's just the name assume that it's coming from the support directory
         # is there a full path provided? - Does not make corrections for langauage - assumes user knows what he/she's doing
         set hierarchyList [hierarchyToList $fileName]
         if {[llength $hierarchyList] > 1} {        # a hierarchy has been presented so use it instead of the support directory 
            set fullFileName $fileName
         } else {  
            # just the file name - assume it's coming from the source directory
            set fullFileName ""
            append fullFileName $trainingPath/$tcName/support/ $fileName
         }
       regsub -all {\\} $fullFileName / fullFileName
         import_files -fileset constrs_1 -norecurse $fullFileName
       }   
    } else {
       puts "Expected a {list} of constraint files!"
    }
   
   markLastStep constraintFilesAdd;
}
lappend loadedProcs {constraintFilesAdd "adds a list of files as constraints"};
#/**
# * proc:  ipFilesAdd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc ipFilesAdd {} {
 variable tcName
 variable platform
 variable demoOrLab
 variable language
 variable verbose
 variable trainingPath
 
 if {$verbose == 1} { puts "adding IP files"}
 #Adds the ip files based on board choosen
 if {$platform == "KC705"} {
  import_files -norecurse $trainingPath/$tcName/support/clk_core.xci
 } elseif {$platform == "KCU105"} {
  import_files -norecurse $trainingPath/$tcName/support/clk_core.xci  
  import_files -norecurse $trainingPath/$tcName/support/char_fifo.xci
 }
markLastStep ipFilesAdded
}
lappend loadedProcs {ipFilesAdds "add IP files as IP"};
#
#/**   ***OBSOLETE???***
# * proc:  copySourcestoTraining
# * descr: Copies SVN sources to training directory
# * @meta <list of searchable terms> 
# */
proc copySourcestoTraining {} {
variable tcName
variable trainingPath

file copy /media/sf_trunk/FPGA/TopicClusters/$tcName $trainingPath
}

#
# ***** Processor/Processing System
#/**
# * proc:  applyZynqProcessorPreset
# * descr: 
# * @meta <list of searchable terms> 
# */
proc applyZynqProcessorPreset {} {
   variable processor
   variable platform
   variable verbose
   
   if {$verbose} { puts "in completer_helper.applyZynqProcessorPreset"; }
   
   # what is it? makes comparisons below easier
   set isZed    [strcmp $platform Zed]
   set isZC702  [strcmp $platform ZC702]
   set isZCU102 [strcmp $platform ZCU102]
   set isZCU104 [strcmp $platform ZCU104]
   set isUBlaze [strcmp $processor MicroBlaze]
   
   if {$isUBlaze == 0} {
      # If using ublaze, no need to do anything with presets.
   } else {
      if {$isZCU104 == 0} {
      # todo: probably wrong - validate
         set_property -dict [list CONFIG.preset {ZCU104}] [get_bd_cells processing_system7_0]
      } elseif {$isZC702 == 0} {
         set_property -dict [list CONFIG.preset {ZC702}] [get_bd_cells processing_system7_0]
      } elseif {$isZed ==0} {
         set_property -dict [list CONFIG.preset {ZedBoard}] [get_bd_cells processing_system7_0]
      } else {
         puts "****** Zynq MP Needs to be implemented"
      }
   }
   
   markLastStep applyZynqProcessorPreset;
}
lappend loadedProcs {applyZynqProcessorPreset "apply the Zynq-7000 processor preset - warning this will reset all settings for the PS"};
#
# ********** Processor/Processing System
#/**
# * proc:  processorAdd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc processorAdd {} {
   variable platform
   variable trainingPath
   variable processor
   variable tcName
   variable suppressPreClean
   variable verbose
   if {$verbose} { puts "in completer_helper.processorAdd - adding processor: $processor" }

   # clear the processors if they exist - suppressPreClean allows for microblaze plus other processor
   if {[catch {info exist suppressPreClean} emsg]} {
      if {!$suppressPreClean} {
         set processors [get_bd_cells -quiet {micro* proc* zynq_ultra* noInterrupts PS_access}]
         delete_bd_objs -quiet $processors
      } else {
         # we need to suppress the preClean so don't erase anything and fall through to the next part
      }
   } else {
      # suppressPreClean was not defined therefore treat it as false
#      set processors [get_bd_cells -quiet {micro* proc* zynq_ultra* noInterrupts PS_access}]
#      delete_bd_objs -quiet $processors     
   }

   # PS (if part supports it)
   set isZed    [strsame $platform Zed]
   set isZC702  [strsame $platform ZC702] 
   set isZCU102 [strsame $platform ZCU102]
   set isZCU104 [strsame $platform ZCU104]
   set isZCU111 [strsame $platform ZCU111]
   set isUBlaze [strsame $processor MicroBlaze]
   
   if {$isUBlaze} {
      if {$verbose} { puts "adding the MicroBlaze"}
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:microblaze:10.0] microblaze_0
     
     # when the uB is running in a Zynq-7000 or MPSoC/RFSoC device, we have to use the special IP to access the rx, tx, and hp0 ports of the PS
     # [2018.1] mcheck if ip_repo_paths contains CustEdIP - if not, add it to the repository
     # todo: make sure this ADDs it to the repository not replacing anything that is already there
    if {$isZCU104} {
       # transparent PS not needed
      puts "MPSoC devices offer access to the RX/TX without needing the transparent PS";
    } else {
       # get the transparent PS as it is needed for rx/tx and clock
       # set availableIPs [get_ipdefs]
       # set targetIPname XparentPS:1.0
       # if {![containedIn $targetIPname $availableIPs]} {
       #    set_property  ip_repo_paths  $trainingPath/CustEdIP/XparentPS [current_project]
       #    update_ip_catalog    
       # }
        # todo: this is what it should be: create_bd_cell -type ip -vlnv [latestVersion xilinx.com:user:xparentPS:1.0] PS_access
        #create_bd_cell -type ip -vlnv [latestVersion xilinx.com:user:XarentPS:1.0] PS_access
        #create_bd_cell -type ip -vlnv xilinx.com:user:$targetIPname PS_access
       # set_property -dict [list CONFIG.CLK_100MHz_EN {true} CONFIG.Rx_EN {true} CONFIG.Tx_EN {true} CONFIG.CLK_reset_EN {true} CONFIG.S_AXI_HP0_EN {true}] [get_bd_cells PS_access]  
        ##set_property range 512M [get_bd_addr_segs {microblaze_0/Data/SEG_PS_access_reg0}]   
# Use the clock off the PS     
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins microblaze_0/Clk];
connect_bd_net [get_bd_pins microblaze_0/Reset] [get_bd_pins rst_ps7_0_100M/mb_reset];

      }   
   } else {
      # if not specifically targeting the uB, the PS will be instantiated
      if {$isZed || $isZC702} {                 # add in the Zynq7000 PS
         if {$verbose} { puts "is a Zed or ZC702 - adding the PS" }
         create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:processing_system7:5.5] processing_system7_0
      } elseif {$isZCU102 || $isZCU104} {                          # add in the US+ PS
         if {$verbose} { puts "is a ZCU102/4 - adding the PS"}
         create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:zynq_ultra_ps_e:3.0] zynq_ultra_ps_e_0
      } elseif {$ZCU111} {
         if {$verbose} { puts "is an RFSoC device - adding the PS"}
         create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:zynq_ultra_ps_e:3.0] zynq_ultra_ps_e_0      
      }
   }
  
   regenerate_bd_layout
   save_bd_design
   
   markLastStep processorAdd
}
lappend loadedProcs {processorAdd "adds the specified processor to the block design"};
#
# ********** processorConfigure
#
# - ensures that processor is configured for the board and includes an M_AXI_GP0
#
#/**
# * proc:  processorConfigure
# * descr: 
# * @meta <list of searchable terms> 
# */
proc processorConfigure {} {
   variable platform
   variable processor
   variable ZynqAllOff
   variable MPSoCallOff
   variable activePeripheralList
   variable debug
   
   variable verbose   
   if {$verbose} { puts "in completer_helper.processorConfigure"; }
   
   variable suppressInterrupts
   if (![info exists suppressInterrupts]) { set suppressInterrupts 0 }
   
   # what is it? makes comparisons below easier
   set isZed     [strsame $platform Zed]
   set isZC702   [strsame $platform ZC702]
   set isZCU102  [strsame $platform ZCU102]
   set isZCU104  [strsame $platform ZCU104]
   set isZCU111  [strsame $platform ZCU111]   
   set isAPSoC   [expr $isZed || $isZC702]
   set isMPSoC   [expr $isZCU102 || $isZCU104 || $isZCU111]
   set isUBlaze  [strsame $processor MicroBlaze]
   set isA53     [strsame $processor A53]
   set isR5      [strsame $processor R5]
   
   # clear the PS's configuration
   if {$isAPSoC} {
      set targetDevice processing_system7_0
      set list $ZynqAllOff
   } elseif {$isMPSoC} {
      set targetDevice zynq_ultra_ps_e_0
      set list $MPSoCallOff
   } elseif {$isUBlaze} {
      # no action required
   } else {
      boxedMsg "undefined processor!"
      return;
   }

   # is there a microblaze in this design?     
   if {$isUBlaze} {
      # ignore the PS in this device as it is being managed by the PS_access IP
     
      if ($suppressInterrupts) { 
         if {$verbose} { puts "configuring uB without interrupts"; }
         apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {preset "Microcontroller" local_mem "32KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "0" clk "/PS_access/CLK_100MHz (100 MHz)" }  [get_bd_cells microblaze_0]
      } else { 
         if {$verbose} { puts "configuring uB with interrupts"; }
         apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {preset "Microcontroller" local_mem "32KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/PS_access/CLK_100MHz (100 MHz)" }  [get_bd_cells microblaze_0]
         puts "Grounding unused pin on Concat block to Intertupt controller"; 
         create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:xlconstant:1.1] UNUSEDintr_gnd
         set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells UNUSEDintr_gnd]
         connect_bd_net [get_bd_pins microblaze_0_xlconcat/In1] [get_bd_pins UNUSEDintr_gnd/dout];                          
      }
      connect_bd_net [get_bd_pins PS_access/CLK_reset_n] [get_bd_pins rst_PS_access_100M/ext_reset_in]      
           
     # connect the uB design to the HP0 for data access to DDR
     apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins PS_access/S_AXI_HP0]

   } else {
      # set the board specific preset
      if {$verbose} { puts "configuring PS - no MicroBlaze present" }
      if {$isZCU104} {
         puts "   configuring ZCU104's PS with preset ($targetDevice) - be sure to run processorConfigure afterwards";
         puts "      this is done to properly set us the connections and settings for the DDR and other stuff";
         apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]; 
      } elseif {$isZCU102} {
         puts "   configuring ZCU102's PS with preset ($targetDevice)";
         apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
       } elseif {$isZC702} {
         if {$verbose} { puts "applying preset for ZC702" }
         set_property -dict [list CONFIG.preset {ZC702}] [get_bd_cells processing_system7_0]
         apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]   
       } elseif {$isZed} {
         if {$verbose} { puts "applying preset for ZedBoard" }
         set_property -dict [list CONFIG.preset {ZedBoard}] [get_bd_cells processing_system7_0]
         apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]        
       } else {
         if {$verbose} { puts "no presets for MPSoC or RFSoC" }
       }
     
      # todo: can we skip this if we're targeting the MicroBlaze?
      # clear the PS's configuration
      if {$verbose} { puts "completer_helper.processorConfigure - clearing all options in PS"; }
      set nConfigItems [llength $list]
      for {set index 0} {$index < $nConfigItems} {incr index 2} {
         set itemNameIndex  $index
         set itemValueIndex [expr $index + 1 ]
         set itemName       [lindex $list $itemNameIndex ]
         set itemValue      [lindex $list $itemValueIndex]
         #if {$verbose} { puts "setting $itemName to $itemValue"; }
         set_property $itemName $itemValue [get_bd_cells $targetDevice]    
      }
            
      # add in user's specific configuration
      set nConfigItems [llength $activePeripheralList]     
      if {$verbose} {
         if {$nConfigItems == 0} {
            puts "activePeripheralList is empty!";
         }
      } 

      # iterate through the activePeripheralList and set the property
      for {set index 0} {$index < $nConfigItems} {incr index 2} {
         set itemNameIndex $index   
         set itemValueIndex [expr $index + 1 ]
         set itemName       [lindex $activePeripheralList $itemNameIndex ]  
         set itemValue      [lindex $activePeripheralList $itemValueIndex]
         if {$verbose} { puts "configuring PS's option: $itemName to value: $itemValue"; }
         set_property $itemName $itemValue [get_bd_cells $targetDevice]
      }
   }
       
   save_bd_design  
   
   markLastStep processorConfigure
}
lappend loadedProcs {processorConfigure "configures the PS based on the settings in the AP/MPSoC list"};
#
# *** processorDefaultConnect
#
#/**
# * proc:  processorDefaultConnect
# * descr: 
# * @meta <list of searchable terms> 
# */
proc processorDefaultConnect {} {
   variable platform
   variable processor
   variable verbose
   variable ZynqAllOff
   variable MPSoCallOff
   variable activePeripheralsList
   
   if {$verbose} { puts "in completer_helper.processorDefaultConnect"; }
   
   # what is it? makes comparisons below easier
   set isZed    [strcmp $platform Zed]
   set isZC702  [strcmp $platform ZC702]
   set isZCU102 [strcmp $platform ZCU102]
   set isUBlaze [strcmp $processor MicroBlaze]  

   if { $isUBlaze == 0 } {
      # if the transparent PS peripheral is available, then get rid of the clock wizard and use the XparentPS instead
      set XparentPSpresent [get_bd_cells -quiet PS_access]  
      if {[llength $XparentPSpresent]} {
         # clock connection
         disconnect_bd_net /microblaze_0_Clk [get_bd_pins clk_wiz_1/clk_out1]
         connect_bd_net [get_bd_pins PS_access/CLK_100MHz] [get_bd_pins microblaze_0/Clk]
         # and the locked nReset signals
         delete_bd_objs [get_bd_nets clk_wiz_1_locked]
         connect_bd_net [get_bd_pins PS_access/CLK_reset_n] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
         # remove the IP and port
         delete_bd_objs [get_bd_intf_nets CLK_IN1_D_1] [get_bd_intf_ports CLK_IN1_D]
         delete_bd_objs [get_bd_nets noReset_dout] [get_bd_cells clk_wiz_1] [get_bd_cells noReset]
         # remove the rtl reset port and associated connection with the clk_wiz_1
         delete_bd_objs [get_bd_nets reset_rtl_1] [get_bd_ports reset_rtl]
         # connect the ext_reset_in to the XParentPS
         connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in] [get_bd_pins PS_access/CLK_reset_n]
      }
   }
  
   set PS7inUse [get_bd_cells -quiet processing_system7*]
   if {[llength $PS7inUse] > 0} {
      if { $isZed == 0 || $isZC702 == 0} {
         apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "0" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
      }
   }
  
   markLastStep processorDefaultConnect
}
lappend loadedProcs {processorDefaultConnect "Makes default connections for the PS - includes clock wizards, reset blocks, etc."};
#
# *** VIOadd
#    - requires that a clock source exist before making this call - in the case of the uB, the clock should be from the PS_access IP
#
#/**
# * proc:  VIOadd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc VIOadd {} {
   variable platform
   variable processor
   variable tcName
   variable verbose
   if {$verbose} { puts "completer_helper.VIOadd"; }
   
   # remove the VIO if it already exists
   set VIOs [get_bd_cells -quiet {vio_fmcce LCD_*} ]
   delete_bd_objs -quiet $VIOs
   
   # determine the platform   
   set isZed    [strsame $platform Zed]
   set isZC702  [strsame $platform ZC702]
   set isZCU102 [strsame $platform ZCU102]
   set isZCU104 [strsame $platform ZCU104]
   set isZCU111 [strsame $platform ZCU111]

   # what kind of PS?
   if {$isZCU102 || $isZCU104 || $isZCU111} {
      # is an MPSoC or RFSoC
      set isPS     [strsame $processor psu_cortexa53_0]    
   } else {
      # is a Z7000
      set isPS     [strsame $processor ps7_cortexa9_0]     
   }

   set isUBlaze [strsame $processor microblaze]
   
   # instantiate and configure the VIO
   set vioName vio_fmcce
   set VIO_nInputs 3
   set VIO_nOutputs 3
   create_bd_cell -type ip -vlnv [latestVersion  xilinx.com:ip:vio:3.0] $vioName
   set_property -dict [list CONFIG.C_NUM_PROBE_IN $VIO_nInputs  CONFIG.C_NUM_PROBE_OUT $VIO_nOutputs] [get_bd_cells $vioName]
   set_property -dict [list CONFIG.C_PROBE_IN0_WIDTH {7}] [get_bd_cells $vioName];     # LCD
   set_property -dict [list CONFIG.C_PROBE_IN1_WIDTH {8}] [get_bd_cells $vioName];     # LEDs_linear
   set_property -dict [list CONFIG.C_PROBE_IN2_WIDTH {5}] [get_bd_cells $vioName];     # LEDs_rosetta
   if {$isZCU104} {
      # only has 4 LEDs in the rosetta
     set_property -dict [list CONFIG.C_PROBE_IN2_WIDTH {4}] [get_bd_cells vio_fmcce];
   }
   set_property -dict [list CONFIG.C_PROBE_OUT0_WIDTH {1}] [get_bd_cells $vioName];    # LCD data catcher next datum request
   set_property -dict [list CONFIG.C_PROBE_OUT1_WIDTH {5}] [get_bd_cells $vioName];    # Buttons_Rosetta
   if {$isZCU104} {
      set_property -dict [list CONFIG.C_PROBE_OUT1_WIDTH {4}] [get_bd_cells $vioName];    # Buttons_Rosetta
   }
   set_property -dict [list CONFIG.C_PROBE_OUT2_WIDTH {8}] [get_bd_cells $vioName];    # Switches_Linear
   if {$isZCU104} {
      # only has 4 DIP switches
     set_property -dict [list CONFIG.C_PROBE_OUT2_WIDTH {4}] [get_bd_cells $vioName];
   }
   
   # connect the clock
   if {$isUBlaze} { 
     #connect_bd_net [get_bd_pins vio_fmcce/clk] [get_bd_pins clk_wiz_1/clk_out1]; 
     apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/PS_access/CLK_100MHz (100 MHz)" }  [get_bd_pins vio_fmcce/clk]
   } 

   if {$isPS} { 
      if {$isZCU104} {
         connect_bd_net [get_bd_pins vio_fmcce/clk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
     } else {
        # Z7000 board
         connect_bd_net [get_bd_pins vio_fmcce/clk] [get_bd_pins processing_system7_0/FCLK_CLK0];    
      }
   }    
   
   # tie off the LCDs as they are no longer being used, let the LED outputs hang open
   create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 LCD_const_data
   set_property -dict [list CONFIG.CONST_WIDTH {7} CONFIG.CONST_VAL {0}] [get_bd_cells LCD_const_data]
   connect_bd_net [get_bd_pins LCD_const_data/dout] [get_bd_pins vio_fmcce/probe_in0]
   
   # the remainingVIO connections will be made by their respective GPIO elements
}
lappend loadedProcs {vioAdd "adds the VIO for the virtualized I/O settings"};
#/**
# * proc:  LEDsLinearAdd
# * descr: adds GPIO supporting 8 bit linear LEDs
# * @meta <list of searchable terms> 
# */
proc LEDsLinearAdd { } {
   variable platform;
   variable processor;
   variable tcName;
   variable verbose;
   if {$verbose} { puts "completer_helper.LEDsLinearAdd (Adding Linear LED to PS)";  }
   
   set ipName GPIO_LEDs_linear
   set ipCore "xilinx.com:ip:axi_gpio"
   set ipPort LEDs_linear
   
   # remove the VIO if it already exists
   set objects [get_bd_cells -quiet {GPIO_LEDs_linear} ]
   delete_bd_objs -quiet $objects
   set objects [get_bd_ports -quiet $ipPort ]
   delete_bd_objs -quiet $objects
   
   # add GPIO Linear LEDs, configure, and connect
   create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_gpio:2.0] $ipName
   set_property -dict [list CONFIG.C_GPIO_WIDTH {8} CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells $ipName]
   
   # connect to the appropriate processor
   set isUBlaze     [strsame $processor MicroBlaze];
   set isZed        [strsame $platform ZED];
   set isZC702      [strsame $platform ZC702];
   set isZCU102     [strsame $platform ZCU102];
   set isZCU104     [strsame $platform ZCU104];
   set isZCU111     [strsame $platform ZCU111];
   
   # make AXI connection
   apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/GPIO_LEDs_linear/S_AXI} ddr_seg {Auto} master_apm {0}}  [get_bd_intf_pins GPIO_LEDs_linear/S_AXI]

 #  if {$isUBlaze} {
 #     apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins GPIO_LEDs_linear/S_AXI]
 #  } elseif {[strsame $processor A53] || [strContains $processor a53]} {
 #     puts "attaching to the A53"
 #     apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_LPD} Slave {/GPIO_LEDs_linear/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins GPIO_LEDs_linear/S_AXI]
 #     # this was the old one for the ZCU102
 #     #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_LPD} Slave {/GPIO_LEDs_linear/S_AXI} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins GPIO_LEDs_linear/S_AXI]
 #  } elseif {[strContains $processor A9]} {                      
 #     puts "Zynq7000"
 #     apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins $ipName/S_AXI]
 #  } else {
 #     puts "unidentified processor: $processor"
 #  }

   #  Connect signals to board wherever possible - ZC702 and Zed have all 8 LEDs available
   if {$isZCU102} {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/GPIO_LEDs_linear/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins GPIO_LEDs_linear/S_AXI]
      apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {led_8bits ( LED ) } Manual_Source {Auto}}  [get_bd_intf_pins GPIO_LEDs_linear/GPIO]   
   } elseif {$isZCU104} {
      # ZCU104 only has rosetta LEDs - no linear LEDs are available
     # we will still instantiate the GPIO and monitor the outputs via the VIO
     # connect the GPIO's AXI to the rest of the system
     apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/GPIO_LEDs_linear/S_AXI} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins GPIO_LEDs_linear/S_AXI]
   } elseif {$isZC702} {
      create_bd_port -dir O -from 7 -to 0 $ipPort
      connect_bd_net [get_bd_pins /$ipName/gpio_io_o] [get_bd_ports $ipPort]
   } elseif {$isZed} {
      create_bd_port -dir O -from 7 -to 0 $ipPort
      connect_bd_net [get_bd_pins /$ipName/gpio_io_o] [get_bd_ports $ipPort]
   }
   
   # connect to the VIO which should already have been instantiated
   if {$isZCU104} {
      # since the ZCU104 doesn't have physical linear LEDs, we'll tie directly in to the FMCCE VIO
     connect_bd_net [get_bd_pins GPIO_LEDs_linear/gpio_io_o] [get_bd_pins vio_fmcce/probe_in1]
   } else {
      # support for other boards goes here
   }

   markLastStep LEDsLinearAdd;
}
lappend loadedProcs {LEDsLinearAdd "adds the GPIO for controlling the linear LEDs"};
#
# *** Buttons Rosetta
#
#/**
# * proc:  buttonsRosettaAdd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc buttonsRosettaAdd { } {
   variable platform
   variable processor
   variable tcName
   variable verbose
   if {$verbose} { puts "completer_helper.buttonsRosettaAdd"; }   
   
   set isZed       [strsame $platform ZED]
   set isZC702     [strsame $platform ZC702]
   set isUBlaze    [strsame $processor microblaze]   
   set isZCU104    [strsame $platform ZCU104]
   set isZCU111    [strsame $platform ZCU111]
   set ipName "GPIO_buttons_rosetta"
   set ipPort buttons_rosetta
   
   # remove the device if it already exists
   set objects [get_bd_cells -quiet {$ipName GPIO_buttons_rosetta Buttons_ORed ground_3_bits adjust_Rosetta_button_width} ]
   delete_bd_objs -quiet $objects
   set objects [get_bd_ports -quiet $ipPort ]
   delete_bd_objs -quiet $objects
   
   # add GPIO Rosetta buttons and configure
   create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_gpio:2.0] $ipName
   if {$isZCU104} {
      # 4 button rosetta configuration
     set_property -dict [list CONFIG.C_GPIO_WIDTH {4} CONFIG.C_ALL_INPUTS {1}] [get_bd_cells $ipName]
   } else {
      # full 5 button rosetta configuration
      set_property -dict [list CONFIG.C_GPIO_WIDTH {5} CONFIG.C_ALL_INPUTS {1}] [get_bd_cells $ipName]
   }
   
   # connect to the appropriate processor
   set isUBlaze [strsame $processor Microblaze];
   if {$isUBlaze} {
      if {$verbose} { puts "running automation for $ipName - slave AXI connection in MicroBlaze context" }
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins $ipName/S_AXI]  
      #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins GPIO_buttons_rosetta/S_AXI]
   } elseif {$isZCU104} {
      if {$verbose} { puts "running automation for $ipName - slave AXI connection in PS context" }
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/GPIO_buttons_rosetta/S_AXI} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins GPIO_buttons_rosetta/S_AXI]
   } else {
      if {$verbose} { puts "running automation for $ipName - slave AXI connection in PS context" }
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/GPIO_buttons_rosetta/S_AXI} ddr_seg {Auto} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins GPIO_buttons_rosetta/S_AXI]

      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins $ipName/S_AXI]
   }

   # Connect signals to board wherever possible - ZC702 only has north and south, Zed has all 5 buttons available
   if {$isZCU104} {
      # since input is available from the VIO and the board, an OR is required 
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:util_vector_logic:2.0] Buttons_ORed
      set_property -dict [list CONFIG.C_OPERATION {or} CONFIG.LOGO_FILE {data/sym_orgate.png} CONFIG.C_SIZE {4}] [get_bd_cells Buttons_ORed]

      # create a board port and connect to the concatonation block and then on to the OR block
      create_bd_port -dir I -from 3 -to 0 $ipPort
      connect_bd_net [get_bd_ports buttons_rosetta] [get_bd_pins Buttons_ORed/Op1]
      connect_bd_net [get_bd_pins vio_fmcce/probe_out1] [get_bd_pins Buttons_ORed/Op2]
     
      # connect the output of the OR to the GPIO
      connect_bd_net [get_bd_pins $ipName/gpio_io_i] [get_bd_pins Buttons_ORed/Res];
    
   } elseif {$isZC702} {
      # since input is available from the VIO and the board, an OR is required 
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:util_vector_logic:2.0] Buttons_ORed
      set_property -dict [list CONFIG.C_OPERATION {or} CONFIG.LOGO_FILE {data/sym_orgate.png} CONFIG.C_SIZE {5}] [get_bd_cells Buttons_ORed]

      # since this board lacks a number of buttons,  the existing buttons have to be buffered to properly match the input of the OR gate
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:xlconcat:2.1] adjust_Rosetta_button_width
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:xlconstant:1.1] ground_3_bits
      set_property -dict [list CONFIG.CONST_WIDTH {3} CONFIG.CONST_VAL {0}] [get_bd_cells ground_3_bits]

      # create a board port and connect to the concatonation block and then on to the OR block
      create_bd_port -dir I -from 1 -to 0 $ipPort
      connect_bd_net [get_bd_pins /adjust_Rosetta_button_width/In0] [get_bd_ports $ipPort]
      connect_bd_net [get_bd_pins ground_3_bits/dout] [get_bd_pins adjust_Rosetta_button_width/In1]
      connect_bd_net [get_bd_pins adjust_Rosetta_button_width/dout] [get_bd_pins Buttons_ORed/Op1]

      # connect the VIO to the other input to the OR logic cell
      connect_bd_net [get_bd_pins vio_fmcce/probe_out1] [get_bd_pins Buttons_ORed/Op2]
     
      # connect the output of the OR to the GPIO
      connect_bd_net [get_bd_pins $ipName/gpio_io_i] [get_bd_pins Buttons_ORed/Res]

   } elseif {$isZed} {
      # since input is available from the VIO and the board, an OR is required 
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:util_vector_logic:2.0] Buttons_ORed
      set_property -dict [list CONFIG.C_OPERATION {or} CONFIG.LOGO_FILE {data/sym_orgate.png} CONFIG.C_SIZE {5}] [get_bd_cells Buttons_ORed]
                 
      # create a board port and connect to the concatonation block and then on to the OR block
      create_bd_port -dir I -from 4 -to 0 $ipPort
      connect_bd_net [get_bd_pins $ipPort] [get_bd_pins Buttons_ORed/Op1]        
     
      # connect the VIO to the OR logic cell
      connect_bd_net [get_bd_pins vio_fmcce/probe_out1] [get_bd_pins Buttons_ORed/Op2]
     
      # connect the output of the OR to the GPIO
      connect_bd_net [get_bd_pins $ipName/gpio_io_i] [get_bd_pins Buttons_ORed/Res]

   } else {
      # future - if a board completely lacks these buttons then it can be routed directly to the VIO and GPIO
   }  
}
lappend loadedProcs {buttonsRosettaAdd "adds the GPIO as an input device for the rosettas buttons"};
#
# *** LEDs Rosetta
#
#/**
# * proc:  LEDsRosettaAdd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc LEDsRosettaAdd { } {
   variable platform
   variable processor
   variable tcName
   variable verbose
   if {$verbose} { puts "completer_helper.LEDsRosettaAdd"; }
   
   set isZed        [strsame $platform "ZED"]
   set isZC702      [strsame $platform "ZC702"]
   set isZCU104     [strsame $platform "ZCU104"]
   set isZCU111     [strsame $platform ZCU111]
   set ipName "GPIO_LEDs_rosetta"
   set ipPort LEDs_rosetta
   
   # remove the device if it already exists
   set objects [get_bd_cells -quiet $ipName ]
   delete_bd_objs -quiet $objects
   set objects [get_bd_ports -quiet $ipPort ]
   delete_bd_objs -quiet $objects
   
   # add GPIO Rosetta LEDs and configure
   create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_gpio:2.0] $ipName
   if {$isZCU104} {
      # only has 4 elements in the rosetta
      set_property -dict [list CONFIG.C_GPIO_WIDTH {4} CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells $ipName]
   } else {
      # boards with full 5 element rosettas
      set_property -dict [list CONFIG.C_GPIO_WIDTH {5} CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells $ipName]
   }
   
   # connect to the appropraite processor
   set isUBlaze [strsame $processor MicroBlaze]
   if {$isUBlaze} {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins $ipName/S_AXI]
   } elseif {$isZCU104} {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (96 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/GPIO_LEDs_rosetta/S_AXI} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins GPIO_LEDs_rosetta/S_AXI]
   } else {
      # Z7000
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/GPIO_LEDs_rosetta/S_AXI} ddr_seg {Auto} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins GPIO_LEDs_rosetta/S_AXI]

    #old  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins $ipName/S_AXI] 
   }
   
   #
   #  Connect signals to board wherever possible - both the ZC702 and Zed boards completely lack the rosetta LEDs therefore there is no port and connects directly to the VIO
   if {$isZCU104} {
      make_bd_pins_external  [get_bd_pins GPIO_LEDs_rosetta/gpio_io_o];   # connect to the output pins
      set_property name LEDs_rosetta [get_bd_ports gpio_io_o_0];        # change the name to be compliant with the IO naming convetion for this design
      connect_bd_net [get_bd_pins vio_fmcce/probe_in2] [get_bd_pins GPIO_LEDs_rosetta/gpio_io_o];   # tie to the VIO
   } elseif {$isZC702} {
      connect_bd_net [get_bd_pins vio_fmcce/probe_in2] [get_bd_pins $ipName/gpio_io_o]
   } elseif {$isZed} {
      connect_bd_net [get_bd_pins vio_fmcce/probe_in2] [get_bd_pins $ipName/gpio_io_o]
   }   
}
lappend loadedProcs {LEDsRosettaAdd "adds the GPIO as an output device for the rosettas LEDs"};
#
# *** Switches Linear
#
#/**
# * proc:  switchesLinearAdd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc switchesLinearAdd { } {
   variable platform;
   variable processor;
   variable tcName;
   variable verbose;
   if {$verbose} { puts "completer_helper.switchesLinearAdd"; }   
   
   set isZed     [strsame $platform ZED]
   set isZC702   [strsame $platform ZC702]
   set isZCU102  [strsame $platform ZCU102]
   set isZCU104  [strsame $platform ZCU104]
   set isZCU111  [strsame $platform ZCU111]
   set isAPSoC   [expr $isZed || $isZC702]
   set isMPSoC   [expr $isZCU102 || $isZCU104 || $isZCU111];
   set ipName GPIO_switches_linear
   set ipPort switches_linear
   
   # remove the device if it already exists
   set objects [get_bd_cells -quiet {*switches*} ]
   delete_bd_objs -quiet $objects
   set objects [get_bd_ports -quiet $ipPort ]
   delete_bd_objs -quiet $objects
   
   # add GPIO Linear Switches and configure
   create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_gpio:2.0] $ipName
   if {$isZCU104} {
      # only has four user DIP switches
      set_property -dict [list CONFIG.C_GPIO_WIDTH {4} CONFIG.C_ALL_INPUTS {1}] [get_bd_cells $ipName]
   } else {
      set_property -dict [list CONFIG.C_GPIO_WIDTH {8} CONFIG.C_ALL_INPUTS {1}] [get_bd_cells $ipName]
   }
   
   # connect to the appropraite processor using the connection automation
   set isUBlaze [strsame $processor MicroBlaze]
   if {$isUBlaze} {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins $ipName/S_AXI]  
   } elseif {$isAPSoC} {
      #apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {gpio_sw ( DIP switches ) } Manual_Source {Auto}}  [get_bd_intf_pins GPIO_switches_linear/GPIO]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/GPIO_switches_linear/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins GPIO_switches_linear/S_AXI]
     #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/GPIO_switches_linear/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins GPIO_switches_linear/S_AXI]
   } elseif {$isMPSoC} {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/GPIO_switches_linear/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins GPIO_switches_linear/S_AXI]
   } else {
      puts "completer_helper: switchesLinearAdd: Undefined platform: $platform";
   }
   
   #
   # Connect signals to board wherever possible - ZC702 lacks the linear switches; Zed boards has the full set of 8 switches
   puts "Now attempting to connect the GPIO to the linear switches...";
   if {$isZCU104} {
      # 4 dip switches are avilable
      create_bd_port -dir I -from 3 -to 0 $ipPort
     
      # create an or gate so that the input to the GPIO can be from the VIO or DIP switches
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:util_vector_logic:2.0] Switches_ORed
      set_property -dict [list CONFIG.C_OPERATION {or} CONFIG.LOGO_FILE {data/sym_orgate.png}] [get_bd_cells Switches_ORed]
      set_property -dict [list CONFIG.C_SIZE {4}] [get_bd_cells Switches_ORed]
      
      connect_bd_net [get_bd_ports switches_linear] [get_bd_pins Switches_ORed/Op1];                # connect from the input port to the OR gate
      connect_bd_net [get_bd_pins Switches_ORed/Op2] [get_bd_pins vio_fmcce/probe_out2];            # connect to the VIO  
      connect_bd_net [get_bd_pins Switches_ORed/Res] [get_bd_pins $ipName/gpio_io_i];               # connect from the OR gate to the GPIO
     
   } elseif {$isZC702 == 0} {
      # no board connection
      puts "ZC702 does not have any linear switches, therefore, no ports will be created and the GPIO will be connected directly to the VIO";
      connect_bd_net [get_bd_pins vio_fmcce/probe_out2] [get_bd_pins $ipName/gpio_io_i];
   } elseif {$isZed == 0} {
      puts "Zed board has full complement of switches and will be combined via an OR with the VIO's inputs"
      create_bd_port -dir I -from 7 -to 0 $ipPort
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:util_vector_logic:2.0] Switches_ORed
      set_property -dict [list CONFIG.C_OPERATION {or} CONFIG.LOGO_FILE {data/sym_orgate.png}] [get_bd_cells Switches_ORed]
     
     # connect the OR gate to the port and to the VIO (which already have been instantiated)
     connect_bd_net [get_bd_ports switches_linear] [get_bd_pins Switches_ORed/Op1]
     connect_bd_net [get_bd_pins vio_fmcce/probe_out2] [get_bd_pins Switches_ORed/Op2]
     
     # connect the OR to the input of the GPIO      
      connect_bd_net [get_bd_pins Switches_ORed/Res] [get_bd_pins $ipName/gpio_io_i]
   }   
}
lappend loadedProcs {switchesLinearAdd "adds the GPIO as an input device for the linear switches"};
#
# *** UARTaddConditional
#   adds the UART only if the processor is a MicroBlaze
#/**
# * proc:  UARTaddConditional
# * descr: 
# * @meta <list of searchable terms> 
# */
proc UARTaddConditional {} {
   variable verbose
   if {$verbose} { puts "completer_helper.UARTaddConditional"; }
   variable processor
   if {[strsame $processor MicroBlaze]} {
      UARTadd
   } else {
      puts "Not adding UART as there are UARTs in the PS";
   }
}
lappend loadedProcs {UARTaddConditional "adds a PL UART to the block design"};
#
# *** UART
#/**
# * proc:  UARTadd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc UARTadd {} {
   variable platform
   variable processor
   variable tcName
   variable verbose
   variable suppressUARTinterrupt;     # there might be interrupts in the system, but the UART should connect to one
   variable suppressInterrupts;        # no interrupts in the system therefore the UART shouldn't generate one
   if {![info exists suppressUARTinterrupt]} { set suppressUARTinterrupt 0; }
   if {![info exists suppressInterrupts]}    { set suppressInterrupts 0; }  
   variable UARTdebug;                 # generates an ILA for monitoring the Rx/Tx lines of the UART
   if {![info exists UARTdebug]}    { set UARTdebug 0; }  
   
   set ipName UART
   
   if {$verbose} { puts "completer_helper.UARTadd"; }
   
   # remove the device if it already exists
   set objects [get_bd_cells -quiet *UART*]
   delete_bd_objs -quiet $objects
   delete_bd_objs [get_bd_nets -quiet {*UART* *Rx*}]
   
   if {[strsame $processor MicroBlaze]} {
      # add the UART itself
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_uartlite:2.0] $ipName
      set_property -dict [list CONFIG.C_BAUDRATE {115200}] [get_bd_cells $ipName]
      if {$suppressUARTinterrupt || $suppressInterrupts} { 
         puts "Microblaze processor found - adding UART without interrupt"; 
         # UART interrupt pin left hanging, input to interrupt controller is tied to ground - but only if there are system interrupts
         if {!$suppressInterrupts} {   
           # LR moved the constant creation to processorConfig
           # create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:xlconstant:1.1] UARTintr_gnd
           # set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells UARTintr_gnd]
            connect_bd_net [get_bd_pins microblaze_0_xlconcat/In0] [get_bd_pins UARTintr_gnd/dout];            
         }
      } else {
         puts "Microblaze processor found - adding UART with interrupt";          
         connect_bd_net [get_bd_pins microblaze_0_xlconcat/In0] [get_bd_pins UART/interrupt];   # Added by LR 2/24/2017  
      }
      
      # if in debug mode, add an ILA to the Rx/Tx
      if {$UARTdebug} {
         if {$verbose} { puts "completer_helper.UARTadd - adding debug ILA for the UART"; }
         
         # add and configure the System ILA for the UART
         create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:system_ila:1.1] UART_ILA
         set_property -dict [list CONFIG.C_BRAM_CNT {7.5} CONFIG.C_DATA_DEPTH {131072} CONFIG.C_NUM_OF_PROBES {2} CONFIG.C_ADV_TRIGGER {true} CONFIG.C_MON_TYPE {NATIVE}] [get_bd_cells UART_ILA]
         
         # remove the interface connection and replace with individual wires
         connect_bd_net [get_bd_pins PS_access/Rx] [get_bd_pins UART/rx]
         connect_bd_net [get_bd_pins UART_ILA/probe0] [get_bd_pins PS_access/Rx]
         connect_bd_net [get_bd_pins PS_access/Tx] [get_bd_pins UART/tx]
         connect_bd_net [get_bd_pins UART_ILA/probe1] [get_bd_pins UART/tx]
         
         # connect the clock
         apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/PS_access/CLK_100MHz (100 MHz)" }  [get_bd_pins UART_ILA/clk]
      } else {
         connect_bd_intf_net [get_bd_intf_pins PS_access/UART_pins] [get_bd_intf_pins UART/UART]
      }
      
      # finally connect the UART's clock
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins UART/S_AXI]
   }
}
lappend loadedProcs {UARTadd "adds the UART dependent on platform"};
#
# /**
#  * proc: BRAMadd
#  * descr: adds and connects BRAMadd
#  * note:  support only for MPSoC at this time... 
#  * @meta: BRAM 
#  */
proc BRAMadd {} {
   variable verbose;
   if {$verbose} { puts "completer_helper.BRAMadd"; } 
   
   # remove any traces of existing BRAMs so we can make a clean start
   set objects [get_bd_cells -quiet *BRAM*]
   delete_bd_objs -quiet $objects

   # add the BRAM controller and configure it as a single port first...
   create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_bram_ctrl:4.1] BRAMctrl
   set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells BRAMctrl]
   
   # connect the BRAM to the controller
   apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins BRAMctrl/BRAM_PORTA]
   
   # connect the BRAM controller to the AXI interconnect
   apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (100 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/BRAMctrl/S_AXI} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins BRAMctrl/S_AXI]

   
   markLastStep BRAMadd
}
lappend loadedProcs {BRAMadd "adds the BRAM controller and BRAMs to the block design"};
#
# *** DDR Memory Controller (MIG) - not tested!
#
#/**
# * proc:  MIGadd
# * descr: 
# * @meta <list of searchable terms> 
# */
proc MIGadd { } {
   variable verbose;
   if {$verbose} { puts "completer_helper.MIGadd"; } 
   variable blockDesignName;
     
   # add MIG only if there is a MicroBlaze processor
   if {[strsame $processor MicroBlaze]} {
      # remove default clocking wizard
      # need to remove clock port as well because board automation for MIG automatically adds another one
      # maybe in the future this will get fixed
      delete_bd_objs [get_bd_intf_nets sys_diff_clock_1] [get_bd_nets clk_wiz_1_locked] [get_bd_cells clk_wiz_1]
      delete_bd_objs [get_bd_nets reset_1]
      delete_bd_objs [get_bd_intf_ports sys_diff_clock] 
      
      # Add MIG using board interface
      create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:mig_7series:4.0] mig_7series_0
      apply_board_connection -board_interface "ddr3_sdram" -ip_intf "mig_7series_0/mig_ddr_interface" -diagram $blockDesignName
      
      # Connect reset
      connect_bd_net [get_bd_ports reset] [get_bd_pins mig_7series_0/sys_rst]
      connect_bd_net [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in] 
      
      # Connect clock signals
      connect_bd_net -net [get_bd_nets microblaze_0_Clk] [get_bd_pins mig_7series_0/ui_clk]
      connect_bd_net [get_bd_pins mig_7series_0/mmcm_locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]   
      connect_bd_net -net [get_bd_nets rst_clk_wiz_1_100M_peripheral_aresetn] [get_bd_pins mig_7series_0/aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
      
      # Re-customize uB to support DDR connection
      set_property -dict [list CONFIG.C_USE_ICACHE {1} CONFIG.C_USE_DCACHE {1}] [get_bd_cells microblaze_0]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Cached)" Clk "Auto" }  [get_bd_intf_pins mig_7series_0/S_AXI]      
   } 
   markLastStep MIGadd;
}
lappend loadedProcs {MIGadd "adds the PL MIG to the block design"};
#
# *** regenerate board layout
#
#/**
# * proc:  reGenLayout
# * descr: 
# * @meta <list of searchable terms> 
# */
proc reGenLayout {} {
  variable verbose      
  if {$verbose} { puts "completer_helper.reGenLayout" }
  regenerate_bd_layout
  save_bd_design
  
  markLastStep reGenLayout
}
lappend loadedProcs {reGenLayout "regenerate the layout"};
#
# ********** processorBlockAutomationRun
#
# - connects processor to I/O
#
#/**
# * proc:  processorBlockAutomationRun
# * descr: 
# * @meta <list of searchable terms> 
# */
proc processorBlockAutomationRun {} {
   variable processor;
   variable platform;
   variable verbose   ;
   if {$verbose} { puts "in processorBlockAutomationRun with processor set to: $processor"; }
   
   # what is it? makes comparisons below easier
   set isZed    [strsame $platform Zed];
   set isZC702  [strsame $platform ZC702];
   set isZCU102 [strsame $platform ZCU102];
   set isZCU104 [strsame $platform ZCU104];
   set isZCU111 [strsame $platform ZCU111];
   set isAPSoC  [expr $isZed || $isZC702];
   set isMPSoC  [expr $isZCU102 || $isZCU104 || $isZCU111];
   set isUBlaze [strsame $processor MicroBlaze];
   set isA72    [strsame $processor A72];
   set isA53    [strsame $processor A53];
   set isR5     [strsame $processor R5];
   
   if {$isUBlaze} {
      puts "no automation needs to be run on a microblaze only configuration"
      #**LR** (2018.3)
      puts "Set PS DDR RAM access to 512MB Starting at 0x20000000"
      set_property range 512M [get_bd_addr_segs {microblaze_0/Data/SEG_PS_access_reg0}]
      set_property offset 0x20000000 [get_bd_addr_segs {microblaze_0/Data/SEG_PS_access_reg0}]    
   } elseif {$isAPSoC} {
      puts "running automation on a Zynq-7000"
      apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "0" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
   } elseif {$isMPSoC} {
      # no action at this point because this appears to be taking place with the processorConfigure proc
   } else {
      puts "Undefined or unsupported processor for blockAutomation"
   }

   markLastStep processorBlockAutomationRun
}
lappend loadedProcs {processorBlockAutomationRun "run block automation on the PS"};
#/**
# * proc:  blockDesignWrap
# * descr: 
# * @meta <list of searchable terms> 
# */
proc blockDesignWrap {} {
   variable tcName
   variable trainingPath
   variable labName
   variable language
   variable blockDesignName
   variable demoOrLab
   variable verbose
   if {$verbose} { puts "completer_helper.blockDesignWrap" }
   
   save_bd_design
   close_bd_design [get_bd_designs $blockDesignName]

   # Reset block diagram output products and re-generate
   reset_target all [get_files  $trainingPath/$tcName/$demoOrLab/$labName.srcs/sources_1/bd/$blockDesignName/$blockDesignName.bd]
   generate_target all [get_files  $trainingPath/$tcName/$demoOrLab/$labName.srcs/sources_1/bd/$blockDesignName/$blockDesignName.bd]
   export_ip_user_files -of_objects [get_files $trainingPath/$tcName/$demoOrLab/$labName.srcs/sources_1/bd/$blockDesignName/$blockDesignName.bd] -no_script -sync -force -quiet
   create_ip_run [get_files -of_objects [get_fileset sources_1] $trainingPath/$tcName/$demoOrLab/$labName.srcs/sources_1/bd/$blockDesignName/$blockDesignName.bd]

   # is this really necessary? will we ever get this far without having defined the language?
   if {[strsame $language undefined]} {
      puts "Please select VHDL or Verilog with the \"use\" proc"
      return
   }
    
   set fullPath ""
   append fullPath $trainingPath/$tcName/$demoOrLab/$labName.srcs/sources_1/bd/$blockDesignName/$blockDesignName.bd
   make_wrapper -files [get_files $fullPath] -top
   
   set fullPath ""
   if {[string compare -nocase [getLanguage] verilog] == 0} {
      append fullPath $trainingPath/$tcName/$demoOrLab/$tcName.srcs/sources_1/bd/$blockDesignName/hdl/$blockDesignName\_wrapper.v    
   } else {
      append fullPath $trainingPath/$tcName/$demoOrLab/$labName.srcs/sources_1/bd/$blockDesignName/hdl/$blockDesignName\_wrapper.vhd  
   }
   add_files -norecurse $fullPath
   update_compile_order -fileset sources_1 
   update_compile_order -fileset sim_1
   
   # set the wrapper as the top of the design
   set_property top blkDsgn_wrapper [current_fileset]
   
   markLastStep wrapBlockDesign
}
lappend loadedProcs {wrapBlockDesign "creates an HDL wrapper for the block design"};
#/**
# * proc:  simulationRun
# * descr: 
# * @meta <list of searchable terms> 
# */
proc simulationRun {} {
   variable verbose
   if {$verbose} { puts "completer_helper.simulationRun"; }
   
   launch_simulation;
   
   markLastStep simulationRun;
}
lappend loadedProcs {simulationRun "runs the simulation"};
#/**
# * proc:  synthesisRun
# * descr: 
# * @meta <list of searchable terms> 
# */
proc synthesisRun {} {
   variable verbose   
   if {$verbose} { puts "completer_helper.synthesisRun"; }
   
   reset_run synth_1
   launch_runs synth_1 -jobs 4
   if {$verbose} { puts "\twaiting for synthesis to complete"; }
   wait_on_run synth_1
   open_run synth_1 -name synth_1
   
   markLastStep synthesisRun
}
lappend loadedProcs {synthesisRun "runs synthesis"};
#/**
# * proc:  implementationRun
# * descr: 
# * @meta <list of searchable terms> 
# */
proc implementationRun {} {
   variable verbose   
   if {$verbose} { puts "completer_helper.implementationRun"; }
   
   #reset_run synth_1
   launch_runs impl_1 -jobs 4
   if {$verbose} { puts "\twaiting for bitstream generation to complete"; }
   wait_on_run impl_1
   open_run impl_1
   
   markLastStep implementationRun
}
lappend loadedProcs {implenentationRun "run the design through implementation"};
#/**
# * proc:  bitstreamRun
# * descr: 
# * @meta <list of searchable terms> 
# */
proc bitstreamRun {} {
   variable verbose   
   if {$verbose} { puts "completer_helper.bitstreamRun"; }
   
   # test if there is already a bitstream
   set status [get_property status [current_run]]
   set implementationCompleteMessage "route_design Complete!"
   set bitstreamCompleteMessage      "write_bitstream Complete!"     
   set bitstreamErrorMessage         "write_bitstream ERROR"   

   if {[strsame $status $bitstreamErrorMessage]} { 
      errorMsg "Error writing bitstream"
   }   
    
   if {![strsame $status $bitstreamCompleteMessage]} {      
     launch_runs impl_1 -to_step write_bitstream -jobs 4
      if {$verbose} { infoMsg "\twaiting for bitstream generation to complete"; }
      wait_on_run impl_1
   } else {
     infoMsg "Bitstream has already been run!"
   }
      
   markLastStep bitstreamRun
}
lappend loadedProcs {bitstreamRun "builds the bitstream"};
# current limitations: only works for ZC702 and Zed boards due to part selection
#/**
# * proc:  hardwareManagerOpen
# * descr: 
# * @meta <list of searchable terms> 
# */
proc hardwareManagerOpen {} {
   variable tcName
   variable trainingPath
   variable blockDesignName
   variable verbose   
   if {$verbose} { puts "completer_helper.hardwareManagerOpen"; }
   
   open_hw;             # open the hardware manager
   connect_hw_server;   #
   open_hw_target;      #
   set_property PROGRAM.FILE {$trainingPath/$tcName/lab/$tcName.runs/impl_1/$blockDesignName.bit} [get_hw_devices xc7z020_1]
   set_property PROBES.FILE {$trainingPath/$tcName/lab/$tcName.runs/impl_1/$blockDesignName.ltx} [get_hw_devices xc7z020_1]
   set_property FULL_PROBES.FILE {$trainingPath/$tcName/lab/$tcName.runs/impl_1/$blockDesignName.ltx} [get_hw_devices xc7z020_1]
   current_hw_device [get_hw_devices xc7z020_1]
   refresh_hw_device [lindex [get_hw_devices xc7z020_1] 0]
   display_hw_ila_data [ get_hw_ila_data hw_ila_data_1 -of_objects [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"embd_dsgn_i/ila_0"}]]
   
   markLastStep hardwareManagerOpen
}
lappend loadedProcs {hardwareManagerOpen "open the hardware manager"};
#
# ***** export design (local to project)
# Modified for 2019.2 to support Vitis SDK instead of SDK
#/**
# * proc:  designExport
# * descr: 
# * @meta <list of searchable terms> 
# */
proc designExport {} {
   variable tcName
   variable trainingPath
   variable blockDesignName
   variable platform
   variable verbose   
   if {$verbose} { puts "completer_helper.designExport"; }
   
   # support for Vitis IDE
   set xsaFileName $trainingPath/$tcName/lab/UED_
   append xsaFileName [string tolower $platform] .xsa 
   
   write_hw_platform -fixed -force -include_bit -file $xsaFileName

   markLastStep designExport
}
lappend loadedProcs {designExport "export the design for software development"};
#   *** OBSOLETE??? ***
# ***** launch SDK
#
#/**
# * proc:  VitisLaunch
# * descr: WARNING - no tcl proc exists to launch this tool from within Vivado as there was with SDK
# * @meta <list of searchable terms> 
# */
proc VitisLaunch {} {
#   variable tcName
#   variable trainingPath
#   variable blockDesignName
#   variable verbose   
    if {$verbose} { puts "in VitisLaunch - not implemented"; }
#
#   set hdfPath ""
#   append hdfPath $trainingPath/$tcName/lab/$tcName.sdk/$blockDesignName _wrapper.hdf
#   launch_sdk -workspace $trainingPath/$tcName/lab/$tcName.sdk -hwspec $hdfPath
#   
#   markLastStep SDKlaunch
}
#
# ***** close vivado project
#
#/**
# * proc:  VivadoCloseProject
# * descr: 
# * @meta <list of searchable terms> 
# */
proc VivadoCloseProject {} {
   variable verbose
   if {$verbose} { puts "in VivadoCloseProject"; }
   
   close_project;
   
   markLastStep VivadoCloseProject
}
lappend loadedProcs {VivadoCloseProject "closes the open Vivado project"};
#
# ***** closeVivado
#
#/**
# * proc:  VivadoClose
# * descr: 
# * @meta <list of searchable terms> 
# */
proc VivadoClose {} { exit; }
lappend loadedProcs {VivadoClose "close the Vivado tool"};
#
# assumes that make contains the buildStartingPoint state
#/**
# * proc:  buildStartingPoint
# * descr: 
# * @meta <list of searchable terms> 
# */
proc buildStartingPoint {} { make buildStartingPoint }
lappend loadedProcs {buildStartingPoint "launch the starting point from make"};

proc indirect { var } {
   set variableName [string range $var 1 [string length $var]]
   puts "variable name is $variableName"
   variable $variableName;           # the variable referenced by var is not scoped inside this proc unless forces. This should make it available.
   set thisArg [format [subst $var]];        # now that it is available, get the value 
   puts "value of thisArg = $thisArg"
   return $thisArg
}
lappend loadedProcs {indirect "not ready for prime time"};


#
# *** Clear everything from the canvas
#
#/**
# * proc:  clearAll
# * descr: 
# * @meta <list of searchable terms> 
# */
proc clearAll {} {
   delete_bd_objs [get_bd_nets *]
   delete_bd_objs [get_bd_intf_ports *]
   delete_bd_objs [get_bd_ports *]
   delete_bd_objs [get_bd_cells *]
}
lappend loadedProcs {clearAll "removes all objects in the canvas"};

set completer_helper_loaded 1;

if ($debug) {
   puts "Done with load of completer_helper.tcl";
}
