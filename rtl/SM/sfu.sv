// FILE: sfu.sv
// Special function unit: e.g., reciprocal, sqrt (template using simple combinational ops)
module sfu (
  input logic clk, rst_n,
  input logic [31:0] in,
  input logic start,
  output logic [31:0] out,
  output logic ready
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin ready<=0; out<=0; end
    else if (start) begin
      // for template, compute simple reciprocal approximation
      out <= (in!=0) ? (32'h3f800000 / in) : 0;
      ready <= 1;
    end else ready <= 0;
  end
endmodule

