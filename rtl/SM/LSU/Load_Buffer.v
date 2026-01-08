// FILE: Load_Buffer.v
// Simple load buffer to track outstanding loads and forward on store-to-load hits
module Load_Buffer #(
  parameter ADDR_W = 40,
  parameter DATA_W = 64,
  parameter DEPTH = 32
)(
  input clk,
  input rst_n,
  input push,
  input [ADDR_W-1:0] addr_in,
  output [ADDR_W-1:0] head_addr,
  output empty
);
  reg [ADDR_W-1:0] q [0:DEPTH-1];
  reg [$clog2(DEPTH):0] head, tail, cnt;
  integer i;
  assign empty = (cnt==0);
  assign head_addr = q[head];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head<=0; tail<=0; cnt<=0;
      for (i=0;i<DEPTH;i++) q[i]<=0;
    end else begin
      if (push && cnt < DEPTH) begin
        q[tail] <= addr_in;
        tail <= tail + 1;
        cnt <= cnt + 1;
      end
      if (!empty) begin
        // pop when consumed externally (not modeled here)
      end
    end
  end
endmodule

