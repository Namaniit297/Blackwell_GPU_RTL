// FILE: l1_cache.sv
// Tiny L1 data cache template (write-through for simplicity)
module l1_cache #(
  parameter ADDR_WIDTH=40, DATA_WIDTH=64, LINES=64
)(
  input logic clk, rst_n,
  input logic        req_valid,
  input logic [ADDR_WIDTH-1:0] req_addr,
  input logic        req_write,
  input logic [DATA_WIDTH-1:0] req_wdata,
  output logic       resp_valid,
  output logic [DATA_WIDTH-1:0] resp_rdata
);
  // direct-mapped small cache
  logic [DATA_WIDTH-1:0] mem [0:LINES-1];
  logic [ADDR_WIDTH-1:0] tags [0:LINES-1];
  logic valid [0:LINES-1];

  integer i;
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for (i=0;i<LINES;i++) begin valid[i]<=0; mem[i]<=0; tags[i]<=0; end
      resp_valid <= 0;
    end else begin
      resp_valid <= 0;
      if (req_valid) begin
        int idx = req_addr[11:6]; // example indexing
        if (valid[idx] && tags[idx]==req_addr) begin
          // hit
          if (req_write) mem[idx] <= req_wdata;
          else resp_rdata <= mem[idx];
          resp_valid <= 1;
        end else begin
          // miss: return zero in template and mark line
          tags[idx] <= req_addr;
          valid[idx] <= 1;
          if (req_write) mem[idx] <= req_wdata;
          else resp_rdata <= 0;
          resp_valid <= 1;
        end
      end
    end
  end
endmodule

