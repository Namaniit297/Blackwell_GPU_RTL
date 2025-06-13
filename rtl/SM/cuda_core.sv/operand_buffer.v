module operand_buffer #(
  parameter int W = 32
)(
  input  logic clk,
  input  logic rst,
  input  logic write_en,
  input  logic [W-1:0] op1_in,
  input  logic [W-1:0] op2_in,
  input  logic [5:0] opcode_in,
  input  logic        is_fp_in,

  output logic valid_out,
  output logic [W-1:0] op1_out,
  output logic [W-1:0] op2_out,
  output logic [5:0] opcode_out,
  output logic        is_fp_out,
  input  logic        consume
);
  logic full;

  // One-deep buffer
  always_ff @(posedge clk or posedge rst) begin
    if (rst) valid_out <= 0;
    else if (write_en) valid_out <= 1;
    else if (consume) valid_out <= 0;
  end

  logic [W-1:0] op1, op2;
  logic [5:0] opcode;
  logic       is_fp;

  always_ff @(posedge clk) begin
    if (write_en) begin
      op1 <= op1_in;
      op2 <= op2_in;
      opcode <= opcode_in;
      is_fp <= is_fp_in;
    end
  end

  assign op1_out = op1;
  assign op2_out = op2;
  assign opcode_out = opcode;
  assign is_fp_out = is_fp;
endmodule
