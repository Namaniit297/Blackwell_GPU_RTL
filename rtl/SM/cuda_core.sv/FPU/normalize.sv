`default_nettype none

module fp_normalize #(
  parameter int M = 23,
  parameter int E = 8
)(
  input logic [2*M+2:0] in_m, // input mantissa with extra bits
  input logic [E:0]       in_e,
  input logic             in_valid,
  output logic [M:0]      out_m,
  output logic [E:0]      out_e,
  output logic            valid
);
  logic [$clog2(2*M+3)-1:0] shift;
  int i;

  always_comb begin
    shift = 0;
    for (i = 2*M+2; i >= 0; i--) 
      if (in_m[i]) begin shift = 2*M+2 - i; break; end

    out_m = (in_m << shift)[2*M+2 -: M+1];
    out_e = in_e - shift;
  end

  assign valid = in_valid;
endmodule

