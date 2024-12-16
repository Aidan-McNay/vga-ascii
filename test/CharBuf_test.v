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
  logic       dut_out_of_bounds;

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
    .read_lit         (dut_read_lit),
    .out_of_bounds    (dut_out_of_bounds)
  );

  //----------------------------------------------------------------------
  // Instantiate a CharLUT to get the expected answer
  //----------------------------------------------------------------------

  logic [7:0] oracle_ascii_char;
  logic [2:0] oracle_vidx;
  logic [2:0] oracle_hidx;
  logic       oracle_lit;

  CharLUT oracle (
    .ascii_char (oracle_ascii_char),
    .vidx       (oracle_vidx),
    .hidx       (oracle_hidx),
    .lit        (oracle_lit)
  );

  //----------------------------------------------------------------------
  // write_ascii
  //----------------------------------------------------------------------

  initial begin
    dut_ascii_val = 1'b0;
  end

  task write_ascii
  (
    input logic [7:0] ascii_char
  );
    dut_ascii     = ascii_char;
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
    input logic [7:0] ascii_char,
    input logic [6:0] hchar,
    input logic [5:0] vchar,
    input logic       cursor,
    input logic       in_bounds
  );
    if ( !t.failed ) begin

      dut_read_hchar    = hchar;
      dut_read_vchar    = vchar;
      oracle_ascii_char = ascii_char;

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
                      ascii_char, dut_read_vchar, dut_read_voffset, 
                      dut_read_hchar, dut_read_hoffset, dut_read_lit );
          end
          
          if( !in_bounds )
            exp_lit = 1'b0;
          else if( cursor & ( v == 7 ) & ( h != 7 ) )
            exp_lit = 1'b1;
          else
            exp_lit = oracle_lit;
          
          `CHECK_EQ( dut_read_lit,      exp_lit );
          `CHECK_EQ( dut_out_of_bounds, !in_bounds );
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

    check( "A", 0, 6'(p_num_rows - 1), n, y );
    check( " ", 1, 6'(p_num_rows - 1), y, y );

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

    check( "2", 0, 6'(p_num_rows - 1), n, y );
    check( "3", 1, 6'(p_num_rows - 1), n, y );
    check( "0", 2, 6'(p_num_rows - 1), n, y );
    check( "0", 3, 6'(p_num_rows - 1), n, y );
    check( " ", 4, 6'(p_num_rows - 1), y, y );

  endtask

  //----------------------------------------------------------------------
  // test_case_3_multi_line
  //----------------------------------------------------------------------

  task test_case_3_multi_line();
    t.test_case_begin( "test_case_3_multi_line" );

    for( int i = 0; i < p_num_cols; i = i + 1 ) begin
      write_ascii( "1" );
    end
    write_ascii( "2" );

    for( int i = 0; i < p_num_cols; i = i + 1 ) begin
      check( "1", 7'(i), 6'(p_num_rows - 2), n, y );
    end
    check( "2", 0, 6'(p_num_rows - 1), n, y );
    check( " ", 1, 6'(p_num_rows - 1), y, y );

  endtask

  //----------------------------------------------------------------------
  // test_case_4_overflow
  //----------------------------------------------------------------------

  task test_case_4_overflow();
    t.test_case_begin( "test_case_4_overflow" );

    for( int r = 0; r < p_num_rows; r = r + 1 ) begin
      for( int c = 0; c < p_num_cols; c = c + 1 ) begin
        write_ascii( 8'(r + 65) );
      end
    end

    for( int r = 0; r < p_num_rows; r = r + 1 ) begin
      for( int c = 0; c < p_num_cols; c = c + 1 ) begin
        if( r == p_num_rows - 1 )
          check( " ", 7'(c), 6'(r), 1'( c == 0 ), y );
        else
          check( 8'(r + 66), 7'(c), 6'(r), n, y );
      end
    end

  endtask

  //----------------------------------------------------------------------
  // test_case_5_delete
  //----------------------------------------------------------------------

  localparam DEL = 8'h7F;

  task test_case_5_delete();
    t.test_case_begin( "test_case_5_delete" );

    write_ascii( "A" );
    write_ascii( "B" );
    write_ascii( "C" );
    write_ascii( DEL );
    write_ascii( DEL );
    write_ascii( "D" );
    write_ascii( "E" );

    check( "A", 0, 6'(p_num_rows - 1), n, y );
    check( "D", 1, 6'(p_num_rows - 1), n, y );
    check( "E", 2, 6'(p_num_rows - 1), n, y );
    check( " ", 3, 6'(p_num_rows - 1), y, y );

  endtask

  //----------------------------------------------------------------------
  // test_case_6_multi_line_delete
  //----------------------------------------------------------------------

  task test_case_6_multi_line_delete();
    t.test_case_begin( "test_case_6_multi_line_delete" );

    for( int i = 0; i < p_num_cols; i = i + 1 ) begin
      write_ascii( "P" );
    end
    write_ascii( "2" );
    write_ascii( DEL );
    write_ascii( DEL );
    write_ascii( DEL );

    for( int i = 0; i < p_num_cols; i = i + 1 ) begin
      check( "P", 7'(i), 6'(p_num_rows - 2), n, y );
    end
    check( " ", 0, 6'(p_num_rows - 1), y, y );

  endtask

  //----------------------------------------------------------------------
  // test_case_7_newline
  //----------------------------------------------------------------------

  localparam LF = 8'h0A;

  task test_case_7_newline();
    t.test_case_begin( "test_case_7_newline" );

    write_ascii( "E" );
    write_ascii( LF );
    write_ascii( "C" );
    write_ascii( LF );
    write_ascii( "E" );
    write_ascii( LF );

    check( "E", 0, 6'(p_num_rows - 4), n, y );
    check( "C", 0, 6'(p_num_rows - 3), n, y );
    check( "E", 0, 6'(p_num_rows - 2), n, y );
    check( " ", 0, 6'(p_num_rows - 1), y, y );

  endtask

  //----------------------------------------------------------------------
  // test_case_8_clear
  //----------------------------------------------------------------------

  localparam ESC = 8'h1B;

  task test_case_8_clear();
    t.test_case_begin( "test_case_8_clear" );

    write_ascii( "T" );
    write_ascii( "E" );
    write_ascii( LF );
    write_ascii( "S" );
    write_ascii( "T" );
    write_ascii( LF );
    write_ascii( "8" );
    write_ascii( LF );
    write_ascii( ESC );

    check( " ", 0, 6'(p_num_rows - 4), n, y );
    check( " ", 1, 6'(p_num_rows - 4), n, y );

    check( " ", 0, 6'(p_num_rows - 3), n, y );
    check( " ", 1, 6'(p_num_rows - 3), n, y );

    check( " ", 0, 6'(p_num_rows - 2), n, y );

    check( " ", 0, 6'(p_num_rows - 1), y, y );

  endtask

  //----------------------------------------------------------------------
  // test_case_9_out_of_bounds
  //----------------------------------------------------------------------

  task test_case_9_out_of_bounds();
    t.test_case_begin( "test_case_9_out_of_bounds" );

    for( int r = p_num_rows; r < p_num_rows + 2; r = r + 1 ) begin
      for( int c = p_num_cols; c < p_num_cols + 2; c = c + 1 ) begin
        check( " ", 7'(c), 6'(r), n, n );
      end
    end

  endtask

  //----------------------------------------------------------------------
  // print_buf
  //----------------------------------------------------------------------
  // A task to print the entire character buffer, for visual debugging

  // verilator lint_off WIDTHTRUNC

  task print_buf();
    for( int r = 0; r < p_num_rows * 8; r = r + 1 ) begin
      for( int c = 0; c < p_num_cols * 8; c = c + 1 ) begin
        { dut_read_hchar, dut_read_hoffset } = c;
        { dut_read_vchar, dut_read_voffset } = r;
        #10;
        if( dut_read_lit )
          $write(".");
        else
          $write(" ");
      end
      $write("\n");
    end
  endtask

  // verilator lint_on WIDTHTRUNC

  //----------------------------------------------------------------------
  // run_test_suite
  //----------------------------------------------------------------------

  task run_test_suite();
    t.test_suite_begin( suite_name );

    if ((t.n <= 0) || (t.n == 1)) test_case_1_basic();
    if ((t.n <= 0) || (t.n == 2)) test_case_2_multi_char();
    if ((t.n <= 0) || (t.n == 3)) test_case_3_multi_line();
    if ((t.n <= 0) || (t.n == 4)) test_case_4_overflow();
    if ((t.n <= 0) || (t.n == 5)) test_case_5_delete();
    if ((t.n <= 0) || (t.n == 6)) test_case_6_multi_line_delete();
    if ((t.n <= 0) || (t.n == 7)) test_case_7_newline();
    if ((t.n <= 0) || (t.n == 8)) test_case_8_clear();
    if ((t.n <= 0) || (t.n == 9)) test_case_9_out_of_bounds();

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

  CharBufTestSuite #(1,  8,  8) suite_1();
  CharBufTestSuite #(2, 16, 16) suite_2();
  CharBufTestSuite #(3,  8, 64) suite_3();
  CharBufTestSuite #(4, 32, 32) suite_4();

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
    if ((s <= 0) || (s == 4)) suite_4.run_test_suite();

    t.test_bench_end();
  end
endmodule
