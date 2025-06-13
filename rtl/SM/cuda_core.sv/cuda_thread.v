//==============================================================================
// AGNI V1.0 – cuda_thread.sv
//------------------------------------------------------------------------------
// Author       : Naman Kalra
// Description  : Executes one PTX instruction using ALU or FPU.
//                Includes internal operand buffer.
//==============================================================================

module cuda_thread #(
  parameter int W = 32
)(
  input  logic         clk,
  input  logic         rst,

  // Instruction + operand input from NoC dispatcher
  input  logic         valid_in,        // Instruction valid
  input  logic [5:0]   opcode_in,       // PTX opcode
  input  logic         is_fp_in,        // ALU=0, FPU=1
  input  logic [W-1:0] op1_in,
  input  logic [W-1:0] op2_in,

  // Outputs to writeback unit
  output logic [W-1:0] result_out,
  output logic         done_out,
  output logic         ready_out
);

  //--------------------------------------------------------------------------
  // Internal Buffer (1-instruction latch)
  //--------------------------------------------------------------------------

  logic         buf_valid;
  logic [5:0]   buf_opcode;
  logic         buf_is_fp;
  logic [W-1:0] buf_op1, buf_op2;
  logic         consume;

  // Instruction latch
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      buf_valid <= 1'b0;
    end else if (valid_in && ~buf_valid) begin
      buf_valid   <= 1'b1;
      buf_opcode  <= opcode_in;
      buf_is_fp   <= is_fp_in;
      buf_op1     <= op1_in;
      buf_op2     <= op2_in;
    end else if (consume) begin
      buf_valid <= 1'b0;
    end
  end

  //--------------------------------------------------------------------------
  // Execution Units (ALU / FPU)
  //--------------------------------------------------------------------------

  logic [W-1:0] alu_result, fpu_result;
  logic         alu_done, fpu_done;

  // ALU instantiation
  alu alu_inst (
    .clk(clk),
    .rst(rst),
    .valid(buf_valid && ~buf_is_fp),
    .opcode(buf_opcode),
    .op1(buf_op1),
    .op2(buf_op2),
    .result(alu_result),
    .done(alu_done)
  );

  // FPU instantiation
  fpu_unit fpu_inst (
    .clk(clk),
    .rst(rst),
    .valid(buf_valid && buf_is_fp),
    .opcode(buf_opcode),
    .a(buf_op1),
    .b(buf_op2),
    .result(fpu_result),
    .done(fpu_done)
  );

  //--------------------------------------------------------------------------
  // Result MUX + Handshake
  //--------------------------------------------------------------------------

  assign result_out = buf_is_fp ? fpu_result : alu_result;
  assign done_out   = buf_is_fp ? fpu_done   : alu_done;
  assign consume    = done_out;
  assign ready_out  = ~buf_valid;

endmodule
