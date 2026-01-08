// FILE: alu_top.v
// ALU top that instantiates IALU, IMUL, IDIV and multiplexer
module alu_top (
  input clk, rst_n,
  input [3:0] op,
  input [63:0] a, b,
  input div_start,
  output [127:0] mul_res,
  output [63:0] alu_res,
  output div_busy,
  output [63:0] div_q
);
  wire [63:0] ires;
  wire zero;
  IALU i_alu(.clk(clk), .rst_n(rst_n), .op(op), .a(a), .b(b), .y(ires), .zero(zero));
  IMUL i_mul(.a(a), .b(b), .product(mul_res));
  IDIV i_div(.clk(clk), .rst_n(rst_n), .start(div_start), .dividend(a), .divisor(b), .busy(div_busy), .quotient(div_q), .remainder());
  assign alu_res = ires;
endmodule

