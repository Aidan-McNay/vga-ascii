//========================================================================
// CharLUT_test.v
//========================================================================
// A testbench for our character look-up table

`include "hw/CharLUT.v"
`include "test/utils.v"

module Top();

  //----------------------------------------------------------------------
  // Setup
  //----------------------------------------------------------------------

  // verilator lint_off UNUSED
  logic clk;
  logic rst;
  // verilator lint_on UNUSED

  TestUtils t( .* );

  //----------------------------------------------------------------------
  // Instantiate design under test
  //----------------------------------------------------------------------

  logic [7:0] dut_ascii_char;
  logic [3:0] dut_vidx;
  logic [2:0] dut_hidx;
  logic       dut_lit;

  CharLUT dut (
    .ascii_char (dut_ascii_char),
    .vidx       (dut_vidx),
    .hidx       (dut_hidx),
    .lit        (dut_lit)
  );

  //----------------------------------------------------------------------
  // check
  //----------------------------------------------------------------------
  // All tasks start at #1 after the rising edge of the clock. So we
  // write the inputs #1 after the rising edge, and check the outputs #1
  // before the next rising edge.

  task check
  (
    input logic [7:0] ascii_char,
    input logic [3:0] vidx,
    input logic [2:0] hidx,
    input logic       lit
  );
    if ( !t.failed ) begin

      dut_ascii_char = ascii_char;
      dut_vidx       = vidx;
      dut_hidx       = hidx;

      #8;

      if ( t.n != 0 ) begin
        $display( "%3d: %s (%d,%d) > %b", t.cycles,
                  dut_ascii_char, dut_vidx, dut_hidx, dut_lit );
      end

      `CHECK_EQ( dut_lit, lit );

      #2;

    end
  endtask

  //----------------------------------------------------------------------
  // test_case_1_basic
  //----------------------------------------------------------------------
  // Just test the first row of "A"

  task test_case_1_basic();
    t.test_case_begin( "test_case_1_basic" );

    //     char vidx hidx lit
    check( "A", 5,   0,   0 );
    check( "A", 5,   1,   0 );
    check( "A", 5,   2,   1 );
    check( "A", 5,   3,   0 );
    check( "A", 5,   4,   1 );
    check( "A", 5,   5,   0 );
    check( "A", 5,   6,   0 );
    check( "A", 5,   7,   0 );

  endtask

  //----------------------------------------------------------------------
  // test_case_2_full_char
  //----------------------------------------------------------------------
  // Check the full character of "q"

  task check_row(
    input logic [7:0] ascii_char,
    input logic [3:0] row, 
    input logic [7:0] lits
  );
    for( logic [3:0] col = 0; col < 4'd8; col = col + 4'd1 ) begin
      check( ascii_char, row, col[2:0], lits[col[2:0]] );
    end
  endtask

  task test_case_2_full_char();
    t.test_case_begin( "test_case_2_full_char" );

    check_row( "q",  0, 8'b00000000 );
    check_row( "q",  1, 8'b00000000 );
    check_row( "q",  2, 8'b00000000 );
    check_row( "q",  3, 8'b00000000 );
    check_row( "q",  4, 8'b00000000 );
    check_row( "q",  5, 8'b00000000 );
    check_row( "q",  6, 8'b01111100 );
    check_row( "q",  7, 8'b01000010 );
    check_row( "q",  8, 8'b01000010 );
    check_row( "q",  9, 8'b01000010 );
    check_row( "q", 10, 8'b01000010 );
    check_row( "q", 11, 8'b01000010 );
    check_row( "q", 12, 8'b01111100 );
    check_row( "q", 13, 8'b01000000 );
    check_row( "q", 14, 8'b01000000 );
    check_row( "q", 15, 8'b00000000 );

  endtask

  //----------------------------------------------------------------------
  // main
  //----------------------------------------------------------------------

  initial begin
    t.test_bench_begin( `__FILE__ );

    if ((t.n <= 0) || (t.n == 1)) test_case_1_basic();
    if ((t.n <= 0) || (t.n == 2)) test_case_2_full_char();

    t.test_bench_end();
  end

endmodule
