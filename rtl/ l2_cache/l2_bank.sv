// FILE: l2_bank.sv
// Simple L2 bank: set-associative single-bank SRAM-like behavior, synchronous read/write
module l2_bank #(
  parameter ADDR_WIDTH = 40,
  parameter DATA_WIDTH = 64,
  parameter BANK_SIZE = 16*1024 // number of lines for template
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    en,
  input  logic                    wr,
  input  logic [ADDR_WIDTH-1:0]   addr,
  input  logic [DATA_WIDTH-1:0]   wdata,
  output logic [DATA_WIDTH-1:0]   rdata,
  output logic                    ready
);

  localparam LINE_WIDTH = DATA_WIDTH;
  // Simple direct-mapped memory for template
  logic [DATA_WIDTH-1:0] mem [0:BANK_SIZE-1];

  wire [$clog2(BANK_SIZE)-1:0] index = addr[$clog2(BANK_SIZE)+5-1:5]; // example offset bits

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      ready <= 1'b0;
    end else begin
      if (en) begin
        if (wr) begin
          mem[index] <= wdata;
          ready <= 1'b1;
        end else begin
          rdata <= mem[index];
          ready <= 1'b1;
        end
      end else ready <= 1'b0;
    end
  end

endmodule

