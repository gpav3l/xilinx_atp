#
# **********************************************************************************
#
# AXItransactions_completer.tcl
#
# History:
# 2017/09/28 - WK - Updated for 2017.3
# 10/12/2016 - SC - initial Version based on ArchZyq7000_Overview
#
# **********************************************************************************
#

set hostOS [lindex $tcl_platform(os) 0]
if { $hostOS == "Windows" } {
    set trainingPath "c:"
    set xilinxPath "c:/Xilinx"
} else {
    set trainingPath "/home/xilinx"
    set xilinxPath "/opt/Xilinx/Vivado_SDK"
}

puts "Version 2017.3 - 09/29/2017"

# identify this TopicCluster
variable TCname
set TCname AXItransactions

# load the helper script
source $trainingPath/training/tools/helper.tcl
source $trainingPath/training/tools/completer_helper.tcl

# enumerate the parameters of the project (used by completer_helper)
set tcName          AXItransactions
set labName         $tcName
set projName        $labName
set demoOrLab       lab
set verbose         1
set blockDesignName blkDsgn

# build the table of steps
set stepList {{projectCreate blockDesignCreate}\
              {ATGadd IPexampleDesignOpen coeFileUpdate simFilesAdd behavioralSimulation simulationClose }\
			  {outputProductsReset   behavioralSimulation simulationClose simulationReRun} \
             }

# identify the PS's configuration
variable APSoCactivePeripheralList { CONFIG.PCW_USE_M_AXI_GP0             1                         
							         CONFIG.PCW_UART1_PERIPHERAL_ENABLE   1
							         CONFIG.PCW_EN_CLK0_PORT              1
				                     CONFIG.PCW_EN_RST0_PORT              1
							       }	
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

# set the language use - not relevant, but needed for procs
use VHDL
use ZC702

#
# ********** Add and customize the UART
proc ATGadd {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:ATGadd" }
   
   # clean up a previous version of the ATG
   set cells [get_bd_cells -quiet *uart*]
   delete_bd_objs $cells
   
   # add in the ATG and customize it
   create_ip -name axi_traffic_gen -vendor xilinx.com -library ip -version 3.0 -module_name axi_traffic_gen_0 -dir $trainingPath/training/AXItransactions/lab/ip_placeholder.srcs/sources_1/ip
   generate_target {instantiation_template} [get_files $trainingPath/training/AXItransactions/lab/ip_placeholder.srcs/sources_1/ip/axi_traffic_gen_0/axi_traffic_gen_0.xci]
   update_compile_order -fileset sources_1
   
   markLastStep ATGadd
}

#
# ********** Open IP Example Design, 2-2-3
proc IPexampleDesignOpen {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:IPexampleDesignOpen" }
   
	start_gui
	source $trainingPath/training/AXItransactions/lab/ip_placeholder.srcs/sources_1/ip/axi_traffic_gen_0/axi_traffic_gen_0_ex.tcl -notrace
	update_compile_order -fileset sources_1

   markLastStep IPexampleDesignOpen;
}

	
#
# ********** coeFileUpdate 2-6
proc coeFileUpdate {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:coeFileUpdate" }
   
   # Delete addr.coe, 2-6-4 thru 2-6-5
	export_ip_user_files -of_objects  [get_files $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/addr.coe] -no_script -reset -force -quiet
	remove_files  $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/addr.coe
	
	
    # Delete cntrl.coe, data.coe, and mask.coe, 2-6-6 thru 2-6-8
	export_ip_user_files -of_objects  [get_files $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/ctrl.coe] -no_script -reset -force -quiet
	export_ip_user_files -of_objects  [get_files $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/data.coe] -no_script -reset -force -quiet
	export_ip_user_files -of_objects  [get_files $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/mask.coe] -no_script -reset -force -quiet
	remove_files  {$trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/ctrl.coe $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/data.coe $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/imports/mask.coe}
	
   markLastStep coeFileUpdate;	
}

#
# ********* coeHexFileAdd
proc coeHexFileAdd {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:coeHexFileAdd" }
	
   # Add hex COE files, 2-7-2 thru 2-7-5
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_ADDR_MIF {$trainingPath/training/AXItransactions/support/addr.coe}] [get_ips atg_lite_agent]
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_DATA_MIF {$trainingPath/training/AXItransactions/support/data.coe}] [get_ips atg_lite_agent]
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_MASK_MIF {$trainingPath/training/AXItransactions/support/mask.coe}] [get_ips atg_lite_agent]
   set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_CTRL_MIF {$trainingPath/training/AXItransactions/support/ctrl.coe}] [get_ips atg_lite_agent]

   markLastStep coeHexFileAdd
}

#
# ********** simFilesAdd 2-8
proc simFilesAdd {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:simFilesAdd" }
   
   # Add simulation files, 2-8-1 thru 2-8-10
	set_property SOURCE_SET sources_1 [get_filesets sim_1]
	import_files -fileset sim_1 -norecurse $trainingPath/training/AXItransactions/support/axi_traffic_gen_0_tb_top_behav.wcfg
	
   markLastStep simFilesAdd
}
	
#
# ********** outputProductsReset 3-1
proc outputProductsReset {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:outputProductsReset" }

   # Reset output products, 3-1-3
	set_property SOURCE_SET sources_1 [get_filesets sim_1]
	import_files -fileset sim_1 -norecurse $trainingPath/training/AXItransactions/support/axi_traffic_gen_0_tb_top_behav.wcfg
	reset_target all [get_files  $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci]
	export_ip_user_files -of_objects  [get_files  $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci] -sync -no_script -force -quiet
	
	markLastStep outputProductsReset
}

#
# ********** behavioralSimulation 3-2
proc behavioralSimulation {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:behavioralSimulation" }
   
   # Run behavioral simulation, 3-2-1 
	launch_simulation
		"xvlog --incr --relax -prj axi_traffic_gen_0_tb_top_vlog.prj"
	    "xvhdl --incr --relax -prj axi_traffic_gen_0_tb_top_vhdl.prj"		
	open_wave_config $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sim_1/imports/support/axi_traffic_gen_0_tb_top_behav.wcfg
	source axi_traffic_gen_0_tb_top.tcl
	
	# Run simulation for 15 us, 3-2-2 thru 3-2-3
	run 15 us
		
	markLastStep behavioralSimulation
}

#
# ********** simulationClose 3-4
proc simulationClose {} {
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:simulationClose" }

   #Close simulation, 3-4-1
	close_sim
	
   markLastStep simulationClose
}

		
#***No Tcl output is generated when the data.coe file is modified and saved in tasks 3-5-4 & 3-5-5. I am mentioning it here in case you are going to create "makes" for this lab***


#
# ********* simulationReRun 3-6
proc simulationReRun {} {
   variable trainingPath
   variable verbose
   if {$verbose == 1} { puts "in AXItransaction_completer:simulationReRun" }

   # Reset output products, 3-6-1
	reset_target all [get_files  $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci]
	export_ip_user_files -of_objects  [get_files  $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci] -sync -no_script -force -quiet


	# Rerun simulation, 3-6-1 
	generate_target all [get_files $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci]
	export_ip_user_files -of_objects [get_files $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci] -no_script -sync -force -quiet
	export_simulation -of_objects [get_files $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci] -directory $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.ip_user_files/sim_scripts -ip_user_files_dir $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.ip_user_files -ipstatic_source_dir $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.ip_user_files/ipstatic -lib_map_path [list {modelsim=$trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/modelsim} {questa=$trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/questa} {riviera=$trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/riviera} {activehdl=$trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.cache/compile_simlib/activehdl}] -use_ip_compiled_libs -force -quiet
	create_fileset -blockset atg_lite_agent
	set_property top atg_lite_agent [get_fileset atg_lite_agent]
	move_files -fileset [get_fileset atg_lite_agent] [get_files -of_objects [get_fileset sources_1] $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sources_1/ip/atg_lite_agent/atg_lite_agent.xci]
	launch_run atg_lite_agent_synth_1
	wait_on_run atg_lite_agent_synth_1
    launch_simulation
	open_wave_config $trainingPath/training/AXItransactions/axi_traffic_gen_0_ex/axi_traffic_gen_0_ex.srcs/sim_1/imports/support/axi_traffic_gen_0_tb_top_behav.wcfg
	source axi_traffic_gen_0_tb_top.tcl
	
	markLastStep simulationReRun
}
		
		
