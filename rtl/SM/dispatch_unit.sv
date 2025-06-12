
//==============================================================================
// AGNI V1.0 – NoC Dispatcher with Core Readiness
//------------------------------------------------------------------------------
// Author       : Naman Kalra
// Description  : Dispatches to cores only if each thread is both active & ready
//==============================================================================

module noc_dispatcher_with_ready #(
  parameter int NUM_THREADS = 32,
  parameter int REG_WIDTH   = 32
)(
  input  logic clk,
  input  logic rst,

  // Warp-wide control
  input  logic                          warp_valid,
  input  logic [5:0]                    opcode,
  input  logic                          is_fp,        // ALU or FPU

  // Per-thread status
  input  logic [NUM_THREADS-1:0]        thread_active, // From scheduler
  input  logic [NUM_THREADS-1:0]        core_ready,    // From each CUDA core

  // Operands
  input  logic [NUM_THREADS*REG_WIDTH-1:0] op1_bus,
  input  logic [NUM_THREADS*REG_WIDTH-1:0] op2_bus,

  // Outputs to CUDA cores
  output logic [NUM_THREADS-1:0]        core_valid,
  output logic [NUM_THREADS*REG_WIDTH-1:0] core_op1,
  output logic [NUM_THREADS*REG_WIDTH-1:0] core_op2,
  output logic [NUM_THREADS*6-1:0]      core_opcode,
  output logic [NUM_THREADS-1:0]        core_is_fp
);

  genvar i;
  generate
    for (i = 0; i < NUM_THREADS; i++) begin
      wire is_ready = warp_valid & thread_active[i] & core_ready[i];

      assign core_valid[i] = is_ready;
      assign core_op1[i*REG_WIDTH +: REG_WIDTH] = is_ready ? op1_bus[i*REG_WIDTH +: REG_WIDTH] : '0;
      assign core_op2[i*REG_WIDTH +: REG_WIDTH] = is_ready ? op2_bus[i*REG_WIDTH +: REG_WIDTH] : '0;
      assign core_opcode[i*6 +: 6] = is_ready ? opcode : 6'b0;
      assign core_is_fp[i] = is_ready ? is_fp : 1'b0;
    end
  endgenerate

endmodule
