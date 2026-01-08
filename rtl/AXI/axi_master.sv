// FILE: axi_master.sv
// Simple AXI-lite master interface used by DMA or CPU to initiate reads/writes
module axi_master #(
  parameter ADDR_W=32, DATA_W=32
)(
  input  logic                   clk, rst_n,
  // user command interface
  input  logic                   start_wr,
  input  logic [ADDR_W-1:0]      wr_addr,
  input  logic [DATA_W-1:0]      wr_data,
  output logic                   wr_done,
  input  logic                   start_rd,
  input  logic [ADDR_W-1:0]      rd_addr,
  output logic [DATA_W-1:0]      rd_data,
  output logic                   rd_done,
  // connected to crossbar ports (M0)
  output logic                   awvalid,
  output logic [ADDR_W-1:0]      awaddr,
  output logic                   wvalid,
  output logic [DATA_W-1:0]      wdata,
  input  logic                   bvalid,
  output logic                   bready,
  output logic                   arvalid,
  output logic [ADDR_W-1:0]      araddr,
  input  logic [DATA_W-1:0]      rdata,
  input  logic                   rvalid
);

  typedef enum logic [1:0] {IDLE, WRITE_ADDR, WRITE_DATA, WAIT_B, READ_ADDR, WAIT_R} state_t;
  state_t state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      awvalid<=0; wvalid<=0; bready<=0; arvalid<=0;
      wr_done<=0; rd_done<=0;
    end else begin
      case(state)
        IDLE: begin
          wr_done<=0; rd_done<=0;
          if (start_wr) begin awaddr<=wr_addr; awvalid<=1; state<=WRITE_ADDR; end
          else if (start_rd) begin araddr<=rd_addr; arvalid<=1; state<=READ_ADDR; end
        end
        WRITE_ADDR: begin
          if (awvalid && !bready) begin awvalid<=0; wvalid<=1; wdata<=wr_data; state<=WRITE_DATA; end
        end
        WRITE_DATA: begin
          if (wvalid) begin wvalid<=0; bready<=1; state<=WAIT_B; end
        end
        WAIT_B: begin
          if (bvalid && bready) begin bready<=0; wr_done<=1; state<=IDLE; end
        end
        READ_ADDR: begin
          arvalid<=0; if (arvalid==0) state<=WAIT_R; // placeholder
        end
        WAIT_R: begin
          if (rvalid) begin rd_data<=rdata; rd_done<=1; state<=IDLE; end
        end
      endcase
    end
  end

endmodule
