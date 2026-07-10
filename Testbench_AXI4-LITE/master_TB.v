`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2026 18:04:26
// Design Name: 
// Module Name: master_TB
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



module master_TB #(
  parameter data_width    = 32,
  parameter address_width = 4,
  parameter depth         = 16,
  parameter resp_okay     = 2'b00,
  parameter resp_DECERR   = 2'b10,
  parameter idle          = 2'b00,
  parameter write         = 2'b01,
  parameter read          = 2'b10,
  parameter resp          = 2'b11
);

  // clock/reset
  reg aclk_tb;
  reg aresetn_tb;

  // TB-side signals
  
  reg  [address_width-1:0] s_axi_AWADDR_tb;
  reg                      s_axi_AWVALID_tb;
  wire                     s_axi_AWREADY_tb;
  reg  [data_width-1:0]    s_axi_WDATA_tb;
  reg                      s_axi_WVALID_tb;
  wire                     s_axi_WREADY_tb;
  wire [1:0]               BRESP_tb;
  wire                     BVALID_tb;
  reg                      BREADY_tb;
  reg  [address_width-1:0] s_axi_ARADDR_tb;
  reg                      s_axi_ARVALID_tb;
  wire                     ARREADY_tb;
  wire [data_width-1:0]    s_axi_RDATA_tb;
  wire                     s_axi_RVALID_tb;
  reg                      s_axi_RREADY_tb;
  wire [1:0] write_state_tb;
  wire [1:0]read_state_tb;
  wire ram_write_enb_tb;
  // DUT instance
  axi_wrapped_ram dut (
    .aclk(aclk_tb),
    .aresetn(aresetn_tb),
  	.write_state(write_state_tb),
    .read_state(read_state_tb),
    .ram_write_enb(ram_write_enb_tb),
    .s_axi_AWADDR(s_axi_AWADDR_tb),
    .s_axi_AWVALID(s_axi_AWVALID_tb),
    .s_axi_AWREADY(s_axi_AWREADY_tb),

    .s_axi_WDATA(s_axi_WDATA_tb),
    .s_axi_WVALID(s_axi_WVALID_tb),
    .s_axi_WREADY(s_axi_WREADY_tb),

    .BRESP(BRESP_tb),
    .BVALID(BVALID_tb),
    .BREADY(BREADY_tb),

    .s_axi_ARADDR(s_axi_ARADDR_tb),
    .s_axi_ARVALID(s_axi_ARVALID_tb),
    .ARREADY(ARREADY_tb),

    .s_axi_RDATA(s_axi_RDATA_tb),
    .s_axi_RVALID(s_axi_RVALID_tb),
    .s_axi_RREADY(s_axi_RREADY_tb)
  );

  
  initial begin
    aclk_tb    = 0;
	


    #4 aresetn_tb = 0;
    #2 aresetn_tb = 1;
    #1000 $finish;
  end

  always #5 aclk_tb = ~aclk_tb;
  
  always @(posedge aclk_tb) begin
  	if (aresetn_tb == 1'b0) begin
 
    	
  		s_axi_AWADDR_tb  <= 0;
  		s_axi_AWVALID_tb <= 0;
  		s_axi_WDATA_tb    <= 0;
  		s_axi_WVALID_tb   <= 0;
  		BREADY_tb         <= 0;
  		s_axi_ARADDR_tb   <= 0;
  		s_axi_ARVALID_tb  <= 0;
  		s_axi_RREADY_tb   <= 0;  		
  		
  		end
  	else begin
  		case (write_state_tb)
  			idle: begin
  				s_axi_AWADDR_tb  <= $urandom();
  				s_axi_AWVALID_tb <= $urandom(); 			 	
    			if (s_axi_AWREADY_tb == 1'b1 && s_axi_AWVALID_tb == 1'b1) begin
    				s_axi_AWVALID_tb <= 1'b0;
    				s_axi_WDATA_tb <= $urandom();
    				s_axi_WVALID_tb  <= $urandom();
    				BREADY_tb <= $urandom();
    			end
  				end
  			write: begin
  				if (BREADY_tb == 1'b0) BREADY_tb <= $urandom();
  				if (s_axi_WVALID_tb  == 1'b0) s_axi_WVALID_tb  <= $urandom();
  				if (s_axi_WVALID_tb == 1'b1 && s_axi_WREADY_tb == 1'b1) begin
  					s_axi_WVALID_tb <= 1'b0;
  					
  					
  					end
  				
  			
  				end
  			resp: begin
  					if (BVALID_tb == 1'b1 && BREADY_tb == 1'b1)  BREADY_tb <= 1'b0;
					if (BREADY_tb == 1'b0) BREADY_tb <= $urandom();						
  				end
  			default: begin  end
  			endcase
   	case (read_state_tb)
  		idle: begin
  	  		s_axi_ARADDR_tb   <= $urandom();		
  			s_axi_ARVALID_tb  <= $urandom();		
  			s_axi_RREADY_tb <= 1'b0;
  			if (ARREADY_tb == 1'b1 && s_axi_ARVALID_tb == 1'b1) begin
  				s_axi_ARVALID_tb <= 1'b0;
  				end
  			end
  		read: begin
  			if (s_axi_RVALID_tb == 1'b1 && s_axi_RREADY_tb == 1'b1) begin
  				s_axi_RREADY_tb <= 1'b0;
  				end
  			else if ( ram_write_enb_tb == 1'b0 && s_axi_RREADY_tb == 1'b1) begin
  				
  				end
  			else begin
  				if (s_axi_RREADY_tb == 1'b0) s_axi_RREADY_tb <= $urandom();	
  				// ram_write_enb = 0 needs to be done here.
  				// RREADY is to be turned on here or a bit later by the master.
  				// It can't be turned on before. Always keep it off.
  				end
  		
  			end
  		
  		default: begin s_axi_RREADY_tb <= 1'b0; end
  		endcase
  		end
  	end

endmodule


