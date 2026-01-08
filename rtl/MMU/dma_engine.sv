// FILE: dma_engine.sv
// Simple DMA engine: reads from memory and writes to dest, provides AXI-lite control regs
module dma_engine #(
  parameter ADDR_W=32, DATA_W=64
)(
  input logic clk, rst_n,
  // control: start, src, dst, len (words)
  input logic start,
  input logic [ADDR_W-1:0] src,
  input logic [ADDR_W-1:0] dst,
  input logic [31:0] len,
  output logic done,
  // memory interface (simple req/ack)
  output logic mem_rd_req,
  output logic [ADDR_W-1:0] mem_rd_addr,
  input  logic mem_rd_ack,
  input  logic [DATA_W-1:0] mem_rd_data,
  output logic mem_wr_req,
  output logic [ADDR_W-1:0] mem_wr_addr,
  output logic [DATA_W-1:0] mem_wr_data,
  input  logic mem_wr_ack
);

  logic [31:0] counter;
  typedef enum logic [1:0] {IDLE, RD, WR, DONE} st_t;
  st_t state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE; done<=0; counter<=0; mem_rd_req<=0; mem_wr_req<=0;
    end else begin
      case(state)
        IDLE: begin done<=0;
          if (start) begin counter <= 0; state <= RD; end
        end
        RD: begin
          mem_rd_req <= 1; mem_rd_addr <= src + counter* (DATA_W/8);
          if (mem_rd_ack) begin mem_rd_req <= 0; mem_wr_req <= 1; mem_wr_data <= mem_rd_data; mem_wr_addr <= dst + counter*(DATA_W/8); state <= WR; end
        end
        WR: begin
          if (mem_wr_ack) begin mem_wr_req <= 0; counter <= counter + 1; if (counter + 1 >= len) state <= DONE; else state <= RD; end
        end
        DONE: begin done <= 1; state <= IDLE; end
      endcase
    end
  end
endmodule
