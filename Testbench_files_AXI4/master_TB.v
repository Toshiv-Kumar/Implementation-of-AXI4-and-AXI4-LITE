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
  parameter resp          = 2'b11,
  parameter FIXED         = 2'b00,
  parameter INCR          = 2'b01,
  parameter WRAP          = 2'b10,
  parameter RSV           = 2'b11,
  parameter ID_R_WIDTH    = 2,
  parameter ID_W_WIDTH    = 2
);

  // clock/reset
  reg aclk_tb;
  reg aresetn_tb;

  // TB-side signals
  reg  [address_width-1:0] s_axi_AWADDR_tb;
  reg  [3:0]               AWLEN_tb; 
  reg  [2:0]               AWSIZE_tb; // bytes in transfer
  reg  [1:0]               AWBURST_tb;
  reg                      s_axi_AWVALID_tb;
  wire                     s_axi_AWREADY_tb;

  reg  [data_width-1:0]    s_axi_WDATA_tb;
  reg                      WLAST_tb;
  reg                      s_axi_WVALID_tb;
  wire                     s_axi_WREADY_tb;

  wire [1:0]               BRESP_tb;
  wire                     BVALID_tb;
  reg                      BREADY_tb;

  reg  [address_width-1:0] s_axi_ARADDR_tb;
  reg  [3:0]               ARLEN_tb;
  reg  [2:0]               ARSIZE_tb;
  reg  [1:0]               ARBURST_tb;
  reg                      s_axi_ARVALID_tb;
  wire                     ARREADY_tb;

  wire [data_width-1:0]    s_axi_RDATA_tb;
  wire                     RLAST_tb;
  wire                     s_axi_RVALID_tb;
  reg                      s_axi_RREADY_tb;
  wire  [(data_width >>3) -1:0] rstrb_tb;
  wire [1:0]               write_state_tb;
  wire [1:0]               read_state_tb;
  wire                     ram_write_enb_tb;

  reg  [ID_R_WIDTH-1:0]    AWID_tb;
  reg  [ID_R_WIDTH-1:0]    ARID_tb;
  wire [ID_W_WIDTH-1:0]    BID_tb;
  wire [ID_W_WIDTH-1:0]    RID_tb;
  reg  [(data_width >>3) -1:0] WSTRB_tb;
  // DUT instance
  axi_full_wraps_ram #(
    .data_width(data_width),
    .address_width(address_width),
    .depth(depth),
    .resp_okay(resp_okay),
    .resp_DECERR(resp_DECERR),
    .idle(idle),
    .write(write),
    .read(read),
    .resp(resp),
    .FIXED(FIXED),
    .INCR(INCR),
    .WRAP(WRAP),
    .RSV(RSV),
    .ID_R_WIDTH(ID_R_WIDTH),
    .ID_W_WIDTH(ID_W_WIDTH)
  ) dut (
    .aclk(aclk_tb),
    .aresetn(aresetn_tb),

    .s_axi_AWADDR(s_axi_AWADDR_tb),
    .AWLEN(AWLEN_tb),
    .AWSIZE(AWSIZE_tb),
    .AWBURST(AWBURST_tb),
    .s_axi_AWVALID(s_axi_AWVALID_tb),
    .s_axi_AWREADY(s_axi_AWREADY_tb),

	.WSTRB(WSTRB_tb),
    .s_axi_WDATA(s_axi_WDATA_tb),
    .WLAST(WLAST_tb),
    .s_axi_WVALID(s_axi_WVALID_tb),
    .s_axi_WREADY(s_axi_WREADY_tb),

    .BRESP(BRESP_tb),
    .BVALID(BVALID_tb),
    .BREADY(BREADY_tb),

    .s_axi_ARADDR(s_axi_ARADDR_tb),
    .ARLEN(ARLEN_tb),
    .ARSIZE(ARSIZE_tb),
    .ARBURST(ARBURST_tb),
    .s_axi_ARVALID(s_axi_ARVALID_tb),
    .ARREADY(ARREADY_tb),

    .s_axi_RDATA(s_axi_RDATA_tb),
    .RLAST(RLAST_tb),
    .s_axi_RVALID(s_axi_RVALID_tb),
    .s_axi_RREADY(s_axi_RREADY_tb),

    .write_state(write_state_tb),
    .read_state(read_state_tb),
    .ram_write_enb(ram_write_enb_tb),
    .AWID(AWID_tb),
    .ARID(ARID_tb),
    .BID(BID_tb),
    .RID(RID_tb),
    .rstrb(rstrb_tb)
  );
 	reg [1:0] iter;

  
  initial begin
      aclk_tb    = 0;
      
    
    
      s_axi_AWADDR_tb      = 0;
      AWLEN_tb             = 0;
      AWSIZE_tb            = 0;
      AWBURST_tb           = 0;
      s_axi_AWVALID_tb     = 1'b0;
    
      s_axi_WDATA_tb       = 0;
      WLAST_tb             = 1'b0;
      s_axi_WVALID_tb      = 1'b0;
    
      BREADY_tb            = 1'b0;
    
      s_axi_ARADDR_tb      = 0;
      ARLEN_tb             = 0;
      ARSIZE_tb            = 0;
      ARBURST_tb           = 0;
      s_axi_ARVALID_tb     = 1'b0;
    
      s_axi_RREADY_tb      = 1'b0;
    
      AWID_tb              = 0;
      ARID_tb              = 0;
    
      WSTRB_tb             = 0;
    #4 aresetn_tb = 0;
    #2 aresetn_tb = 1;
    #4000 $finish;
  end

  always #5 aclk_tb = ~aclk_tb;
  
  always @(*) begin
  	if ( s_axi_AWVALID_tb == 1'b1) begin
  			AWLEN_tb = 4'b0011;// this ideally comes from cpu directly and we don't need to think about any logic of these signals.
  			AWSIZE_tb = 3'b001;// awsize can at max be 4 bytes, otherwise there would be overflow in the ram and would complicate the logic.
  			AWBURST_tb = INCR;// Fixed to this for a sequential ram.
  			
  		end
  	if (s_axi_WVALID_tb == 1'b1) begin
  		if (iter == 0 || iter == 2) WSTRB_tb = 4'b0011; // this ideally comes from cpu directly and we don't need to think about any logic of these signals.
  		else if (iter == 1 || iter == 3) WSTRB_tb = 4'b1100;
  		end
  
  	end
  	
    always @(*) begin
  		if ( s_axi_ARVALID_tb == 1'b1) begin
  				ARLEN_tb = 4'b0011;// this ideally comes from cpu directly and we don't need to think about any logic of these signals.
  				ARSIZE_tb = 3'b001;// aRsize can at max be 4 bytes, otherwise there would be overflow in the ram and would complicate the logic.
  				ARBURST_tb = INCR;// Fixed to this for a sequential ram.
  				
  			end
  	
  		end
  		
  always @(posedge aclk_tb) begin
  	if (aresetn_tb == 1'b0) begin
 		
    	iter <= 0;
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
  				iter <= 0;	 	
    			if (s_axi_AWREADY_tb == 1'b1 && s_axi_AWVALID_tb == 1'b1) begin
    				s_axi_AWVALID_tb <= 1'b0;
    				s_axi_WDATA_tb <= $urandom();
    				s_axi_WVALID_tb  <= $urandom();
    				BREADY_tb <= $urandom();
    			end
    			else begin
    				s_axi_AWADDR_tb  <= $urandom();
    			  	s_axi_AWVALID_tb <= $urandom(); 
    			end
  				end
  			
  			write: begin
  				if (BREADY_tb == 1'b0) BREADY_tb <= $urandom();
  				if (s_axi_WVALID_tb  == 1'b0) begin if (iter == AWLEN_tb) begin WLAST_tb <= 1'b1; end s_axi_WVALID_tb  <= $urandom(); s_axi_WDATA_tb <= $urandom(); end
  				if (s_axi_WVALID_tb == 1'b1 && s_axi_WREADY_tb == 1'b1 && WLAST_tb == 1'b1) begin
  					s_axi_WVALID_tb <= 1'b0;
  					iter <= 0;
  					WLAST_tb <= 1'b0;
  					end
  				else if (s_axi_WVALID_tb == 1'b1 && s_axi_WREADY_tb == 1'b1) begin
  					s_axi_WVALID_tb <= 1'b0;
  					iter <= iter + 1;
  					
  					end
  				
  			
  				end
  			resp: begin
  					if (BVALID_tb == 1'b1 && BREADY_tb == 1'b1)  BREADY_tb <= 1'b0;
					if (BREADY_tb == 1'b0) BREADY_tb <= $urandom();						
  				end
  			default: begin 
  				WSTRB_tb <= 0;
  				iter <= 0;
  				s_axi_AWADDR_tb  <= 0;
  				s_axi_AWVALID_tb <= 0;
  				s_axi_WDATA_tb    <= 0;
  				s_axi_WVALID_tb   <= 0;
  				BREADY_tb         <= 0;
  				s_axi_ARADDR_tb   <= 0;
  				s_axi_ARVALID_tb  <= 0;
  				s_axi_RREADY_tb   <= 0;  		
  		
  				end
  			endcase
   	case (read_state_tb)
  		idle: begin
  	  			
  			s_axi_RREADY_tb <= 1'b0;
  			if (ARREADY_tb == 1'b1 && s_axi_ARVALID_tb == 1'b1) begin
  				s_axi_ARVALID_tb <= 1'b0;
  				end
  			else begin
  				s_axi_ARADDR_tb   <= $urandom();		
  			  	s_axi_ARVALID_tb  <= $urandom();	
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
