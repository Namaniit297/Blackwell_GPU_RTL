// FILE: dram_ctrl.sv
// Very simple DRAM controller model (serves loads/stores with fixed latency)
module dram_ctrl #(parameter ADDR_WIDTH=40, DATA_WIDTH=64, LATENCY=50)(
  input  logic                  clk,
  input  logic                  rst_n,
  // request interface (simple)
  input  logic                  req_valid,
  input  logic [ADDR_WIDTH-1:0] req_addr,
  input  logic                  req_write,
  input  logic [DATA_WIDTH-1:0] req_wdata,
  output logic                  resp_valid,
  output logic [DATA_WIDTH-1:0] resp_rdata
);

  // small request FIFO
  typedef struct packed { logic [ADDR_WIDTH-1:0] addr; logic write; logic [DATA_WIDTH-1:0] wdata; } req_t;
  req_t req_q;
  logic [7:0] timer;
  logic active;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active <= 0; timer <= 0; resp_valid <= 0; resp_rdata <= 0;
    end else begin
      if (req_valid && !active) begin
        req_q.addr <= req_addr;
        req_q.write <= req_write;
        req_q.wdata <= req_wdata;
        active <= 1;
        timer <= LATENCY;
      end

      if (active) begin
        if (timer==0) begin
          active <= 0;
          resp_valid <= 1;
          if (!req_q.write) resp_rdata <= { { (DATA_WIDTH-32){1'b0} }, req_q.addr[31:0] }; // mock data
        end else begin
          timer <= timer - 1;
          resp_valid <= 0;
        end
      end else resp_valid <= 0;
    end
  end

endmodule

