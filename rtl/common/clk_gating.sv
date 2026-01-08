// FILE: clk_gating.sv
// Clock gating cell (template using enable)
module clk_gating (
  input  logic clk_in,
  input  logic enable,
  output logic clk_out
);
  // In synthesis you'd use vendor clock gating cells. For simulation we simply AND.
  assign clk_out = clk_in & enable;
endmodule

