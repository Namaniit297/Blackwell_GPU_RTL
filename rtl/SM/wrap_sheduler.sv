//==============================================================================
//  AGNI V1.0 - Warp Scheduler
//------------------------------------------------------------------------------
//  Author       : Naman Kalra
//  Copyright    : © 2025 IIT Tirupati
//  Description  : Round-Robin Warp Scheduler with support for stall, barrier,
//                 and divergence control. Compatible with CUDA-style execution.
//==============================================================================

module warp_scheduler #(
  parameter int NUM_WARPS = 32
)(
  input  logic                       clk,
  input  logic                       rst,

  // Warp state masks
  input  logic [NUM_WARPS-1:0]       active_mask,     // Warp is active
  input  logic [NUM_WARPS-1:0]       stall_mask,      // Warp is stalled (e.g., memory wait)
  input  logic [NUM_WARPS-1:0]       barrier_mask,    // Warp is at barrier sync
  input  logic [NUM_WARPS-1:0]       diverge_mask,    // Warp is diverged / waiting for reconverge

  // Output signals
  output logic [NUM_WARPS-1:0]       warp_issue_onehot, // One-hot encoding of scheduled warp
  output logic [$clog2(NUM_WARPS)-1:0] warp_id,        // Warp index to issue
  output logic                       valid              // 1 if a warp is selected
);

  // Internal scheduling state
  logic [NUM_WARPS-1:0] visible_mask;
  logic [$clog2(NUM_WARPS)-1:0] rr_ptr;

  // Refresh visible warps when mask is empty
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      visible_mask <= '0;
      rr_ptr <= 0;
    end else if (visible_mask == 0) begin
      visible_mask <= active_mask & ~(stall_mask | barrier_mask | diverge_mask);
      rr_ptr <= 0;
    end
  end

  // Round-Robin warp issue logic
  always_comb begin
    warp_issue_onehot = '0;
    valid = 0;
    warp_id = '0;

    for (int i = 0; i < NUM_WARPS; i++) begin
      int idx = (rr_ptr + i) % NUM_WARPS;
      if (visible_mask[idx]) begin
        warp_issue_onehot[idx] = 1;
        warp_id = idx[$clog2(NUM_WARPS)-1:0];
        valid = 1;
        break;
      end
    end
  end

  // Update RR pointer and visible_mask on valid issue
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      rr_ptr <= 0;
    end else if (valid) begin
      visible_mask[warp_id] <= 0;
      rr_ptr <= (warp_id + 1) % NUM_WARPS;
    end
  end

endmodule

