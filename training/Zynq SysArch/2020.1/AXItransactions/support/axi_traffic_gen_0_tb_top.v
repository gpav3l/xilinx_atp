// (c) Copyright 2012 - 2013 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

`timescale 1ns/1ps
module axi_traffic_gen_0_tb_top ();

//Clock Generation:
//Clock period 10 nano-seconds(10ns)
parameter EXDES_CLK_PERIOD = 10 ;
reg axi_aclk;
wire done  ;
wire [31:0]  status;

always begin
  axi_aclk = 0;
  forever #(EXDES_CLK_PERIOD/2) axi_aclk = ~axi_aclk;
end

//Reset Generation:
reg reset;
initial begin
 reset = 1'b0;
 #100;
 reset = 1'b1;
end

//Example Design Instantiation:
ATG_wrapper ATG_wrapper_i (
  .s_axi_aclk     (axi_aclk),
  .s_axi_aresetn  (reset),         
  .done           (done),
  .status         (status)
);


//Pass/Fail Check:
always @(posedge axi_aclk) begin
 if(reset == 1'b1 && done == 1'b1) begin
   $display("EXDES:Done Received");
   $display("Test Status :%d",status[1:0]);
  
   if(status[1:0] == 2'b01) begin
     $display("Test Completed Successfully");
   end else if(status[1:0] == 2'b11 )begin
     $display("ERROR:Test did not complete (timed-out)");
   end else begin
     $display("ERROR:Test Failed");
   end
   $finish;
 end
end
  
initial begin
     #10000;
     $display("Test Failed !! Test Timed Out");
     $finish;
end

endmodule
