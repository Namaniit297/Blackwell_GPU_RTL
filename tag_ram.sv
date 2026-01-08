// FILE: tag_ram.sv
// Generic tag RAM for caches (synthesizable RAM)
module tag_ram #(
  parameter ENTRIES = 256,
  parameter TAG_W = 20
)(
  input logic clk, rst_n,
  input logic [$clog2(ENTRIES)-1:0] addr,
  input logic wr,
  input logic [TAG_W-1:0] tag_in,
  output logic [TAG_W-1:0] tag_out
);
  logic [TAG_W-1:0] ram [0:ENTRIES-1];
  always_ff @(posedge clk) begin
    if (wr) ram[addr] <= tag_in;
    tag_out <= ram[addr];
  end
endmodule
