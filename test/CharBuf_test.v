//========================================================================
// CharBuf_test.v
//========================================================================
// A testbench for our character buffer

`include "hw/CharBuf.v"
`include "hw/CharLUT.v"
`include "test/utils.v"

//========================================================================
// CharBufTestSuite
//========================================================================
// A test suite for a particular parametrization of the character buffer

module CharBufTestSuite #(
  parameter p_suite_num = 0,
  parameter p_num_rows  = 32,
  parameter p_num_cols  = 32
);

  string suite_name = $sformatf("%0d: CharBufTestSuite_%0d_%0d", p_suite_num,
                                p_num_rows, p_num_cols);

  //----------------------------------------------------------------------
  // Setup
  //----------------------------------------------------------------------

  logic clk;
  logic rst;

  TestUtils t( .* );

  //----------------------------------------------------------------------
  // Instantiate design under test
  //----------------------------------------------------------------------

  logic [7:0] dut_ascii;
  logic       dut_ascii_val;
  logic [6:0] dut_read_hchar;
  logic [5:0] dut_read_vchar;
  logic [2:0] dut_read_hoffset;
  logic [2:0] dut_read_voffset;
  logic       dut_read_lit;

  CharBuf #(
    .p_num_rows (p_num_rows),
    .p_num_cols (p_num_cols)
  ) dut (
    .clk              (clk),
    .rst              (rst),
    .ascii            (dut_ascii),
    .ascii_val        (dut_ascii_val),
    .read_hchar       (dut_read_hchar),
    .read_vchar       (dut_read_vchar),
    .read_hoffset     (dut_read_hoffset),
    .read_voffset     (dut_read_voffset),
    .read_lit         (dut_read_lit)
  );

  //----------------------------------------------------------------------
  // Instantiate a CharLUT to get the expected answer
  //----------------------------------------------------------------------

  logic [7:0] oracle_char;
  logic [2:0] oracle_vidx;
  logic [2:0] oracle_hidx;
  logic       oracle_lit;

  CharLUT oracle (
    .char (oracle_char),
    .vidx (oracle_vidx),
    .hidx (oracle_hidx),
    .lit  (oracle_lit)
  );

  //----------------------------------------------------------------------
  // write_ascii
  //----------------------------------------------------------------------

  initial begin
    dut_ascii_val = 1'b0;
  end

  task write_ascii
  (
    input logic [7:0] char
  );
    dut_ascii = char;
    dut_ascii_val = 1'b1;

    #10;

    dut_ascii_val = 1'b0;
  endtask

  //----------------------------------------------------------------------
  // check
  //----------------------------------------------------------------------
  // All tasks start at #1 after the rising edge of the clock.

  logic [2:0] hoffset;
  logic [2:0] voffset;
  logic       exp_lit;

  task check
  (
    input logic [7:0] char,
    input logic [6:0] hchar,
    input logic [5:0] vchar,
    input logic       cursor
  );
    if ( !t.failed ) begin

      dut_read_hchar = hchar;
      dut_read_vchar = vchar;
      oracle_char    = char;

      for( int h = 0; h < 8; h = h + 1 ) begin
        for( int v = 0; v < 8; v = v + 1 ) begin
          hoffset = 3'(h);
          voffset = 3'(v);

          dut_read_hoffset = hoffset;
          dut_read_voffset = voffset;
          oracle_hidx      = hoffset;
          oracle_vidx      = voffset;

          #10;

          if ( t.n != 0 ) begin
            $display( "%3d: %s (%d.%d,%d.%d) > %b", t.cycles,
                      char, dut_read_vchar, dut_read_voffset, 
                      dut_read_hchar, dut_read_hoffset, dut_read_lit );
          end
          
          if( cursor & ( v == 7 ) )
            exp_lit = 1'b1;
          else
            exp_lit = oracle_lit;
          
          `CHECK_EQ( dut_read_lit, exp_lit );
        end
      end
    end
  endtask

  //----------------------------------------------------------------------
  // test_case_1_basic
  //----------------------------------------------------------------------

  localparam y = 1'b1;
  localparam n = 1'b0;

  task test_case_1_basic();
    t.test_case_begin( "test_case_1_basic" );

    write_ascii( "A" );

    check( "A", 0, 6'(p_num_rows - 1), n );
    check( " ", 1, 6'(p_num_rows - 1), y );

  endtask

  //----------------------------------------------------------------------
  // test_case_2_multi_char
  //----------------------------------------------------------------------

  task test_case_2_multi_char();
    t.test_case_begin( "test_case_2_multi_char" );

    write_ascii( "2" );
    write_ascii( "3" );
    write_ascii( "0" );
    write_ascii( "0" );

    check( "2", 0, 6'(p_num_rows - 1), n );
    check( "3", 1, 6'(p_num_rows - 1), n );
    check( "0", 2, 6'(p_num_rows - 1), n );
    check( "0", 3, 6'(p_num_rows - 1), n );
    check( " ", 4, 6'(p_num_rows - 1), y );

  endtask

  //----------------------------------------------------------------------
  // run_test_suite
  //----------------------------------------------------------------------

  task run_test_suite();
    t.test_suite_begin( suite_name );

    if ((t.n <= 0) || (t.n == 1)) test_case_1_basic();
    if ((t.n <= 0) || (t.n == 1)) test_case_2_multi_char();

  endtask

endmodule

//========================================================================
// Top-level module
//========================================================================

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
  // Parameterized Test Suites
  //----------------------------------------------------------------------

  CharBufTestSuite #(1)         suite_1();
  CharBufTestSuite #(2, 16, 16) suite_2();
  CharBufTestSuite #(3,  8, 64) suite_3();

  //----------------------------------------------------------------------
  // main
  //----------------------------------------------------------------------

  int s;

  initial begin
    t.test_bench_begin( `__FILE__ );
    s = t.get_test_suite();

    if ((s <= 0) || (s == 1)) suite_1.run_test_suite();
    if ((s <= 0) || (s == 2)) suite_2.run_test_suite();
    if ((s <= 0) || (s == 3)) suite_3.run_test_suite();

    t.test_bench_end();
  end
endmodule
