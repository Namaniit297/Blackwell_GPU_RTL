//==============================================================================
// AGNI V1.0 – sm_box.sv
//------------------------------------------------------------------------------
// Description: One compute box in SM. Includes 2 warp schedulers, full pipeline,
//              and 32 shared CUDA cores. Based on Blackwell SM box structure.
//==============================================================================

module sm_box #(
  parameter int W = 32,
  parameter int NUM_THREADS = 32  // Number of physical CUDA cores
)(
  input  logic clk,
  input  logic rst,

  // Inputs from SM-level warp pool / wavefront allocator
  input  logic [1:0][31:0] warp_active_mask,   // [warp_id][thread_id] active
  input  logic [1:0][31:0] warp_stall_mask,    // e.g., waiting on memory
  input  logic [1:0][31:0] warp_barrier_mask,

  // Outputs to writeback unit or scoreboard
  output logic [NUM_THREADS-1:0][W-1:0] result_out,
  output logic [NUM_THREADS-1:0]        done_out
);

  //--------------------------------------------------------------------------
  // Warp Scheduler Arbitration (Choose one warp per cycle)
  //--------------------------------------------------------------------------

  logic [1:0]                        warp_valid;
  logic [$clog2(NUM_THREADS)-1:0]   warp_id_sel;
  logic [31:0]                      active_mask_sel;
  logic [31:0]                      stall_mask_sel;
  logic [31:0]                      barrier_mask_sel;

  // Instantiate 2 warp schedulers
  logic [1:0][31:0] issue_onehot;
  logic [1:0][$clog2(NUM_THREADS)-1:0] issued_warp_id;
  logic [1:0] valid_sched;

  genvar i;
  generate
    for (i = 0; i < 2; i++) begin : warp_sched_block
      warp_scheduler #(.NUM_WARPS(32)) scheduler_i (
        .clk(clk),
        .rst(rst),
        .active_mask(warp_active_mask[i]),
        .stall_mask(warp_stall_mask[i]),
        .barrier_mask(warp_barrier_mask[i]),
        .warp_issue_onehot(issue_onehot[i]),
        .warp_id(issued_warp_id[i]),
        .valid(valid_sched[i])
      );
    end
  endgenerate

  // Round-robin arbitration between two warp schedulers
  logic rr_select;
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      rr_select <= 0;
    else if (valid_sched[0] ^ valid_sched[1])
      rr_select <= valid_sched[1];  // prioritize whichever is valid
    else
      rr_select <= ~rr_select;      // alternate
  end

  assign warp_valid      = valid_sched[rr_select];
  assign warp_id_sel     = issued_warp_id[rr_select];
  assign active_mask_sel = warp_active_mask[rr_select];
  assign stall_mask_sel  = warp_stall_mask[rr_select];
  assign barrier_mask_sel= warp_barrier_mask[rr_select];

  //--------------------------------------------------------------------------
  // Fetch + Decode + Issue (Stub logic, to be completed later)
  //--------------------------------------------------------------------------

  logic [5:0]              opcode;
  logic                    is_fp;
  logic [W-1:0]            op1[NUM_THREADS];
  logic [W-1:0]            op2[NUM_THREADS];
  logic [NUM_THREADS-1:0]  core_ready;
  logic [NUM_THREADS-1:0]  core_valid;
  logic [NUM_THREADS*6-1:0]core_opcode;
  logic [NUM_THREADS*W-1:0]core_op1_flat;
  logic [NUM_THREADS*W-1:0]core_op2_flat;
  logic [NUM_THREADS-1:0]  core_is_fp;

  // [STUB] Fetched instruction (same for all active threads of warp)
  assign opcode = 6'h02;  // e.g., MUL
  assign is_fp  = 1'b0;

  // [STUB] Dummy operands per thread
  generate
    for (i = 0; i < NUM_THREADS; i++) begin : dummy_ops
      assign op1[i] = i;
      assign op2[i] = 2*i;
    end
  endgenerate

  // Flatten operand buses
  generate
    for (i = 0; i < NUM_THREADS; i++) begin : flatten_ops
      assign core_op1_flat[i*W +: W] = op1[i];
      assign core_op2_flat[i*W +: W] = op2[i];
    end
  endgenerate

  //--------------------------------------------------------------------------
  // NoC Dispatcher (with ready + masking)
  //--------------------------------------------------------------------------

  noc_dispatcher_with_ready #(
    .NUM_THREADS(NUM_THREADS),
    .REG_WIDTH(W)
  ) noc (
    .clk(clk),
    .rst(rst),
    .warp_valid(warp_valid),
    .opcode(opcode),
    .is_fp(is_fp),
    .thread_active(active_mask_sel),
    .core_ready(core_ready),
    .op1_bus(core_op1_flat),
    .op2_bus(core_op2_flat),
    .core_valid(core_valid),
    .core_op1(core_op1_flat),
    .core_op2(core_op2_flat),
    .core_opcode(core_opcode),
    .core_is_fp(core_is_fp)
  );

  //--------------------------------------------------------------------------
  // 32 Shared CUDA Cores
  //--------------------------------------------------------------------------

  generate
    for (i = 0; i < NUM_THREADS; i++) begin : shared_cores
      cuda_thread #(.W(W)) thread_core (
        .clk(clk),
        .rst(rst),
        .valid_in(core_valid[i]),
        .opcode_in(core_opcode[i*6 +: 6]),
        .is_fp_in(core_is_fp[i]),
        .op1_in(core_op1_flat[i*W +: W]),
        .op2_in(core_op2_flat[i*W +: W]),
        .result_out(result_out[i]),
        .done_out(done_out[i]),
        .ready_out(core_ready[i])
      );
    end
  endgenerate

endmodule
