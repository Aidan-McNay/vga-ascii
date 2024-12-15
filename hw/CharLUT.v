//========================================================================
// CharLUT.v
//========================================================================
// A lookup table to determine whether a given (visible) ASCII character
// should be displayed
//
// We assume 8x8 characters, and output whether the corresponding pixel
// should be colored or not
//
//       01234567  hidx
//      ,--------.
//   0  |  XX    |
//   1  | XXXX   |
//   2  |XX  XX  |
//   3  |XX  XX  |
//   4  |XXXXXX  |
//   5  |XX  XX  |
//   6  |XX  XX  |
//   7  |        |
// vidx `--------' 
//
// Note that currently, only characters 32 (space) - 126 (~) are supported

`ifndef HW_CHARLUT_V
`define HW_CHARLUT_V

module CharLUT (
  input  logic [7:0] ascii_char,
  input  logic [2:0] vidx,
  input  logic [2:0] hidx,
  output logic       lit
);

  //----------------------------------------------------------------------
  // Look-up table to determine character
  //----------------------------------------------------------------------
  // Each character is encoded in a row-major format
  //
  // Encodings sourced from https://github.com/dhepper/font8x8

  logic [63:0] char_pix;

  always_comb begin
    case( ascii_char )
      " ":     char_pix = { 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};   // U+0020 (space)
      "!":     char_pix = { 8'h18, 8'h3C, 8'h3C, 8'h18, 8'h18, 8'h00, 8'h18, 8'h00};   // U+0021 (!)
      "\"":    char_pix = { 8'h36, 8'h36, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};   // U+0022 (")
      "#":     char_pix = { 8'h36, 8'h36, 8'h7F, 8'h36, 8'h7F, 8'h36, 8'h36, 8'h00};   // U+0023 (#)
      "$":     char_pix = { 8'h0C, 8'h3E, 8'h03, 8'h1E, 8'h30, 8'h1F, 8'h0C, 8'h00};   // U+0024 ($)
      "%":     char_pix = { 8'h00, 8'h63, 8'h33, 8'h18, 8'h0C, 8'h66, 8'h63, 8'h00};   // U+0025 (%)
      "&":     char_pix = { 8'h1C, 8'h36, 8'h1C, 8'h6E, 8'h3B, 8'h33, 8'h6E, 8'h00};   // U+0026 (&)
      "'":     char_pix = { 8'h06, 8'h06, 8'h03, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};   // U+0027 (')
      "(":     char_pix = { 8'h18, 8'h0C, 8'h06, 8'h06, 8'h06, 8'h0C, 8'h18, 8'h00};   // U+0028 (()
      ")":     char_pix = { 8'h06, 8'h0C, 8'h18, 8'h18, 8'h18, 8'h0C, 8'h06, 8'h00};   // U+0029 ())
      "*":     char_pix = { 8'h00, 8'h66, 8'h3C, 8'hFF, 8'h3C, 8'h66, 8'h00, 8'h00};   // U+002A (*)
      "+":     char_pix = { 8'h00, 8'h0C, 8'h0C, 8'h3F, 8'h0C, 8'h0C, 8'h00, 8'h00};   // U+002B (+)
      ",":     char_pix = { 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h0C, 8'h0C, 8'h06};   // U+002C (,)
      "-":     char_pix = { 8'h00, 8'h00, 8'h00, 8'h3F, 8'h00, 8'h00, 8'h00, 8'h00};   // U+002D (-)
      ".":     char_pix = { 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h0C, 8'h0C, 8'h00};   // U+002E (.)
      "/":     char_pix = { 8'h60, 8'h30, 8'h18, 8'h0C, 8'h06, 8'h03, 8'h01, 8'h00};   // U+002F (/)
      "0":     char_pix = { 8'h3E, 8'h63, 8'h73, 8'h7B, 8'h6F, 8'h67, 8'h3E, 8'h00};   // U+0030 (0)
      "1":     char_pix = { 8'h0C, 8'h0E, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h3F, 8'h00};   // U+0031 (1)
      "2":     char_pix = { 8'h1E, 8'h33, 8'h30, 8'h1C, 8'h06, 8'h33, 8'h3F, 8'h00};   // U+0032 (2)
      "3":     char_pix = { 8'h1E, 8'h33, 8'h30, 8'h1C, 8'h30, 8'h33, 8'h1E, 8'h00};   // U+0033 (3)
      "4":     char_pix = { 8'h38, 8'h3C, 8'h36, 8'h33, 8'h7F, 8'h30, 8'h78, 8'h00};   // U+0034 (4)
      "5":     char_pix = { 8'h3F, 8'h03, 8'h1F, 8'h30, 8'h30, 8'h33, 8'h1E, 8'h00};   // U+0035 (5)
      "6":     char_pix = { 8'h1C, 8'h06, 8'h03, 8'h1F, 8'h33, 8'h33, 8'h1E, 8'h00};   // U+0036 (6)
      "7":     char_pix = { 8'h3F, 8'h33, 8'h30, 8'h18, 8'h0C, 8'h0C, 8'h0C, 8'h00};   // U+0037 (7)
      "8":     char_pix = { 8'h1E, 8'h33, 8'h33, 8'h1E, 8'h33, 8'h33, 8'h1E, 8'h00};   // U+0038 (8)
      "9":     char_pix = { 8'h1E, 8'h33, 8'h33, 8'h3E, 8'h30, 8'h18, 8'h0E, 8'h00};   // U+0039 (9)
      ":":     char_pix = { 8'h00, 8'h0C, 8'h0C, 8'h00, 8'h00, 8'h0C, 8'h0C, 8'h00};   // U+003A (:)
      ";":     char_pix = { 8'h00, 8'h0C, 8'h0C, 8'h00, 8'h00, 8'h0C, 8'h0C, 8'h06};   // U+003B (;)
      "<":     char_pix = { 8'h18, 8'h0C, 8'h06, 8'h03, 8'h06, 8'h0C, 8'h18, 8'h00};   // U+003C (<)
      "=":     char_pix = { 8'h00, 8'h00, 8'h3F, 8'h00, 8'h00, 8'h3F, 8'h00, 8'h00};   // U+003D (=)
      ">":     char_pix = { 8'h06, 8'h0C, 8'h18, 8'h30, 8'h18, 8'h0C, 8'h06, 8'h00};   // U+003E (>)
      "?":     char_pix = { 8'h1E, 8'h33, 8'h30, 8'h18, 8'h0C, 8'h00, 8'h0C, 8'h00};   // U+003F (?)
      "@":     char_pix = { 8'h3E, 8'h63, 8'h7B, 8'h7B, 8'h7B, 8'h03, 8'h1E, 8'h00};   // U+0040 (@)
      "A":     char_pix = { 8'h0C, 8'h1E, 8'h33, 8'h33, 8'h3F, 8'h33, 8'h33, 8'h00};   // U+0041 (A)
      "B":     char_pix = { 8'h3F, 8'h66, 8'h66, 8'h3E, 8'h66, 8'h66, 8'h3F, 8'h00};   // U+0042 (B)
      "C":     char_pix = { 8'h3C, 8'h66, 8'h03, 8'h03, 8'h03, 8'h66, 8'h3C, 8'h00};   // U+0043 (C)
      "D":     char_pix = { 8'h1F, 8'h36, 8'h66, 8'h66, 8'h66, 8'h36, 8'h1F, 8'h00};   // U+0044 (D)
      "E":     char_pix = { 8'h7F, 8'h46, 8'h16, 8'h1E, 8'h16, 8'h46, 8'h7F, 8'h00};   // U+0045 (E)
      "F":     char_pix = { 8'h7F, 8'h46, 8'h16, 8'h1E, 8'h16, 8'h06, 8'h0F, 8'h00};   // U+0046 (F)
      "G":     char_pix = { 8'h3C, 8'h66, 8'h03, 8'h03, 8'h73, 8'h66, 8'h7C, 8'h00};   // U+0047 (G)
      "H":     char_pix = { 8'h33, 8'h33, 8'h33, 8'h3F, 8'h33, 8'h33, 8'h33, 8'h00};   // U+0048 (H)
      "I":     char_pix = { 8'h1E, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h1E, 8'h00};   // U+0049 (I)
      "J":     char_pix = { 8'h78, 8'h30, 8'h30, 8'h30, 8'h33, 8'h33, 8'h1E, 8'h00};   // U+004A (J)
      "K":     char_pix = { 8'h67, 8'h66, 8'h36, 8'h1E, 8'h36, 8'h66, 8'h67, 8'h00};   // U+004B (K)
      "L":     char_pix = { 8'h0F, 8'h06, 8'h06, 8'h06, 8'h46, 8'h66, 8'h7F, 8'h00};   // U+004C (L)
      "M":     char_pix = { 8'h63, 8'h77, 8'h7F, 8'h7F, 8'h6B, 8'h63, 8'h63, 8'h00};   // U+004D (M)
      "N":     char_pix = { 8'h63, 8'h67, 8'h6F, 8'h7B, 8'h73, 8'h63, 8'h63, 8'h00};   // U+004E (N)
      "O":     char_pix = { 8'h1C, 8'h36, 8'h63, 8'h63, 8'h63, 8'h36, 8'h1C, 8'h00};   // U+004F (O)
      "P":     char_pix = { 8'h3F, 8'h66, 8'h66, 8'h3E, 8'h06, 8'h06, 8'h0F, 8'h00};   // U+0050 (P)
      "Q":     char_pix = { 8'h1E, 8'h33, 8'h33, 8'h33, 8'h3B, 8'h1E, 8'h38, 8'h00};   // U+0051 (Q)
      "R":     char_pix = { 8'h3F, 8'h66, 8'h66, 8'h3E, 8'h36, 8'h66, 8'h67, 8'h00};   // U+0052 (R)
      "S":     char_pix = { 8'h1E, 8'h33, 8'h07, 8'h0E, 8'h38, 8'h33, 8'h1E, 8'h00};   // U+0053 (S)
      "T":     char_pix = { 8'h3F, 8'h2D, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h1E, 8'h00};   // U+0054 (T)
      "U":     char_pix = { 8'h33, 8'h33, 8'h33, 8'h33, 8'h33, 8'h33, 8'h3F, 8'h00};   // U+0055 (U)
      "V":     char_pix = { 8'h33, 8'h33, 8'h33, 8'h33, 8'h33, 8'h1E, 8'h0C, 8'h00};   // U+0056 (V)
      "W":     char_pix = { 8'h63, 8'h63, 8'h63, 8'h6B, 8'h7F, 8'h77, 8'h63, 8'h00};   // U+0057 (W)
      "X":     char_pix = { 8'h63, 8'h63, 8'h36, 8'h1C, 8'h1C, 8'h36, 8'h63, 8'h00};   // U+0058 (X)
      "Y":     char_pix = { 8'h33, 8'h33, 8'h33, 8'h1E, 8'h0C, 8'h0C, 8'h1E, 8'h00};   // U+0059 (Y)
      "Z":     char_pix = { 8'h7F, 8'h63, 8'h31, 8'h18, 8'h4C, 8'h66, 8'h7F, 8'h00};   // U+005A (Z)
      "[":     char_pix = { 8'h1E, 8'h06, 8'h06, 8'h06, 8'h06, 8'h06, 8'h1E, 8'h00};   // U+005B ([)
      "\\":    char_pix = { 8'h03, 8'h06, 8'h0C, 8'h18, 8'h30, 8'h60, 8'h40, 8'h00};   // U+005C (\)
      "]":     char_pix = { 8'h1E, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h1E, 8'h00};   // U+005D (])
      "^":     char_pix = { 8'h08, 8'h1C, 8'h36, 8'h63, 8'h00, 8'h00, 8'h00, 8'h00};   // U+005E (^)
      "_":     char_pix = { 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hFF};   // U+005F (_)
      "`":     char_pix = { 8'h0C, 8'h0C, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};   // U+0060 (`)
      "a":     char_pix = { 8'h00, 8'h00, 8'h1E, 8'h30, 8'h3E, 8'h33, 8'h6E, 8'h00};   // U+0061 (a)
      "b":     char_pix = { 8'h07, 8'h06, 8'h06, 8'h3E, 8'h66, 8'h66, 8'h3B, 8'h00};   // U+0062 (b)
      "c":     char_pix = { 8'h00, 8'h00, 8'h1E, 8'h33, 8'h03, 8'h33, 8'h1E, 8'h00};   // U+0063 (c)
      "d":     char_pix = { 8'h38, 8'h30, 8'h30, 8'h3e, 8'h33, 8'h33, 8'h6E, 8'h00};   // U+0064 (d)
      "e":     char_pix = { 8'h00, 8'h00, 8'h1E, 8'h33, 8'h3f, 8'h03, 8'h1E, 8'h00};   // U+0065 (e)
      "f":     char_pix = { 8'h1C, 8'h36, 8'h06, 8'h0f, 8'h06, 8'h06, 8'h0F, 8'h00};   // U+0066 (f)
      "g":     char_pix = { 8'h00, 8'h00, 8'h6E, 8'h33, 8'h33, 8'h3E, 8'h30, 8'h1F};   // U+0067 (g)
      "h":     char_pix = { 8'h07, 8'h06, 8'h36, 8'h6E, 8'h66, 8'h66, 8'h67, 8'h00};   // U+0068 (h)
      "i":     char_pix = { 8'h0C, 8'h00, 8'h0E, 8'h0C, 8'h0C, 8'h0C, 8'h1E, 8'h00};   // U+0069 (i)
      "j":     char_pix = { 8'h30, 8'h00, 8'h30, 8'h30, 8'h30, 8'h33, 8'h33, 8'h1E};   // U+006A (j)
      "k":     char_pix = { 8'h07, 8'h06, 8'h66, 8'h36, 8'h1E, 8'h36, 8'h67, 8'h00};   // U+006B (k)
      "l":     char_pix = { 8'h0E, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h1E, 8'h00};   // U+006C (l)
      "m":     char_pix = { 8'h00, 8'h00, 8'h33, 8'h7F, 8'h7F, 8'h6B, 8'h63, 8'h00};   // U+006D (m)
      "n":     char_pix = { 8'h00, 8'h00, 8'h1F, 8'h33, 8'h33, 8'h33, 8'h33, 8'h00};   // U+006E (n)
      "o":     char_pix = { 8'h00, 8'h00, 8'h1E, 8'h33, 8'h33, 8'h33, 8'h1E, 8'h00};   // U+006F (o)
      "p":     char_pix = { 8'h00, 8'h00, 8'h3B, 8'h66, 8'h66, 8'h3E, 8'h06, 8'h0F};   // U+0070 (p)
      "q":     char_pix = { 8'h00, 8'h00, 8'h6E, 8'h33, 8'h33, 8'h3E, 8'h30, 8'h78};   // U+0071 (q)
      "r":     char_pix = { 8'h00, 8'h00, 8'h3B, 8'h6E, 8'h66, 8'h06, 8'h0F, 8'h00};   // U+0072 (r)
      "s":     char_pix = { 8'h00, 8'h00, 8'h3E, 8'h03, 8'h1E, 8'h30, 8'h1F, 8'h00};   // U+0073 (s)
      "t":     char_pix = { 8'h08, 8'h0C, 8'h3E, 8'h0C, 8'h0C, 8'h2C, 8'h18, 8'h00};   // U+0074 (t)
      "u":     char_pix = { 8'h00, 8'h00, 8'h33, 8'h33, 8'h33, 8'h33, 8'h6E, 8'h00};   // U+0075 (u)
      "v":     char_pix = { 8'h00, 8'h00, 8'h33, 8'h33, 8'h33, 8'h1E, 8'h0C, 8'h00};   // U+0076 (v)
      "w":     char_pix = { 8'h00, 8'h00, 8'h63, 8'h6B, 8'h7F, 8'h7F, 8'h36, 8'h00};   // U+0077 (w)
      "x":     char_pix = { 8'h00, 8'h00, 8'h63, 8'h36, 8'h1C, 8'h36, 8'h63, 8'h00};   // U+0078 (x)
      "y":     char_pix = { 8'h00, 8'h00, 8'h33, 8'h33, 8'h33, 8'h3E, 8'h30, 8'h1F};   // U+0079 (y)
      "z":     char_pix = { 8'h00, 8'h00, 8'h3F, 8'h19, 8'h0C, 8'h26, 8'h3F, 8'h00};   // U+007A (z)
      "{":     char_pix = { 8'h38, 8'h0C, 8'h0C, 8'h07, 8'h0C, 8'h0C, 8'h38, 8'h00};   // U+007B ({)
      "|":     char_pix = { 8'h18, 8'h18, 8'h18, 8'h00, 8'h18, 8'h18, 8'h18, 8'h00};   // U+007C (|)
      "}":     char_pix = { 8'h07, 8'h0C, 8'h0C, 8'h38, 8'h0C, 8'h0C, 8'h07, 8'h00};   // U+007D (})
      "~":     char_pix = { 8'h6E, 8'h3B, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};   // U+007E (~)
      default: char_pix = { 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
    endcase
  end

  //----------------------------------------------------------------------
  // Assign output based on appropriate pixel value
  //----------------------------------------------------------------------

  logic [7:0] char_pix_row;

  always_comb begin
    case( vidx )
      'h0:     char_pix_row = char_pix[63:56];
      'h1:     char_pix_row = char_pix[55:48];
      'h2:     char_pix_row = char_pix[47:40];
      'h3:     char_pix_row = char_pix[39:32];
      'h4:     char_pix_row = char_pix[31:24];
      'h5:     char_pix_row = char_pix[23:16];
      'h6:     char_pix_row = char_pix[15: 8];
      'h7:     char_pix_row = char_pix[ 7: 0];
      default: char_pix_row = 'h0;
    endcase
  end

  assign lit = char_pix_row[hidx];

endmodule

`endif // HW_CHARLUT_V
