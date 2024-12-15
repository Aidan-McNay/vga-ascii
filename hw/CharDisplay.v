//========================================================================
// CharDisplay.v
//========================================================================
// The top-level character display
//
// All color parameters are RGB

`ifndef HW_CHARDISPLAY
`define HW_CHARDISPLAY

`include "CharBuf.v"
`include "VGADriver.v"

module CharDisplay #(
  parameter logic [11:0] p_text_color   = 12'hFFF,
  parameter logic [11:0] p_bg_color     = 12'h000,
  parameter logic [11:0] p_screen_color = 12'hFFF,
  parameter p_num_rows                  = 32,
  parameter p_num_cols                  = 32
) (
  input  logic clk_25M,
  input  logic rst,

  //----------------------------------------------------------------------
  // ASCII Interface
  //----------------------------------------------------------------------

  input  logic [7:0] ascii,
  input  logic       ascii_val,

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
  // Instantiate helper modules
  //----------------------------------------------------------------------

  logic [6:0] read_hchar;
  logic [5:0] read_vchar;
  logic [2:0] read_hoffset;
  logic [2:0] read_voffset;
  logic       read_lit;
  logic       out_of_bounds;

  logic [3:0] pixel_red;
  logic [3:0] pixel_green;
  logic [3:0] pixel_blue;

  CharBuf #(
    .p_num_rows (p_num_rows),
    .p_num_cols (p_num_cols)
  ) char_buf (
    .clk (clk_25M),
    .*
  );

  VGADriver vga_driver (
    .*
  );
  
  //----------------------------------------------------------------------
  // Perform color translation
  //----------------------------------------------------------------------

  always_comb begin
    if( out_of_bounds ) begin
      pixel_red   = p_screen_color[11:8];
      pixel_green = p_screen_color[7:4];
      pixel_blue  = p_screen_color[3:0];
    end else if( read_lit ) begin
      pixel_red   = p_text_color[11:8];
      pixel_green = p_text_color[7:4];
      pixel_blue  = p_text_color[3:0];
    end else begin
      pixel_red   = p_bg_color[11:8];
      pixel_green = p_bg_color[7:4];
      pixel_blue  = p_bg_color[3:0];
    end
  end

endmodule

`endif // HW_CHARDISPLAY
