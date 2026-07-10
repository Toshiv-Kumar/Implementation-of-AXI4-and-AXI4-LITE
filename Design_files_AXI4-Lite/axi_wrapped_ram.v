
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


// AXI-LITE design for cpu and ram
// MASTER == CPU == MANAGER and SLAVE == RAM == SUBORDINATE, We are in the middle, this is what interface means.
module axi_wrapped_ram #(parameter data_width = 32,
    					parameter address_width = 4,
    					parameter depth = 16,
    					parameter resp_okay = 2'b00,
    					parameter resp_DECERR = 2'b10, // The request has not reached a point where data can be written. The
    					// location might not be fully updated. Typically used when the address
    					// decodes to an invalid address.
 						parameter idle = 2'b00,
 						parameter write = 2'b01,
 						parameter read = 2'b10,
 						parameter resp = 2'b11
    					)(
    					input aclk,
    					input aresetn, 
    					
    					
    					 
    					 
    					
    					
    					// signals corresponding to write address channel: master to slave
    					input [address_width-1:0] s_axi_AWADDR, // address signal
    					
  //  					input [3:0] AWLEN, // control signal
  //  					input [2:0] AWSIZE, // control signal
  //  					input [1:0] AWBURST, // control signal
    					input s_axi_AWVALID,// address info SENT is valid or not?
    					output reg s_axi_AWREADY,// slave is ready to accept address. before/after valid 
    					// here the AXI will take the role of instantiating this signal, even though you might think that the ram inside would be in control. It is not, axi is.
    					
    					
    					// signals corresponding to write data channel: master to slave
    					input [data_width-1:0] s_axi_WDATA,
  //					input [data_width>>3-1:0] WSTRB,
  //  					input WLAST,
    					input s_axi_WVALID, // if data is valid or not
    					output reg s_axi_WREADY, // if slave can accept a write data
    					
    					// signals corresponding to write response channel: slave to master
    					output reg [1:0]BRESP, // if okay-: write is completed, slv_error then end stage reached but not written.
    					output reg BVALID, // asserted side by side BRESP
    					input BREADY, // if master can accept the write response information
    					
    					
    					
    					// signals corresponding to read address channel: master to slave
    					input [address_width-1:0] s_axi_ARADDR,
  //  					input [3:0]ARLEN,
  //  					input [2:0]ARSIZE,
  //  					input [1:0]ARBURST,
    					input s_axi_ARVALID, // 
    					output reg ARREADY, // slave is ready to accept the address signal: input address can be changed
    					
    					// signals corresponding to read data channel: slave to master
  						output [data_width-1:0] s_axi_RDATA,
  //					output reg [1:0] RRESP, //tells if data sent NOW is fine or there is slv_error(eg of unsigned no.), decerr(address issue)
  //					output reg RLAST,
  						output reg s_axi_RVALID,// if address was empty by xxx data, even then there is some data transferred so valid = 1 but resp tells decerr to master.
  						input s_axi_RREADY,
  						
  						output reg [1:0] write_state,
  						output reg [1:0]read_state,
  						output reg ram_write_enb
    					); 
    					
    					
     					/// to be stored in axi n=interface till it is okay to proceed with transfer.

    					reg [address_width -1: 0] write_addr_reg, read_addr_reg;
    					
    					// signals connected to the ram
    					
    					reg [address_width -1: 0] w_ram_addr;
    					reg [address_width -1: 0] r_ram_addr;
    					reg [data_width -1: 0] ram_wdata;
    					wire [data_width -1: 0] ram_rdata;
    					
    					ram_design uut (.clk(aclk),.rst_n(aresetn), .write_enb(ram_write_enb), .r_addr(r_ram_addr), .w_addr(w_ram_addr), .wdata(ram_wdata), .rdata(ram_rdata));
    					assign s_axi_RDATA = ram_rdata;
    					
    					// write_address_channel logic and write_state logic in this always block
    					always @(posedge aclk) begin
    						if (aresetn == 1'b0) begin
    							write_state <= idle;
    							s_axi_AWREADY <= 1'b0;
    							write_addr_reg <= 0;
    							
    							end
    						else begin
    							case (write_state)
    								idle: begin
    								 	s_axi_AWREADY <= 1'b1;
    								
    									if (s_axi_AWREADY == 1'b1 && s_axi_AWVALID == 1'b1) begin
    										write_addr_reg <= s_axi_AWADDR;
    										write_state <= write;
    										s_axi_AWREADY <= 1'b0;
    										end
    									end
    								write: begin
    									
    									if (s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1) begin
    										
    										write_state <= resp;
    										
    										end
    									
    								
    									end
    								resp: begin
    									if (BVALID == 1'b1 && BREADY == 1'b1) write_state <= idle;
    									end
    								default: write_state <= idle;
    								endcase
    							end
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
    									
    									s_axi_WREADY <= 1'b1;  //: do this in write_data channel
    									if (s_axi_WVALID == 1'b1 && s_axi_WREADY == 1'b1) begin
    										ram_wdata <= s_axi_WDATA;
    										w_ram_addr <= write_addr_reg;
    										
    										s_axi_WREADY <= 1'b0;
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
    							
    							end
    						else begin
    							case (read_state)
    								idle: begin
    								 	ARREADY <= 1'b1;
    								
    									if (ARREADY == 1'b1 && s_axi_ARVALID == 1'b1) begin
    										read_addr_reg <= s_axi_ARADDR;
    										read_state <= read;
    										ARREADY <= 1'b0;
    										end
    									end
    								read: begin
    									
    									if (s_axi_RVALID == 1'b1 && s_axi_RREADY == 1'b1) begin
    										
    										read_state <= idle;
    										
    										end
    									
    								
    									end
    								
    								default: read_state <= idle;
    								endcase
    							end
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
    									

    									if (s_axi_RVALID == 1'b1 && s_axi_RREADY == 1'b1) begin
    										
    										s_axi_RVALID <= 1'b0;
    										
    									
    										end
    									else if ( ram_write_enb == 1'b0 && s_axi_RREADY == 1'b1) begin
    										s_axi_RVALID <= 1'b1;
    								
    										end
    									else begin
    										
    										r_ram_addr <= read_addr_reg;// ram_write_enb = 0 needs to be done here.
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
   							case (read_state)
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
    										// It can't be turned on before. Always keep it off.
    										end
    								
    									end
    								
    									
    								
    								default: begin ram_write_enb <= 1'b0; end
    								endcase
    								end
    							end
endmodule
