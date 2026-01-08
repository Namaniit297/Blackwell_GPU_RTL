// FILE: tensor_core.sv
// Simplified tensor core: performs small matrix multiply for 4x4 tiles (for template)
module tensor_core (
  input logic clk, rst_n,
  input logic start,
  input logic [15:0] a0, a1, a2, a3,
  input logic [15:0] b0, b1, b2, b3,
  output logic done,
  output logic [31:0] c0, c1, c2, c3
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin done<=0; c0<=0;c1<=0;c2<=0;c3<=0; end
    else if (start) begin
      c0 <= a0*b0 + a1*b2;
      c1 <= a0*b1 + a1*b3;
      c2 <= a2*b0 + a3*b2;
      c3 <= a2*b1 + a3*b3;
      done <= 1;
    end else done <= 0;
  end
endmodule

