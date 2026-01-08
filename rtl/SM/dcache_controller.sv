// FILE: dcache_controller.sv
// Data cache controller with write-buffer and simple write-through policy
module dcache_controller #(
  parameter ADDR_W=32, DATA_W=64, LINES=256, LINE_BYTES=64
)(
  input logic clk, rst_n,
  input logic req_valid,
  input logic [ADDR_W-1:0] req_addr,
  input logic req_write,
  input logic [DATA_W-1:0] req_wdata,
  output logic resp_valid,
  output logic [DATA_W-1:0] resp_rdata,
  // memory backend
  output logic mem_req,
  output logic [ADDR_W-1:0] mem_addr,
  output logic mem_write,
  output logic [DATA_W-1:0] mem_wdata,
  input  logic mem_ack,
  input  logic [DATA_W-1:0] mem_rdata
);

  typedef struct packed { logic valid; logic [ADDR_W-1:$clog2(LINES)-1] tag; logic [DATA_W-1:0] data; } dline_t;
  dline_t cache [LINES];
  wire [$clog2(LINES)-1:0] idx = req_addr[$clog2(LINES)+$clog2(LINE_BYTES)-1:$clog2(LINE_BYTES)];
  wire [ADDR_W-1:$clog2(LINES)] tag = req_addr[ADDR_W-1:$clog2(LINES)+$clog2(LINE_BYTES)];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      resp_valid <= 0; mem_req <= 0;
      for (int i=0;i<LINES;i++) cache[i].valid <= 0;
    end else begin
      resp_valid <= 0;
      if (req_valid) begin
        if (cache[idx].valid && cache[idx].tag == tag) begin
          // hit
          if (req_write) begin cache[idx].data <= req_wdata; mem_req <= 1; mem_write <= 1; mem_addr <= req_addr; mem_wdata <= req_wdata; end
          else resp_rdata <= cache[idx].data;
          resp_valid <= 1;
        end else begin
          // miss: fetch line
          mem_req <= 1; mem_write <= 0; mem_addr <= { req_addr[ADDR_W-1:$clog2(LINE_BYTES)], { $clog2(LINE_BYTES){1'b0} } };
          if (mem_ack) begin
            cache[idx].valid <= 1; cache[idx].tag <= tag; cache[idx].data <= mem_rdata;
            resp_rdata <= mem_rdata; resp_valid <= 1; mem_req <= 0;
          end
        end
      end
      if (mem_ack && mem_write) mem_req <= 0;
    end
  end

endmodule
