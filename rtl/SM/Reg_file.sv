//==============================================================================
// AGNI V1.0 – Multi-Banked Register File (BRAM bitmap)
// Author: Naman Kalra  |  © 2025 IIT Tirupati
// Description: FPGA-friendly SRF + VRF using BRAM banks per warp/thread
//==============================================================================

module regfile_multi_bank #(
  parameter int NUM_WARPS   = 32,
  parameter int NUM_LANES   = 32,
  parameter int BANKS       = 4,
  parameter int SREG_COUNT  = 32,
  parameter int VREG_COUNT  = 128,
  parameter int W           = 32
)(
  input  logic                     clk, rst,

  // Scalar write (per warp)
  input  logic                     s_wen,
  input  logic [5:0]               s_wwarp,
  input  logic [$clog2(SREG_COUNT)-1:0] s_waddr,
  input  logic [W-1:0]             s_wdata,

  // Vector write (one lane per cycle)
  input  logic                     v_wen,
  input  logic [5:0]               v_wwarp,
  input  logic [$clog2(NUM_LANES)-1:0] v_wlane,
  input  logic [$clog2(VREG_COUNT)-1:0] v_waddr,
  input  logic [W-1:0]             v_wdata,

  // Vector reads (all lanes in parallel)
  input  logic [NUM_LANES-1:0]     v_ren,
  input  logic [NUM_LANES*$clog2(VREG_COUNT)-1:0] v_raddrs,
  input  logic [5:0]               v_rrwarp,
  output logic [NUM_LANES*W-1:0]   v_rdata,

  // Scalar read
  input  logic                     s_ren,
  input  logic [5:0]               s_rrwarp,
  input  logic [$clog2(SREG_COUNT)-1:0] s_raddr,
  output logic [W-1:0]             s_rdata
);

  // Scalar RF: distributed RAM
  logic [W-1:0] sregs [NUM_WARPS-1:0][0:SREG_COUNT-1];
  assign s_rdata = s_ren ? sregs[s_rrwarp][s_raddr] : '0;

  always_ff @(posedge clk) begin
    if (s_wen) sregs[s_wwarp][s_waddr] <= s_wdata;
  end

  // Vector RF: BRAM-banked
  logic [W-1:0] banks [BANKS-1:0]
                         [NUM_WARPS-1:0]
                         [NUM_LANES/BANKS-1:0]
                         [0:VREG_COUNT-1];

  // Read port per lane
  genvar lane;
  generate
    for (lane = 0; lane < NUM_LANES; lane++) begin
      wire [$clog2(BANKS)-1:0] bk = lane % BANKS;
      wire [$clog2(NUM_LANES/BANKS)-1:0] idx = lane / BANKS;
      wire [$clog2(VREG_COUNT)-1:0] addr = v_raddrs[lane*$clog2(VREG_COUNT) +: $clog2(VREG_COUNT)];
      assign v_rdata[lane*W +: W] = v_ren[lane] ? banks[bk][v_rrwarp][idx][addr] : '0;
    end
  endgenerate

  // Write broadcast across banks
  always_ff @(posedge clk) begin
    if (v_wen) begin
      for (int b = 0; b < BANKS; b++) begin
        banks[b][v_wwarp][v_wlane/BANKS][v_waddr] <= v_wdata;
      end
    end
  end

endmodule

