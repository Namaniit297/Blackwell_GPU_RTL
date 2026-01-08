// FILE: icache_controller.sv
// Instruction cache controller: request fetches from instr_mem and provide to fetch stage.
// Simple direct-mapped template with refill on miss.
module icache_controller #(
  parameter ADDR_W=32, LINE_BYTES = 64, LINES = 256, DATA_W=64
)(
  input logic clk, rst_n,
  input logic [ADDR_W-1:0] pc,
  output logic [DATA_W-1:0] instr_word,
  // backend memory interface
  output logic mem_req,
  output logic [ADDR_W-1:0] mem_addr,
  input  logic mem_ack,
  input  logic [DATA_W-1:0] mem_rdata
);

  localparam TAG_W = ADDR_W - $clog2(LINES) - $clog2(LINE_BYTES);
  typedef struct packed { logic valid; logic [TAG_W-1:0] tag; logic [DATA_W-1:0] data; } line_t;
  line_t cache [LINES];

  wire [$clog2(LINES)-1:0] idx = pc[$clog2(LINES)+$clog2(LINE_BYTES)-1:$clog2(LINE_BYTES)];
  wire [TAG_W-1:0] tag = pc[ADDR_W-1:$clog2(LINES)+$clog2(LINE_BYTES)];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0;i<LINES;i++) cache[i].valid <= 0;
      mem_req <= 0; instr_word <= 0;
    end else begin
      if (cache[idx].valid && cache[idx].tag == tag) begin
        instr_word <= cache[idx].data;
        mem_req <= 0;
      end else begin
        // Miss: request line
        mem_req <= 1;
        mem_addr <= { pc[ADDR_W-1:$clog2(LINE_BYTES)], { $clog2(LINE_BYTES){1'b0} } };
        if (mem_ack) begin
          cache[idx].valid <= 1;
          cache[idx].tag <= tag;
          cache[idx].data <= mem_rdata;
          instr_word <= mem_rdata;
          mem_req <= 0;
        end
      end
    end
  end

endmodule
