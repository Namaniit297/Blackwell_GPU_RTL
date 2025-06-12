//==============================================================================
// AGNI V1.0 - Instruction Fetch Unit
//------------------------------------------------------------------------------
// Author       : Naman Kalra
// Copyright    : © 2025, IIT Tirupati
// Description  : Single-instruction fetch per cycle with round-robin warp
//               selection. Supports local queue (wavepool) of instructions.
//==============================================================================

module fetch #(
  parameter int NUM_WARPS    = 32,
  parameter int PC_WIDTH     = 32,
  parameter int INST_WIDTH   = 32,
  parameter int QUEUE_DEPTH  = 8
)(
  input  logic                        clk,
  input  logic                        rst,

  // From warp scheduler
  input  logic                        fetch_enable,
  input  logic [$clog2(NUM_WARPS)-1:0] fetch_warp_id,

  // Instruction Memory interface
  output logic [PC_WIDTH-1:0]         imem_addr,
  input  logic [INST_WIDTH-1:0]       imem_data,
  input  logic                        imem_valid,

  // To decoder/issue
  output logic                        fetch_valid,
  output logic [INST_WIDTH-1:0]       inst_out,
  output logic [$clog2(NUM_WARPS)-1:0] warp_id_out
);

  // Per-warp program counters
  logic [NUM_WARPS-1:0][PC_WIDTH-1:0] pc_table;

  // Local queue for fetched instructions (wavepool)
  typedef struct packed {
    logic                        valid;
    logic [PC_WIDTH-1:0]        pc;
    logic [INST_WIDTH-1:0]      inst;
    logic [$clog2(NUM_WARPS)-1:0] wid;
  } queue_entry_t;

  queue_entry_t queue [0:QUEUE_DEPTH-1];
  integer q_head, q_tail, q_count;

  // Initialize PC and queue
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (int i = 0; i < NUM_WARPS; i++) pc_table[i] <= '0;
      q_head <= 0; q_tail <= 0; q_count <= 0;
    end else begin
      if (imem_valid && q_count < QUEUE_DEPTH) begin
        queue[q_tail] <= '{
          valid: 1'b1,
          pc: pc_table[fetch_warp_id],
          inst: imem_data,
          wid: fetch_warp_id
        };
        q_tail <= (q_tail + 1) % QUEUE_DEPTH;
        q_count <= q_count + 1;
      end

      fetch_valid <= (q_count > 0);
      if (fetch_valid) begin
        inst_out <= queue[q_head].inst;
        warp_id_out <= queue[q_head].wid[$clog2(NUM_WARPS)-1:0];
        q_head <= (q_head + 1) % QUEUE_DEPTH;
        q_count <= q_count - 1;
      end
    end
  end

  // Trigger memory fetch for next warp
  assign imem_addr = pc_table[fetch_warp_id];
  assign fetch_enable = (q_count < QUEUE_DEPTH);

endmodule

