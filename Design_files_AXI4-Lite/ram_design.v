`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2026 20:06:03
// Design Name: 
// Module Name: ram_design
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ram_design #(parameter data_width = 32,
					parameter address_width = 4,
					parameter depth = 16)(
					input clk,
					input rst_n, 
					input write_enb,
					input [address_width-1:0] r_addr,
					input [address_width-1:0] w_addr,
					input [data_width-1:0] wdata,
					output reg [data_width-1:0] rdata
					); 
					
					reg  [data_width-1:0] mem [0: depth-1];					
  					
  					always @(posedge clk) begin
  						if (rst_n == 1'b0) begin
  							
  							rdata <= 0;
  							
  							end
  						else begin
  							if (write_enb == 1'b1) begin
  									
  									mem[w_addr] <= wdata;
  									
  								end
  							else begin
  								
  								rdata <= mem[r_addr];
  							
  								end
  							
  							end
  					
  						end
endmodule
