// FILE: axi_iface.sv
// Simple AXI-lite-like control interface (write/read). Template that decodes a few registers.
module axi_iface #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)(
  input  logic                  clk,
  input  logic                  rst_n,
  // write channel
  input  logic                  awvalid,
  input  logic [ADDR_WIDTH-1:0] awaddr,
  input  logic                  wvalid,
  input  logic [DATA_WIDTH-1:0] wdata,
  output logic                  bvalid,
  input  logic                  bready,
  // read channel
  input  logic                  arvalid,
  input  logic [ADDR_WIDTH-1:0] araddr,
  output logic                  arready,
  output logic [DATA_WIDTH-1:0] rdata,
  output logic                  rvalid
);

  logic [DATA_WIDTH-1:0] regfile [0:15]; // 16 control regs

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      bvalid <= 0;
      rvalid <= 0;
      arready <= 1;
      rdata <= 0;
    end else begin
      if (awvalid && wvalid) begin
        // decode low bits as register index
        regfile[awaddr[7:4]] <= wdata;
        bvalid <= 1;
      end else if (bready) bvalid <= 0;

      if (arvalid) begin
        rdata <= regfile[araddr[7:4]];
        rvalid <= 1;
      end else rvalid <= 0;
    end
  end

endmodule

