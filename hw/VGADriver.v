//========================================================================
// VGADriver.v
//========================================================================
// A low-level VGA driver to display our characters
//
// Inspired by https://vanhunteradams.com/DE1/VGA_Driver/Driver.html

`ifndef HW_VGADRIVER_V
`define HW_VGADRIVER_V

module VGADriver (
  input  logic clk_25M,
  input  logic rst,

  //----------------------------------------------------------------------
  // Character Buffer interface
  //----------------------------------------------------------------------
  // We send the char coordinates one cycle before we need them - the
  // pixel colors for a given coordinate should come back one cycle later

  output  logic [6:0] read_hchar,
  output  logic [5:0] read_vchar,
  output  logic [2:0] read_hoffset,
  output  logic [2:0] read_voffset,
  
  input   logic [3:0] pixel_red,
  input   logic [3:0] pixel_green,
  input   logic [3:0] pixel_blue,

  //----------------------------------------------------------------------
  // VGA Interface
  //----------------------------------------------------------------------

  output  logic [3:0] VGA_R,
  output  logic [3:0] VGA_G,
  output  logic [3:0] VGA_B,
  output  logic       VGA_HS,
  output  logic       VGA_VS
);

  //----------------------------------------------------------------------
  // Define key values
  //----------------------------------------------------------------------

  // Horizontal parameters (measured in clock cycles)
  parameter [9:0] H_ACTIVE = 10'd639;
  parameter [9:0] H_FRONT  = 10'd15;
  parameter [9:0] H_PULSE  = 10'd95;
  parameter [9:0] H_BACK   = 10'd47;

  // Vertical parameters (measured in lines)
  parameter [8:0] V_ACTIVE = 9'd479;
  parameter [8:0] V_FRONT  = 9'd9;
  parameter [8:0] V_PULSE  = 9'd1;
  parameter [8:0] V_BACK   = 9'd32;
  
  //----------------------------------------------------------------------
  // Define states
  //----------------------------------------------------------------------

  localparam H_ACTIVE_STATE = 2'd0;
  localparam H_FRONT_STATE  = 2'd1;
  localparam H_PULSE_STATE  = 2'd2;
  localparam H_BACK_STATE   = 2'd3;

  localparam V_ACTIVE_STATE = 2'd0;
  localparam V_FRONT_STATE  = 2'd1;
  localparam V_PULSE_STATE  = 2'd2;
  localparam V_BACK_STATE   = 2'd3;

  //----------------------------------------------------------------------
  // Define state transitions
  //----------------------------------------------------------------------

  logic [9:0] h_counter;
  logic [8:0] v_counter;
  logic       line_done;

  logic [1:0] h_state;
  logic [1:0] next_h_state;
  logic [1:0] v_state;
  logic [1:0] next_v_state;

  always_ff @( posedge clk_25M ) begin
    if( rst ) begin
      h_state <= H_ACTIVE_STATE;
      v_state <= V_ACTIVE_STATE;
    end else begin
      h_state <= next_h_state;
      v_state <= next_v_state;
    end
  end

  always_comb begin
    next_h_state = h_state;
    next_v_state = v_state;

    case( h_state )
      H_ACTIVE_STATE: if( h_counter == H_ACTIVE ) next_h_state = H_FRONT_STATE;
      H_FRONT_STATE:  if( h_counter == H_FRONT  ) next_h_state = H_PULSE_STATE;
      H_PULSE_STATE:  if( h_counter == H_PULSE  ) next_h_state = H_BACK_STATE;
      H_BACK_STATE:   if( h_counter == H_BACK   ) next_h_state = H_ACTIVE_STATE;
    endcase

    case( v_state )
      V_ACTIVE_STATE: if(( v_counter == V_ACTIVE ) & line_done) next_v_state = H_FRONT_STATE;
      V_FRONT_STATE:  if(( v_counter == V_FRONT  ) & line_done) next_v_state = H_PULSE_STATE;
      V_PULSE_STATE:  if(( v_counter == V_PULSE  ) & line_done) next_v_state = H_BACK_STATE;
      V_BACK_STATE:   if(( v_counter == V_BACK   ) & line_done) next_v_state = H_ACTIVE_STATE;
    endcase
  end

  //----------------------------------------------------------------------
  // Counter logic
  //----------------------------------------------------------------------

  logic [9:0] next_h_counter;
  logic [8:0] next_v_counter;

  always_ff @( posedge clk_25M ) begin
    if( rst ) begin
      h_counter <= '0;
      v_counter <= '0;
    end else begin
      h_counter <= next_h_counter;
      v_counter <= next_v_counter;
    end
  end

  always_comb begin
    next_h_counter = h_counter + 10'd1;
    next_v_counter = v_counter;

    case( h_state )
      H_ACTIVE_STATE: if( h_counter == H_ACTIVE ) next_h_counter = 10'd0;
      H_FRONT_STATE:  if( h_counter == H_FRONT  ) next_h_counter = 10'd0;
      H_PULSE_STATE:  if( h_counter == H_PULSE  ) next_h_counter = 10'd0;
      H_BACK_STATE:   if( h_counter == H_BACK   ) next_h_counter = 10'd0;
    endcase

    if( line_done ) begin
      next_v_counter = v_counter + 9'd1;
      case( v_state )
        V_ACTIVE_STATE: if( v_counter == V_ACTIVE ) next_v_counter = 9'd0;
        V_FRONT_STATE:  if( v_counter == V_FRONT  ) next_v_counter = 9'd0;
        V_PULSE_STATE:  if( v_counter == V_PULSE  ) next_v_counter = 9'd0;
        V_BACK_STATE:   if( v_counter == V_BACK   ) next_v_counter = 9'd0;
      endcase
    end
  end

  assign line_done = ( h_state == H_BACK_STATE ) & ( next_h_counter == 10'd0 );

  //----------------------------------------------------------------------
  // Sync signals
  //----------------------------------------------------------------------

  logic next_hs;
  logic next_vs;

  always_ff @( posedge clk_25M ) begin
    if( rst ) begin
      VGA_HS <= 1'b1;
      VGA_VS <= 1'b1;
    end else begin
      VGA_HS <= next_hs;
      VGA_VS <= next_vs;
    end
  end

  always_comb begin
    next_hs = VGA_HS;
    next_vs = VGA_VS;

    case( h_state )
      H_ACTIVE_STATE: next_hs = 1'b1;
      H_FRONT_STATE:  next_hs = 1'b1;
      H_PULSE_STATE:  next_hs = 1'b0;
      H_BACK_STATE:   next_hs = 1'b1;
    endcase

    case( v_state )
      V_ACTIVE_STATE: next_vs = 1'b1;
      V_FRONT_STATE:  next_vs = 1'b1;
      V_PULSE_STATE:  next_vs = 1'b0;
      V_BACK_STATE:   next_vs = 1'b1;
    endcase
  end

  //----------------------------------------------------------------------
  // Indicate the next pixel to get
  //----------------------------------------------------------------------

  assign read_hchar   = h_counter[9:3];
  assign read_hoffset = h_counter[2:0];
  assign read_vchar   = v_counter[8:3];
  assign read_voffset = v_counter[2:0];

  //----------------------------------------------------------------------
  // Remaining signals
  //----------------------------------------------------------------------

  assign VGA_R = pixel_red;
  assign VGA_G = pixel_green;
  assign VGA_B = pixel_blue;

endmodule

`endif // HW_VGADRIVER_V
