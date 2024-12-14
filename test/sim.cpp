// =======================================================================
// sim.cpp
// =======================================================================
// A basic simulator for running testbenches

// Include common routines
#include <stdio.h>
#include <verilated.h>

// Include DPI functions
#include "svdpi.h"

// Include model header (ex. Vtop.h)
#include "Vtop.h"

int main( int argc, char** argv )
{
  // Construct a VerilatedContext to hold simulation time, etc.
  VerilatedContext* const contextp = new VerilatedContext;

  // Verilator must compute traced signals
  contextp->traceEverOn( true );

  // Pass arguments so Verilated code can see them, e.g. $value$plusargs
  // This needs to be called before you create any model
  contextp->commandArgs( argc, argv );

  // Construct the Verilated model, from Vtop.h generated from Verilating
  // "top.v"
  Vtop* top = new Vtop{ contextp };

  // Simulate until $finish
  while ( !contextp->gotFinish() ) {
    // Increment time
    contextp->timeInc( 1 );
    // Evaluate model
    top->eval();
  }

  // Final model cleanup
  top->final();

  // Destroy model
  delete top;

  return 0;
}