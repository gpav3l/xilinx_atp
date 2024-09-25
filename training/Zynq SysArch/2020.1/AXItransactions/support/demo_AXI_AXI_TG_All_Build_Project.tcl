# Builds the  intro to AXI Demo
# Shaun C	  12/10/2016 	GUI is now not started and the exit is not called
#							allows build automation
# Lance Roman 2/10/2016
#
#start_gui

set hostOS [lindex $tcl_platform(os) 0]
if { $hostOS == "Windows" } {
    set trainingPath "c:"
    set xilinxPath "c:/Xilinx"
} else {
    set trainingPath "/home/xilinx"
    set xilinxPath "/opt/Xilinx/Vivado_SDK"
}

create_project AXI_TG $trainingPath/training/AXI/demos/AXI_TG -part xc7z020clg484-1
set_property board_part xilinx.com:zc702:part0:1.2 [current_project]
set_property target_language Verilog [current_project]

# Create a block design with an ATG and AXI BRAM Controller with 64KB RAM
create_bd_design "ATG"
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0
endgroup
startgroup
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "New Blk_Mem_Gen" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "/axi_bram_ctrl_0_bram" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_traffic_gen:2.0 axi_traffic_gen_0
endgroup
# Assign created COE files to the ATG
startgroup
set_property -dict [list CONFIG.C_ATG_SYSTEM_INIT_DATA_MIF {$trainingPath/training/AXI/demos/AXI_TG/data.coe} CONFIG.C_ATG_SYSTEM_INIT_ADDR_MIF {$trainingPath/training/AXI/demos/AXI_TG/addr.coe} CONFIG.C_ATG_SYSTEM_INIT_MASK_MIF {$trainingPath/training/AXI/demos/AXI_TG/mask.coe} CONFIG.C_ATG_SYSTEM_INIT_CTRL_MIF {$trainingPath/training/AXI/demos/AXI_TG/ctrl.coe} CONFIG.C_ATG_MODE {AXI4-Lite} CONFIG.C_ATG_SYSINIT_MODES {System_Test} CONFIG.C_ATG_SYSTEM_CMD_MAX_RETRY {2147483647}] [get_bd_cells axi_traffic_gen_0]
endgroup
startgroup
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.ECC_TYPE {0}] [get_bd_cells axi_bram_ctrl_0]
endgroup
connect_bd_intf_net [get_bd_intf_pins axi_traffic_gen_0/M_AXI_LITE_CH1] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
startgroup
create_bd_port -dir I -type clk s_axi_aclk
connect_bd_net [get_bd_pins /axi_traffic_gen_0/s_axi_aclk] [get_bd_ports s_axi_aclk]
endgroup
startgroup
create_bd_port -dir I -type rst s_axi_aresetn
connect_bd_net [get_bd_pins /axi_traffic_gen_0/s_axi_aresetn] [get_bd_ports s_axi_aresetn]
endgroup
startgroup
create_bd_port -dir O -from 31 -to 0 status
connect_bd_net [get_bd_pins /axi_traffic_gen_0/status] [get_bd_ports status]
endgroup
startgroup
create_bd_port -dir O done
connect_bd_net [get_bd_pins /axi_traffic_gen_0/done] [get_bd_ports done]
endgroup
connect_bd_net [get_bd_ports s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_traffic_gen_0/s_axi_aclk]
regenerate_bd_layout -routing
regenerate_bd_layout
assign_bd_address
set_property range 64K [get_bd_addr_segs {axi_traffic_gen_0/Reg1/SEG_axi_bram_ctrl_0_Mem0}]
save_bd_design
close_bd_design [get_bd_designs ATG]

# Import created wave and testbench files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
import_files -fileset sim_1 -norecurse $TCsources/axi_traffic_gen_0_tb_top_behav.wcfg $TCsources/axi_traffic_gen_0_tb_top.v

# Create wrapper file
make_wrapper -files [get_files $trainingPath/training/AXI/demos/AXI_TG/AXI_TG.srcs/sources_1/bd/ATG/ATG.bd] -top
add_files -norecurse $trainingPath/training/AXI/demos/AXI_TG/AXI_TG.srcs/sources_1/bd/ATG/hdl/ATG_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

close_project

file delete -force $TCsources/*vivado*.*

#exit

