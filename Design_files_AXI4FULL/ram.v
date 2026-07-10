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


module ram #(		parameter ID_R_WIDTH = 2,
 					parameter ID_W_WIDTH = 2,
					parameter data_width = 32,
					parameter address_width = 4,
					parameter depth = 16)(
					input [(data_width >>3) -1:0]r_WSTRB, // from master
					input clk,
					input rst_n, 
					input write_enb,
					input [address_width-1:0] r_addr,
					input [address_width-1:0] w_addr,
					input [data_width-1:0] wdata,
					input [ID_R_WIDTH-1:0] r_AWID,
					input [ID_R_WIDTH-1:0] r_ARID,
					output reg [ID_W_WIDTH-1:0] r_BID,
					output reg [ID_W_WIDTH-1:0] r_RID,
					output reg [data_width-1:0] rdata
					
					); 
					reg [1:0]i;
					reg  [data_width-1:0] mem [0: depth-1];					
  					
  					always @(posedge clk) begin
  						if (rst_n == 1'b0) begin
  							
  							rdata <= 0;
  							
  							end
  						else begin
  							if (write_enb == 1'b1) begin
								mem[w_addr][ 7: 0] <= r_WSTRB[0] ? wdata[ 7: 0] : mem[w_addr][ 7: 0];
  							    mem[w_addr][15: 8] <= r_WSTRB[1] ? wdata[15: 8] : mem[w_addr][15: 8];
  							    mem[w_addr][23:16] <= r_WSTRB[2] ? wdata[23:16] : mem[w_addr][23:16];
  							    mem[w_addr][31:24] <= r_WSTRB[3] ? wdata[31:24] : mem[w_addr][31:24];
  									
  								end
  							else begin
  								
  								rdata <= mem[r_addr];
  							
  								end
  							
  							end
  					
  						end
endmodule
