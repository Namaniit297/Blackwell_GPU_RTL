//==============================================================================
//  AGNI V1.0+IPDOM - Warp Scheduler with Reconvergence Stack
//------------------------------------------------------------------------------
//  Author       : Naman Kalra
//  Copyright    : © 2025 IIT Tirupati
//  Description  : Vortex-style IPDOM-aware warp scheduler for handling branch
//                 divergence and reconvergence via per-warp stacks.
//==============================================================================

module warp_scheduler_ipdom #(
  parameter int NUM_WARPS = 32,
  parameter int PC_WIDTH  = 32,
  parameter int STACK_DEPTH = 8
)(
  input  logic                        clk,
  input  logic                        rst,

  // Warp execution state
  input  logic [NUM_WARPS-1:0]        active_mask,
  input  logic [NUM_WARPS-1:0]        stall_mask,
  input  logic [NUM_WARPS-1:0]        barrier_mask,

  // Divergence control
  input  logic                        branch_taken,
  input  logic                        branch_split,       // Indicates new divergence
  input  logic [PC_WIDTH-1:0]         ipdom_target,       // Immediate post-dominator
  input  logic [$clog2(NUM_WARPS)-1:0] branch_warp_id,

  // Outputs
  output logic [NUM_WARPS-1:0]        warp_issue_onehot,
  output logic [$clog2(NUM_WARPS)-1:0] warp_id,
  output logic                        valid
);

  // Reconvergence stack per warp
  logic [PC_WIDTH-1:0] ipdom_stack [NUM_WARPS][STACK_DEPTH];
  logic [$clog2(STACK_DEPTH)-1:0] sp [NUM_WARPS];

  logic [NUM_WARPS-1:0] visible_mask;
  logic [$clog2(NUM_WARPS)-1:0] rr_ptr;

  // Handle divergence push
  always_ff @(posedge clk) begin
    if (branch_split) begin
      ipdom_stack[branch_warp_id][sp[branch_warp_id]] <= ipdom_target;
      sp[branch_warp_id] <= sp[branch_warp_id] + 1;
    end
  end

  // Rebuild visible_mask
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      rr_ptr <= 0;
      visible_mask <= 0;
      for (int i = 0; i < NUM_WARPS; i++) begin
        sp[i] <= 0;
      end
    end else if (visible_mask == 0) begin
      visible_mask <= active_mask & ~(stall_mask | barrier_mask);
      rr_ptr <= 0;
    end
  end

  // Warp selection logic
  always_comb begin
    warp_issue_onehot = 0;
    warp_id = 0;
    valid = 0;
    for (int i = 0; i < NUM_WARPS; i++) begin
      int idx = (rr_ptr + i) % NUM_WARPS;
      if (visible_mask[idx]) begin
        warp_issue_onehot[idx] = 1;
        warp_id = idx;
        valid = 1;
        break;
      end
    end
  end

  // On valid issue
  always_ff @(posedge clk) begin
    if (valid) begin
      visible_mask[warp_id] <= 0;
      rr_ptr <= (warp_id + 1) % NUM_WARPS;
    end
  end

endmodule

