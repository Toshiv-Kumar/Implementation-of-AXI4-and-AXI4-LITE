
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 19:51:09
// Design Name: 
// Module Name: axi_wrapped_ram
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


// AXI design for cpu and ram
// MASTER == CPU == MANAGER and SLAVE == RAM == SUBORDINATE, We are in the middle, this is what interface means.
module axi_full_wraps_ram #(parameter data_width = 32,
    					parameter address_width = 4,
    					parameter depth = 16,
    					parameter resp_okay = 2'b00,
    					parameter resp_DECERR = 2'b10, // The request has not reached a point where data can be written. The
    					// location might not be fully updated. Typically used when the address
    					// decodes to an invalid address.
 						parameter idle = 2'b00,
 						parameter write = 2'b01,
 						parameter read = 2'b10,
 						parameter resp = 2'b11,
 						parameter FIXED = 2'b00, // FIFO buffer
 						parameter INCR  = 2'b01, // normal sequential memory. I will use this one here.
 						parameter WRAP  = 2'b10, // cache line
 						parameter RSV   = 2'b11,
 						parameter ID_R_WIDTH = 2,
 						parameter ID_W_WIDTH = 2
    					)(
    					input aclk,
    					input aresetn,
    					
    					// signals corresponding to write address channel: master to slave
    					input [address_width-1:0] s_axi_AWADDR, // address signal
    					
    					
    					input [3:0] AWLEN, // control signal
    					input [2:0] AWSIZE, // control signal: Max can be 101
    					input [1:0] AWBURST, // control signal
    					// Upper 3 signals are from master during address phase
    					input s_axi_AWVALID,// address info SENT is valid or not?
    					output reg s_axi_AWREADY,// slave is ready to accept address. before/after valid 
    					// here the AXI will take the role of instantiating this signal, even though you might think that the ram inside would be in control. It is not, axi is.
    					
    					
    					// signals corresponding to write data channel: master to slave
    					input [data_width-1:0] s_axi_WDATA,
 						input [(data_width >>3) -1:0]WSTRB,
    					input WLAST,
    					input s_axi_WVALID, // if data is valid or not
    					output reg s_axi_WREADY, // if slave can accept a write data
    					
    					// signals corresponding to write response channel: slave to master
    					output reg [1:0]BRESP, // if okay-: write is completed, slv_error then end stage reached but not written.
    					output reg BVALID, // asserted side by side BRESP
    					input BREADY, // if master can accept the write response information
    					
    					
    					
    					// signals corresponding to read address channel: master to slave
    					input [address_width-1:0] s_axi_ARADDR,
    					input [3:0]ARLEN,
    					input [2:0]ARSIZE,
    					input [1:0]ARBURST,
    					input s_axi_ARVALID, // 
    					output reg ARREADY, // slave is ready to accept the address signal: input address can be changed
    					
    					// signals corresponding to read data channel: slave to master
  						output reg [data_width-1:0] s_axi_RDATA,
  						output reg RLAST,
  						output reg s_axi_RVALID,// if address was empty by xxx data, even then there is some data transferred so valid = 1 but resp tells decerr to master.
  						input s_axi_RREADY,
  						output reg  [(data_width >>3) -1:0]rstrb,
  						
  						output reg [1:0] write_state,
  						output reg [1:0]read_state,
  						output reg ram_write_enb,
  						input [ID_R_WIDTH-1:0] AWID,
  						input [ID_R_WIDTH-1:0] ARID,
  						output wire [ID_W_WIDTH-1:0] BID,
  						output wire [ID_W_WIDTH-1:0] RID
    					); 
    					
    					reg [address_width -1: 0] write_addr_reg, read_addr_reg;
    					reg [2:0]awsize_reg; reg [2:0]shift_to_next_addr_point; reg [2:0] shift_to_next_addr_point_read_burst;
    					reg [2:0]arsize_reg; reg [3:0] arlen_reg;
    					// signals connected to the ram
    					
    					
    					reg [address_width -1: 0] w_ram_addr;
    					reg [address_width -1: 0] r_ram_addr;
    					reg [data_width -1: 0] ram_wdata;
    					wire [data_width -1: 0] ram_rdata;
    					reg [1:0] iter; reg [1:0] iter_read;
    					
    					ram uut (.r_WSTRB(WSTRB), .r_RID(RID), .r_BID(BID), .r_ARID(ARID), .r_AWID(AWID), .clk(aclk),.rst_n(aresetn), .write_enb(ram_write_enb), .r_addr(r_ram_addr), .w_addr(w_ram_addr), .wdata(ram_wdata), .rdata(ram_rdata));
    					
    					
    					
    					// write_address_channel logic and write_state logic in this always block
    					always @(posedge aclk) begin
    						if (aresetn == 1'b0) begin
    							write_state <= idle;
    							s_axi_AWREADY <= 1'b0;
    							write_addr_reg <= 0;
    							iter <= 0;
    							end
    						else begin
    							case (write_state)
    								idle: begin
    								 		iter <= 0;
    								
    									if (s_axi_AWREADY == 1'b1 && s_axi_AWVALID == 1'b1) begin
    										write_addr_reg <= s_axi_AWADDR;
    										awsize_reg <= AWSIZE;
    										write_state <= write;
    										s_axi_AWREADY <= 1'b0;
    										end
    									else begin
    										s_axi_AWREADY <= 1'b1;
    										end	
    									end
    								write: begin
    									if (s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1 && WLAST == 1'b1) begin
    								  					write_state <= resp;
    								  					iter <= 0;
    								  					
    								  		end
    									else if (s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1) begin
    										
    										
    										iter <= iter + 1;
    										end
    									
    								
    									end
    								resp: begin
    									if (BVALID == 1'b1 && BREADY == 1'b1) write_state <= idle;
    									
    									iter <= 0;
    									end
    								default: write_state <= idle;
    								endcase
    							end
    						end
						
						
						always @(awsize_reg) begin
							case(awsize_reg)
								3'b000: shift_to_next_addr_point = (data_width>>3)>>awsize_reg;// 4
								3'b001: shift_to_next_addr_point = (data_width>>3)>>awsize_reg;// 2
								3'b010: shift_to_next_addr_point = (data_width>>3)>>awsize_reg;// 1
							endcase
							end
   					// write_data_channel logic in this always block
    					always @(posedge aclk) begin
    						if (aresetn == 1'b0) begin
    							s_axi_WREADY <= 1'b0;
    							end
    						else begin
    							case (write_state)
    								idle: begin
 
 									
 										end
    								write: begin
    									
    									
    								  	if (s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1 && WLAST == 1'b1) begin
    										ram_wdata <= s_axi_WDATA;
    										if (iter >= shift_to_next_addr_point || (shift_to_next_addr_point*(iter/shift_to_next_addr_point)) == iter) begin
    										    if (iter != 0) w_ram_addr <= write_addr_reg + (iter/shift_to_next_addr_point);
    										    else w_ram_addr <= write_addr_reg;
    										    end
    										else begin
    											w_ram_addr <= write_addr_reg;
    										    end
    										s_axi_WREADY <= 1'b0;								  	
    								  		end
    									else if (s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1) begin
    										ram_wdata <= s_axi_WDATA;
    										if (iter >= shift_to_next_addr_point || (shift_to_next_addr_point*(iter/shift_to_next_addr_point)) == iter) begin
    											if (iter != 0) w_ram_addr <= write_addr_reg + (iter/shift_to_next_addr_point);
    											else w_ram_addr <= write_addr_reg;
    												end
    										else begin
    											w_ram_addr <= write_addr_reg;
    											end
    										s_axi_WREADY <= 1'b0;
    										end
    									else begin
    										s_axi_WREADY <= 1'b1;  
    										end
    								
    									end
    								resp: begin
    									 
    									end
    								default: begin end
    								endcase
    							end
    						end
    						
    						
   					// write_response channel logic in this always block
    					always @(posedge aclk) begin
    						if (aresetn == 1'b0) begin
    							BVALID <= 1'b0;
    							end
    						else begin
    							case (write_state)
    								idle: begin
 									
 									
 										end
    								write: begin
  										end
  										
    								resp: begin
    									 if (write_addr_reg >= 4'b1110) begin
    									 	BVALID <= 1'b1;
    									 	BRESP <= resp_DECERR;	
    									 	end
    									 	
    									 else begin
    									 	BVALID <= 1'b1;
    									 	BRESP <= resp_okay;
    									 	end
    									 if (BVALID == 1'b1 && BREADY == 1'b1) BVALID <= 1'b0;
    									end
    								default: begin end
    								endcase
    							end
    						end
    						
   						
    						
  					// read_address_channel logic and read_state logic in this always block
    					always @(posedge aclk) begin
    						if (aresetn == 1'b0) begin
    							read_state <= idle;
    							ARREADY <= 1'b0;
    							read_addr_reg <= 0;
    							iter_read <= 0;
    							
    							end
    						else begin
    							case (read_state)
    								idle: begin
    								 	iter_read <= 0;
    								
    									if (ARREADY == 1'b1 && s_axi_ARVALID == 1'b1) begin
    										rstrb <= (1 << (1 << ARSIZE)) - 1;
    										read_addr_reg <= s_axi_ARADDR;
    										read_state <= read;
    										ARREADY <= 1'b0;
    										arsize_reg <= ARSIZE;
    										arlen_reg <= ARLEN;
    										end
    										
    									else begin
    										ARREADY <= 1'b1;
    										end
    									end
    								read: begin
    								if (iter_read == shift_to_next_addr_point_read_burst || (shift_to_next_addr_point_read_burst*(iter_read/shift_to_next_addr_point_read_burst)) == iter_read) begin
    									if (iter_read != 0) rstrb <= (1 << (1 << ARSIZE)) - 1;
    									end
    									
    									if  (s_axi_RVALID == 1'b1 && s_axi_RREADY == 1'b1 && RLAST == 1'b1) begin
    									
    										iter_read <= 0;
    										read_state <= idle;								
    										end
    									else if (s_axi_RVALID == 1'b1 && s_axi_RREADY == 1'b1) begin
    										iter_read <= iter_read + 1;    
    										rstrb <= rstrb << (1<<arsize_reg);
    										
    										end
    									
    								
    									end
    								
    								default: read_state <= idle;
    								endcase
    							end
    						end
    					
    					
						always @(arsize_reg) begin
    							case(arsize_reg)
    								3'b000: shift_to_next_addr_point_read_burst = (data_width>>3)>>arsize_reg;// 4
    								// rstrb here shifts 1 time every next iter, resets to start at shift_toaddr point
    								// initialize rsstrb= 1
    								
    								3'b001: shift_to_next_addr_point_read_burst = (data_width>>3)>>arsize_reg;// 2
    								// rstrb here shifts 2 times to left every next iter, resets to start at shift_toaddr point
									// initialize rsstrb= 3
    								
    								3'b010: shift_to_next_addr_point_read_burst = (data_width>>3)>>arsize_reg;// 1
    								// initialize rsstrb= 15
    								// rstrb here shifts 4(rstrb<<(1<<arsize)) times to left every next iter, resets to start at shift_toaddr point
    								
    								// next is 255
    							endcase
    						end 	
    					// read_data_channel logic in this always block
    					always @(posedge aclk) begin
    						if (aresetn == 1'b0) begin
    							s_axi_RVALID <= 1'b0;
    							end
    						else begin
    							case (read_state)
    								idle: begin
 									
     									s_axi_RVALID <= 1'b0;	
			
 										end
    								read: begin
    									
										if  (s_axi_RVALID == 1'b1 && s_axi_RREADY == 1'b1 && RLAST == 1'b1) begin
											s_axi_RVALID <= 1'b0;
											RLAST <= 1'b0;
										
											end
    									else if (s_axi_RVALID == 1'b1 && s_axi_RREADY == 1'b1) begin
    										
    										s_axi_RVALID <= 1'b0;
																					
    									
    										end
    									else if ( ram_write_enb == 1'b0 && s_axi_RREADY == 1'b1) begin
    										s_axi_RVALID <= 1'b1;
    								   		// byte 0 (bits 7:0)
    										 s_axi_RDATA[ 7: 0] <= rstrb[0] ? ram_rdata[ 7: 0] : 8'h00;
    										 // byte 1 (bits 15:8)
    										 s_axi_RDATA[15: 8] <= rstrb[1] ? ram_rdata[15: 8] : 8'h00;
    										 // byte 2 (bits 23:16)
    										 s_axi_RDATA[23:16] <= rstrb[2] ? ram_rdata[23:16] : 8'h00;
    										 // byte 3 (bits 31:24)
    										 s_axi_RDATA[31:24] <= rstrb[3] ? ram_rdata[31:24] : 8'h00;
    										end
    									else begin
    									  if (iter_read >= shift_to_next_addr_point_read_burst || (shift_to_next_addr_point_read_burst*(iter_read/shift_to_next_addr_point_read_burst)) == iter_read) begin
    									    if (iter_read != 0) r_ram_addr <= read_addr_reg + (iter_read/shift_to_next_addr_point_read_burst);
    									    else r_ram_addr <= read_addr_reg;
    									      end
    									  else begin
    										  r_ram_addr <= read_addr_reg;
    									      end
    									      if (iter_read == arlen_reg) RLAST <= 1'b1;
    										// ram_write_enb = 0 needs to be done here or later if write prioritized first
    										// RREADY is to be turned on here or a bit later by the master.
    										// It can't be turned on before. Always keep it off.
    										end
    								
    									end
    								
    								default: begin  s_axi_RVALID <= 1'b0;	end
    								endcase
    							end
    						end
    						
    						
    						// ram_write_enb logic block that handles both read and write logic simultaneously
    						
    						always @(posedge aclk) begin
    							if (aresetn == 1'b0) begin
    								ram_write_enb <= 1'b0;
    								
    								end
    							else begin
    								case (write_state)
    									idle: begin
    									 	ram_write_enb <= 1'b0;
    			
    										end
    									write: begin
    										
    										if (s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1) begin
    											
    											ram_write_enb <= 1'b1;
    											
    											end
    										
    									
    										end
    									resp: begin
											ram_write_enb <= 1'b0;
    										end
    									default: ram_write_enb <= 1'b0;
    									endcase
   							case (read_state)   // wen can handle interupts from write logic.
    								idle: begin
    								 	
    									if (~(s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1)) ram_write_enb <= 1'b0;
    									end
    								read: begin
    									if (s_axi_RVALID == 1'b1 && s_axi_RREADY == 1'b1) begin
    									
											if (~(s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1)) ram_write_enb <= 1'b0;    										
    									
    									
    										end
    									else if ( ram_write_enb == 1'b0 && s_axi_RREADY == 1'b1) begin
    										
    										if (~(s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1)) ram_write_enb <= 1'b0;
    										end
    									else begin
    										if (~(s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1)) ram_write_enb <= 1'b0;// ram_write_enb = 0 needs to be done here.
    										// RREADY is to be turned on here or a bit later by the master.
    										// It can't be turned on before. Always keep it off before.
    										end
    								
    									end
    								
    									
    								
    								
    								default: begin ram_write_enb <= 1'b0; end
    								endcase
    								end
    							end
endmodule
