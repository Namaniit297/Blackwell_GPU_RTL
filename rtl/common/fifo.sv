// FILE: fifo.sv
// Generic synchronous FIFO
module fifo #(parameter WIDTH=64, DEPTH=16) (
  input  logic clk, rst_n,
  input  logic push, input logic [WIDTH-1:0] din,
  input  logic pop, output logic [WIDTH-1:0] dout,
  output logic empty, output logic full
);
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [$clog2(DEPTH)-1:0] rd, wr;
  logic [$clog2(DEPTH):0] cnt;

  assign empty = (cnt==0);
  assign full = (cnt==DEPTH);
  assign dout = mem[rd];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin rd<=0; wr<=0; cnt<=0; end
    else begin
      if (push && !full) begin mem[wr] <= din; wr <= wr+1; cnt <= cnt+1; end
      if (pop && !empty) begin rd <= rd+1; cnt <= cnt-1; end
    end
  end
endmodule

