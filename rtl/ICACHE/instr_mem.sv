// FILE: instr_mem.sv
// Instruction memory (block RAM wrapper)
module instr_mem #(
  parameter ADDR_W = 20,
  parameter DATA_W = 32
)(
  input logic clk,
  input logic [ADDR_W-1:0] addr,
  input logic        req,
  output logic [DATA_W-1:0] rdata,
  output logic       ack
);
  logic [DATA_W-1:0] mem [0:(1<<ADDR_W)-1];
  always_ff @(posedge clk) begin
    if (req) begin rdata <= mem[addr]; ack <= 1; end else ack <= 0;
  end
  // Note: initialize mem via $readmemh in testbench / synthesis init file
endmodule
