// FILE: Store_Queue.v
// Simple store queue that buffers stores until commit/retire
module Store_Queue #(
  parameter ADDR_W = 40,
  parameter DATA_W = 64,
  parameter DEPTH = 32
)(
  input  clk,
  input  rst_n,
  input  push,
  input  [ADDR_W-1:0] addr_in,
  input  [DATA_W-1:0] data_in,
  output pop,
  output [ADDR_W-1:0] addr_out,
  output [DATA_W-1:0] data_out,
  output empty
);
  reg [ADDR_W-1:0] addr_q [0:DEPTH-1];
  reg [DATA_W-1:0] data_q [0:DEPTH-1];
  reg [$clog2(DEPTH):0] head, tail, cnt;

  assign empty = (cnt==0);
  assign pop = (cnt>0);
  assign addr_out = addr_q[head];
  assign data_out = data_q[head];

  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 0; tail <= 0; cnt <= 0;
      for (i=0;i<DEPTH;i++) begin addr_q[i] <= 0; data_q[i] <= 0; end
    end else begin
      if (push && cnt < DEPTH) begin
        addr_q[tail] <= addr_in;
        data_q[tail] <= data_in;
        tail <= tail + 1;
        cnt <= cnt + 1;
      end
      if (pop && cnt > 0) begin
        head <= head + 1;
        cnt <= cnt - 1;
      end
    end
  end
endmodule

