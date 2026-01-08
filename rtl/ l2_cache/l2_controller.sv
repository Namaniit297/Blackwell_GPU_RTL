// FILE: l2_controller.sv
// Lightweight controller that arbitrates between L1 requests (from SMs) and DRAM
module l2_controller #(
  parameter ADDR_WIDTH = 40,
  parameter DATA_WIDTH = 64
)(
  input  logic                clk,
  input  logic                rst_n
  // In a real design you'd have request/resp FIFOs, AXI channels, coherence messages
);

  // For template: implement a simple FSM to forward misses to dram_ctrl via a basic interface
  typedef enum logic [1:0] {IDLE, SERVE, REFILL} state_t;
  state_t state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else begin
      case(state)
        IDLE: state <= IDLE;
        default: state <= IDLE;
      endcase
    end
  end

endmodule

