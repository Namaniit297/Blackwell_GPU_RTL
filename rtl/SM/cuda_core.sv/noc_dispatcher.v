module noc_dispatcher #(
  parameter int W = 32,
  parameter int NUM_THREADS = 32
)(
  input  logic clk,
  input  logic rst,

  // Inputs from issue unit
  input  logic [NUM_THREADS-1:0]       thread_valid,
  input  logic [NUM_THREADS-1:0][5:0]  thread_opcode,
  input  logic [NUM_THREADS-1:0]       thread_is_fp,
  input  logic [NUM_THREADS-1:0][W-1:0] thread_op1,
  input  logic [NUM_THREADS-1:0][W-1:0] thread_op2,

  // From cores
  input  logic [NUM_THREADS-1:0]       core_ready,

  // Outputs to cores
  output logic [NUM_THREADS-1:0]       dispatch_valid,
  output logic [NUM_THREADS-1:0][5:0]  dispatch_opcode,
  output logic [NUM_THREADS-1:0]       dispatch_is_fp,
  output logic [NUM_THREADS-1:0][W-1:0] dispatch_op1,
  output logic [NUM_THREADS-1:0][W-1:0] dispatch_op2
);

  always_comb begin
    for (int i = 0; i < NUM_THREADS; i++) begin
      dispatch_valid[i]     = core_ready[i] && thread_valid[i];
      dispatch_opcode[i]    = thread_opcode[i];
      dispatch_is_fp[i]     = thread_is_fp[i];
      dispatch_op1[i]       = thread_op1[i];
      dispatch_op2[i]       = thread_op2[i];
    end
  end

endmodule
