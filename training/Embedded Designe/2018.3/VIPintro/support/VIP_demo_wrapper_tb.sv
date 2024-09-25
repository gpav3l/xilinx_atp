//-----------------------------------------------------------------------------------------------------
// System Verilog Testbench for Introduction to VIP Simulation lab
// Name: VIP_demo_wrapper_tb.sv
//
// Description: 
// This file contains example test which shows how Master VIP generate transactions to a 
// custom RTL design perpheral, a LED Controller. 
// The example design consists of one AXI VIP in master mode driving the slave LED Controller
//
// LR  4/20/2017 - Initial Creation
// LR 10/10/2017 - Update for 2017.3
//-----------------------------------------------------------------------------------------------------

`timescale 1ns / 1ps

// ADD HERE (1)
// ADD VIP API library and component database packages (1)

module VIP_demo_wrapper_tb();
  bit  tb_ACLK;         // Clock signal
  bit  tb_ARESETn;      // Reset signal
  reg  tb_cnt_disp;     // LED display content select
  wire [7:0]tb_leds;    // LED outputs
  bit [31:0] addr;      // Address of LED Contoller perpheral

  /*************************************************************************************************
  * "Component_name"_mst_t for master agent
  * "Component_name can be easily found in vivado bd design: click on the instance, 
  * Then click CONFIG under Properties window and Component_Name will be shown
  * More details please refer PG267 for more details
  *************************************************************************************************/
  // ADD HERE (2)

   // instantiate bd
  VIP_demo_wrapper DUT(
    .aclk_0(tb_ACLK),
	.aresetn_0(tb_ARESETn),
    .cnt_disp_0(tb_cnt_disp),
    .leds_0(tb_leds)
     );

 // Reset
 initial begin
        tb_ARESETn <= 1'b0;
    #55 tb_ARESETn <= 1'b1;
  end
 
  // Clcock
  always #10 tb_ACLK <= ~tb_ACLK;

 // Design port control
 // cnt_disp; 0 - display register contents
 //           1 - display internal counter
 initial begin
         tb_cnt_disp <= 1'b0;
    #500 tb_cnt_disp <= 1'b1;     #4000 tb_cnt_disp <= 1'b0;
  end
 
 // AXI Stimulus
 initial begin
    /***********************************************************************************************
    * Before agent is newed, user has to run simulation with an empty testbench to find the hierarchy
    * path of the AXI VIP's instance.Message like
    * "Xilinx AXI VIP Found at Path: my_ip_exdes_tb.DUT.ex_design.axi_vip_mst.inst" will be printed 
    * out. Pass this path to the new function. 
    ***********************************************************************************************/
    // ADD HERE (3)
    agent.start_master();                   // agent start to run

    addr = 32'h44A00000;
    axi_lite_write(addr, 32'h4b);
    axi_lite_write(addr, 32'h36);
    axi_lite_write(addr, 32'h98);
    agent.wr_driver.wait_driver_idle(); 
    axi_lite_read(addr);

    agent.wait_drivers_idle();              // Wait driver is idle then stop the simulation
//    $finish;
  end


  /*************************************************************************************************
  * Generate AXI Lite Write transaction:
  * This simple task shows how user can generate a transaction and fill in information with APIs
  * 1. Declare a handle for write transaction
  * 2. Declare all the variables needed for APIs
  * 3. Assign values to the variables - please make sure that values being assigned here do not
  * 4. Write driver of the agent creates write transaction 
  * 5. Fill in the transaction with APIs 
  *   5.1 Fill in addr, burst,ID,length,size by calling set_write_cmd(addr, burst,ID,length,size), 
  *       different protocol has minimum arguments: 
  *       x here means user can use default value 
  *       AXI4-Lite, set_write_cmd(addr,x,x,x,x),
  * 6. Write driver of the agent sends the transaction 
  *************************************************************************************************/
  task axi_lite_write;
    input bit [31:0] addr;
    input bit [31:0] data;

    axi_transaction              wr_transaction;     //Declare an object handle of write transaction
    xil_axi_uint                 mtestID;            // Declare ID  
    xil_axi_ulong                mtestADDR;          // Declare ADDR  
    xil_axi_len_t                mtestBurstLength;   // Declare Burst Length   
    xil_axi_size_t               mtestDataSize;      // Declare SIZE  
    xil_axi_burst_t              mtestBurstType;     // Declare Burst Type  
    xil_axi_data_beat [255:0]    mtestWUSER;         // Declare Wuser  
    xil_axi_data_beat            mtestAWUSER;        // Declare Awuser  
    /***********************************************************************************************
    * No burst for AXI4LITE and maximum data bits is 64
    * Write Data Value for WRITE_BURST transaction
    * Read Data Value for READ_BURST transaction
    ***********************************************************************************************/
    bit [31:0]                  mtestWData;         // Declare Write Data
    mtestWData = data;
    mtestID = 0;
    mtestADDR = addr;
    mtestBurstLength = 0;
    mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
    mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
    wr_transaction = agent.wr_driver.create_transaction("write transaction in API");
    wr_transaction.set_write_cmd(mtestADDR,mtestBurstType,mtestID,mtestBurstLength,mtestDataSize);
    wr_transaction.set_data_block(mtestWData);
    agent.wr_driver.send(wr_transaction);
  endtask :axi_lite_write

  /************************************************************************************************
  * Read transaction method two
  * This simple task shows how user can generate a transaction and fill in information with APIs 
  * 1. Declare a handle for read transaction
  * 2. Declare all the variables needed for APIs
  * 3. Assign values to the variables - please make sure that values being assigned here do not
  *    violate protocol. For example, mtestADDR can't exceed address range(0,1<<addr_width-1)  
  * 4. Read driver of the agent create_transaction 
  * 5. Fill in the transaction with APIs 
  *   5.1 Fill in addr, burst,ID,length,size by calling set_read_cmd(addr, burst,ID,length,size), 
  *       different protocol has minimum arguments: 
  *       x here means user can use default value 
  *       AXI4-Lite, set_read_cmd(addr,x,x,x,x),
  * 6. Read driver of the agent sends the transaction out
  *************************************************************************************************/
  task axi_lite_read;
    input bit [31:0] addr;

    axi_transaction              rd_transaction;    // Declare an object handle of read transaction
    xil_axi_uint                 mtestID;           // Declare ID  
    xil_axi_ulong                mtestADDR;         // Declare ADDR  
    xil_axi_len_t                mtestBurstLength;  // Declare Burst Length   
    xil_axi_size_t               mtestDataSize;     // Declare SIZE  
    xil_axi_burst_t              mtestBurstType;    // Declare Burst Type  
    xil_axi_data_beat            mtestARUSER;       // Declare Aruser  

    /***********************************************************************************************
    * No burst for AXI4LITE and maximum data bits is 64
    * Write Data Value for WRITE_BURST transaction
    * Read Data Value for READ_BURST transaction
    ***********************************************************************************************/
    bit [31:0]                  mtestRData;         // Declare Read Data
    mtestID = 0;
    mtestADDR = addr;
    mtestBurstLength = 0;
    mtestDataSize = xil_axi_size_t'(xil_clog2(32/8));
    mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
    rd_transaction = agent.rd_driver.create_transaction("read transaction");
    rd_transaction.set_read_cmd(mtestADDR,mtestBurstType,mtestID,mtestBurstLength,mtestDataSize);
    agent.rd_driver.send(rd_transaction);
  endtask :axi_lite_read

endmodule


