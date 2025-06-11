`default_nettype none

module fp_round #(
  parameter int M = 23,
  parameter int E = 8
)(
  input logic             valid,
  input logic [M:0]       mant_in,
  input logic [E:0]       exp_in,
  input logic             guard,
  input logic             round_bit,
  input logic             sticky,
  output logic [M-1:0]    mant_out,
  output logic [E-1:0]    exp_out,
  output logic            overflow,
  output logic            underflow,
  output logic            inexact,
  output logic            valid_out
);
  logic [M:0] m_rounded;
  logic [E:0] e_tmp;
  logic round_up;

  assign inexact = guard | round_bit | sticky;
  assign round_up = guard & (round_bit | sticky | mant_in[0]);

  always_comb begin
    m_rounded = mant_in + round_up;
    e_tmp = exp_in;
    if (m_rounded[M]) begin // overflow to 1.x pattern
      m_rounded = m_rounded >> 1;
      e_tmp = exp_in + 1;
    end
    mant_out = m_rounded[M-1:0];
    exp_out = e_tmp[E-1:0];
    overflow  = (e_tmp >= (1<<E)-1);
    underflow = (e_tmp == 0);
  end

  assign valid_out = valid;
endmodule

