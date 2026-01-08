// FILE: axi_slave_bridge.sv
// Simple adapter: maps incoming AXI-lite accesses to a register file and memory interface
module axi_slave_bridge #(
  parameter ADDR_W=32, DATA_W=32, REGS=16
)(
  input logic clk, rst_n,
  // slave AXI-lite signals (one slave port)
  input  logic                    awvalid,
  input  logic [ADDR_W-1:0]       awaddr,
  input  logic                    wvalid,
  input  logic [DATA_W-1:0]       wdata,
  output logic                    bvalid,
  input  logic                    bready,
  input  logic                    arvalid,
  input  logic [ADDR_W-1:0]       araddr,
  output logic [DATA_W-1:0]       rdata,
  output logic                    rvalid,

  // simple memory access interface (synchronous)
  output logic                    mem_req,
  output logic [ADDR_W-1:0]       mem_addr,
  output logic                    mem_wr,
  output logic [DATA_W-1:0]       mem_wdata,
  input  logic                    mem_ack,
  input  logic [DATA_W-1:0]       mem_rdata
);

  logic [DATA_W-1:0] regs [0:REGS-1];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin bvalid<=0; rvalid<=0; mem_req<=0; end
    else begin
      if (awvalid && wvalid) begin
        if (awaddr[7:4] < REGS) begin
          regs[awaddr[7:4]] <= wdata;
          bvalid <= 1;
        end else begin
          // redirect to memory
          mem_req <= 1; mem_addr <= awaddr; mem_wr <= 1; mem_wdata <= wdata;
          if (mem_ack) begin bvalid <= 1; mem_req <= 0; mem_wr <= 0; end
        end
      end else if (bready) bvalid <= 0;

      if (arvalid) begin
        if (araddr[7:4] < REGS) begin
          rdata <= regs[araddr[7:4]];
          rvalid <= 1;
        end else begin
          mem_req <= 1; mem_addr <= araddr; mem_wr <= 0;
          if (mem_ack) begin rdata <= mem_rdata; rvalid <= 1; mem_req <= 0; end
        end
      end else rvalid <= 0;
    end
  end

endmodule
