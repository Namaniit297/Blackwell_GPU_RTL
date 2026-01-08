// FILE: arbiter.sv
// Simple round-robin arbiter supporting N requestors
module arbiter #(parameter N=4) (
  input  logic clk, rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] grant
);
  integer i;
  reg [$clog2(N)-1:0] ptr;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin ptr <= 0; grant <= 0; end
    else begin
      grant <= 0;
      integer j;
      for (j=0;j<N;j++) begin
        int idx = (ptr+j) % N;
        if (req[idx]) begin grant[idx] <= 1; ptr <= idx+1; break; end
      end
    end
  end
endmodule

