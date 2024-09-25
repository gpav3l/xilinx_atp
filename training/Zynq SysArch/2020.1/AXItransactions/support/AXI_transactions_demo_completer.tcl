# 
# **********************************************************************************
#
# Builds the AXI Transactions Demo
#
# History:
# WK          05/21/2018   - upgraded for 2018.1 to use completer helper script
#   ***future***           - upgrade to use completer helper script\
# WK          11/18/2016   - mod for 2016.3 directory structure
# Shaun C	  07/01/2016   - Minor modificiation to pick the coe files from the
#							 support directory
# WK          6/30/2016 - prepped for 2016.1
# Lance Roman 2/10/2016; 
# Shaun C	  12/10/2015 	GUI is now not started and the exit is not called
#							allows build automation
#
# **********************************************************************************
#

puts "Version 2018.1 - 21st May 2018"

# identify this TopicCluster
set hostOS [lindex $tcl_platform(os) 0]
if { $hostOS == "Windows" } {
    set trainingPath "c:"
    set xilinxPath "c:/Xilinx"
} else {
    set trainingPath "/home/xilinx"
    set xilinxPath "/opt/Xilinx/Vivado_SDK"
}

# load the helper script
source $::env(tools)/helper.tcl
source $::env(tools)/completer_helper.tcl

# enumerate the parameters of the project (used by completer_helper)
variable tcName     AXItransactions
variable labName    AXItransactions
variable projName        $labName
variable demoOrLab       demo
variable verbose         1
variable blockDesignName "ATG"

# set the language use - not relevant, but needed for procs
use VHDL
use ZCU104

# build the table of steps
set stepList {{projectCreate blockDesignCreate IPaddAndConnect blockDesignWrap simulationRun}}

# identify the APSoC's PS configuration
variable APSoCactivePeripheralList { CONFIG.PCW_USE_M_AXI_GP0             1                         
							                CONFIG.PCW_UART1_PERIPHERAL_ENABLE   1
							                CONFIG.PCW_EN_CLK0_PORT              1
				                         CONFIG.PCW_EN_RST0_PORT              1
							              }	             
# identify the MPSoC's PS configuration
variable MPSoCactivePeripheralList { CONFIG.PSU__USE__M_AXI_GP2                 1 
                                     CONFIG.PSU__USE__M_AXI_GP0                 1
                                     CONFIG.PSU__USE__S_AXI_GP2                 1
                                     CONFIG.PSU__MAXIGP2__DATA_WIDTH           64
                                     CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE  1
									          CONFIG.PSU__GPIO_EMIO__PERIPHERAL__IO     32
									          CONFIG.PSU__FPGA_PL0_ENABLE                1
									          CONFIG.PSU__USE__FABRIC__RST               1
									          CONFIG.PSU__QSPI__PERIPHERAL__ENABLE       1
									          CONFIG.PSU__UART0__PERIPHERAL__ENABLE      1	
                                   }			 
   
# build the starting point
proc buildStartingPoint {} {
   variable verbose
   if {$verbose} { puts "AXI_transactions_demo_completer.buildStartingPoint"; }
   
   make 1
   
   markLastStep buildStartingPoint
}   

# add the IP and connect_bd_intf_net
proc IPaddAndConnect {} {
   variable hostOS
   variable trainingPath
   variable tcName
   variable blockDesignName
   variable verbose
   if {$verbose} { puts "AXI_transactions_demo_completer.IPaddAndConnect"; }
   
   # remove everything from the canvas
   delete_bd_objs [get_bd_intf_nets *] [get_bd_intf_nets *] [get_bd_cells *] [get_bd_ports *]

   # add the axi_traffic_gen
   create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_traffic_gen:2.0] axi_traffic_gen_0
   
   # remove the old COE files
   if { $hostOS == "Windows" } {
   remove_files  {{c:/training/AXItransactions/support/mask.coe} \
                  {c:/training/AXItransactions/support/data.coe} \
                  {c:/training/AXItransactions/support/ctrl.coe} \
                  {c:/training/AXItransactions/support/addr.coe}}
   } else {
   remove_files  {{/home/xilinx/training/AXItransactions/support/mask.coe} \
                  {/home/xilinx/training/AXItransactions/support/data.coe} \
                  {/home/xilinx/training/AXItransactions/support/ctrl.coe} \
                  {/home/xilinx/training/AXItransactions/support/addr.coe}}
   }
   
   # add the COE files to the ATG
   set dataFile $trainingPath/training/$tcName/support/data.coe
   set maskFile $trainingPath/training/$tcName/support/mask.coe 
   set addrFile $trainingPath/training/$tcName/support/addr.coe
   set ctrlFile $trainingPath/training/$tcName/support/ctrl.coe
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_DATA_MIF $dataFile] [get_bd_cells axi_traffic_gen_0]
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_MASK_MIF $maskFile] [get_bd_cells axi_traffic_gen_0]
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_ADDR_MIF $addrFile] [get_bd_cells axi_traffic_gen_0]
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_CTRL_MIF $ctrlFile] [get_bd_cells axi_traffic_gen_0]
   set_property -dict [list CONFIG.C_ATG_MODE {AXI4-Lite} CONFIG.C_ATG_SYSINIT_MODES {System_Test} ] [get_bd_cells axi_traffic_gen_0]
   set_property -dict [list CONFIG.C_ATG_SYSTEM_CMD_MAX_RETRY {2147483647}]                          [get_bd_cells axi_traffic_gen_0]

   # add the axi_bram_ctrl
   create_bd_cell -type ip -vlnv [latestVersion xilinx.com:ip:axi_bram_ctrl:4.0] axi_bram_ctrl_0

   # add the BRAM and configure
   apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "New Blk_Mem_Gen" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
   apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "/axi_bram_ctrl_0_bram" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
   set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.ECC_TYPE {0}] [get_bd_cells axi_bram_ctrl_0]
   
   # create the extra pads
   create_bd_port -dir I -type clk s_axi_aclk
   create_bd_port -dir I -type rst s_axi_aresetn
   create_bd_port -dir O -from 31 -to 0 status
   create_bd_port -dir O done
   
   # connect everything
   connect_bd_intf_net [get_bd_intf_pins axi_traffic_gen_0/M_AXI_LITE_CH1] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
   connect_bd_net [get_bd_pins /axi_traffic_gen_0/s_axi_aclk] [get_bd_ports s_axi_aclk]
   connect_bd_net [get_bd_pins /axi_traffic_gen_0/s_axi_aresetn] [get_bd_ports s_axi_aresetn]
   connect_bd_net [get_bd_pins /axi_traffic_gen_0/status] [get_bd_ports status]
   connect_bd_net [get_bd_pins /axi_traffic_gen_0/done] [get_bd_ports done]
   connect_bd_net [get_bd_ports s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
   connect_bd_net [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_traffic_gen_0/s_axi_aclk]
   
   # clean it up
   #regenerate_bd_layout -routing
   regenerate_bd_layout

   # assign the board address
   assign_bd_address
   set_property range 64K [get_bd_addr_segs {axi_traffic_gen_0/Reg1/SEG_axi_bram_ctrl_0_Mem0}]

   # save and close
   save_bd_design
   #close_bd_design [get_bd_designs $blockDesignName]
#update_compile_order -fileset sources_1
#open_bd_design {/home/xilinx/training/AXItransactions/demo/AXItransactions.srcs/sources_1/bd/ATG/ATG.bd}
   markLastStep IPaddAndConnect
}


proc simulationRun {} {
   variable trainingPath
   variable tcName
   variable verbose
   if {$verbose} { puts "AXI_transactions_demo_completer.simulationRun"; }
   
   # Import created wave and testbench files
   set TCsources $trainingPath/training/$tcName/support
   set_property SOURCE_SET sources_1 [get_filesets sim_1]
   #import_files -fileset sim_1 -norecurse $trainingPath/training/AXItransactions/support/axi_traffic_gen_0_tb_top_behav.wcfg
   import_files -fileset sim_1 -norecurse $TCsources/axi_traffic_gen_0_tb_top_behav.wcfg $TCsources/axi_traffic_gen_0_tb_top.v
   
   markLastStep simulationRun
}


proc simulationSourcesReset {} {
   variable trainingPath
   variable verbose
   if ($verbose) { puts "AXItransactions_completer.simulationSourcesReset" }
   
   reset_target all [get_files  $trainingPath/training/AXItransactions/demo/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci]
   export_ip_user_files -of_objects  [get_files  $trainingPath/training/AXItransactions/demo/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci] -sync -no_script -force -quiet

   markLastStep simulationSourcesReset
}

proc simulationRun2 {} {
   variable trainingPath
   variable verbose
   if ($verbose) { puts "AXItransactions_completer.simulationRun2" }
   
   generate_target all [get_files $trainingPath/training/AXItransactions/demo/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci]
   export_ip_user_files -of_objects [get_files $trainingPath/training/AXItransactions/demo/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci] -no_script -sync -force -quiet
   export_simulation -of_objects [get_files $trainingPath/training/AXItransactions/demo/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci] -directory $trainingPath/training/AXItransactions/lab/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.ip_user_files/sim_scripts -ip_user_files_dir $trainingPath/training/AXItransactions/lab/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.ip_user_files -ipstatic_source_dir $trainingPath/training/AXItransactions/lab/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.ip_user_files/ipstatic -lib_map_path [list {modelsim=$trainingPath/training/AXItransactions/lab/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/modelsim} {questa=$trainingPath/training/AXItransactions/lab/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/questa} {riviera=$trainingPath/training/AXItransactions/lab/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/riviera} {activehdl=$trainingPath/training/AXItransactions/lab/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/activehdl}] -use_ip_compiled_libs -force -quiet
   create_fileset -blockset atg_lite_agent
   set_property top atg_lite_agent [get_fileset atg_lite_agent]
   move_files -fileset [get_fileset atg_lite_agent] [get_files -of_objects [get_fileset sources_1] $trainingPath/training/AXItransactions/demo/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci]
   launch_run atg_lite_agent_synth_1
   wait_on_run atg_lite_agent_synth_1
   launch_simulation
   open_wave_config $trainingPath/training/AXItransactions/demo/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sim_1/imports/support/axi_traffic_gen_0_tb_top_behav.wcfg
   source axi_traffic_gen_0_tb_top.tcl
   run 15 us
   
   markLastStep simulationRun2
}

# build the project by default
buildStartingPoint
puts "Done building the starting point"

