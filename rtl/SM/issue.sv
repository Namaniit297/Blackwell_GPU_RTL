//==============================================================================
// AGNI V1.0 – Multi-Thread Issue Unit for 32 CUDA Cores
//------------------------------------------------------------------------------
// Dispatches one warp-wide instruction to its 32 threads, with thread-specific
// operands fetched from vector register file and broadcast to cores.
//==============================================================================

module issue_unit_multi_thread #(
  parameter int NUM_THREADS = 32,
  parameter int REG_WIDTH   = 32,
  parameter int ADDR_WIDTH  = 7
)(
  input  logic clk, rst,

  // From scheduler + decoder
  input  logic [5:0] warp_id,
  input  logic        valid,

  input  logic [ADDR_WIDTH-1:0] rs1_idx, rs2_idx, rd_idx,
  input  logic [15:0]           imm,
  input  logic                 use_imm,
  input  logic                 is_scalar_op,
  input  logic                 is_vector_op,
  input  logic                 is_alu, is_fpu, is_lsu, is_sfu,

  // Read interfaces from regfile
  input  logic [REG_WIDTH-1:0]                     s_r1, s_r2,
  input  logic [NUM_THREADS*REG_WIDTH-1:0]        v_r1, v_r2,

  // Outputs to CUDA cores
  output logic                                    alu_valid,
  output logic [NUM_THREADS*REG_WIDTH-1:0]        alu_op1, alu_op2,
  output logic [NUM_THREADS*5-1:0]                alu_rd_bits,

  output logic                                    fpu_valid,
  output logic [NUM_THREADS*REG_WIDTH-1:0]        fpu_op1, fpu_op2,
  output logic [NUM_THREADS*5-1:0]                fpu_rd_bits,

  output logic                                    lsu_valid,
  output logic [NUM_THREADS*REG_WIDTH-1:0]        lsu_addr, lsu_data,
  output logic [NUM_THREADS*5-1:0]                lsu_rd_bits,
  output logic [NUM_THREADS-1:0]                  lsu_write_en,

  output logic                                    sfu_valid,
  output logic [NUM_THREADS*REG_WIDTH-1:0]        sfu_in,
  output logic [NUM_THREADS*5-1:0]                sfu_rd_bits
);

  // Operation validity broadcasing
  assign alu_valid = valid && is_alu;
  assign fpu_valid = valid && is_fpu;
  assign lsu_valid = valid && is_lsu;
  assign sfu_valid = valid && is_sfu;

  // Operand routing
  genvar t;
  generate
    for (t = 0; t < NUM_THREADS; ++t) begin
      // Scalar: broadcast same value to all threads
      logic [REG_WIDTH-1:0] op1 = is_scalar_op ? s_r1 : v_r1[t*REG_WIDTH +: REG_WIDTH];
      logic [REG_WIDTH-1:0] op2 = is_scalar_op ?
                       (use_imm ? {{16{imm[15]}}, imm} : s_r2) :
                       v_r2[t*REG_WIDTH +: REG_WIDTH];

      assign alu_op1[t*REG_WIDTH +: REG_WIDTH] = op1;
      assign alu_op2[t*REG_WIDTH +: REG_WIDTH] = op2;
      assign fpu_op1[t*REG_WIDTH +: REG_WIDTH] = op1;
      assign fpu_op2[t*REG_WIDTH +: REG_WIDTH] = op2;
      assign lsu_addr[t*REG_WIDTH +: REG_WIDTH] = op1;
      assign lsu_data[t*REG_WIDTH +: REG_WIDTH] = op2;
      assign sfu_in[t*REG_WIDTH +: REG_WIDTH]  = op1;
    end
  endgenerate

  // Generate per-thread RD indices for writeback
  wire [5:0] warp_off = warp_id << 5; // warp_id * 32 threads
  generate
    for (t = 0; t < NUM_THREADS; ++t) begin
      assign alu_rd_bits[t*5 +: 5] = rd_idx;
      assign fpu_rd_bits[t*5 +: 5] = rd_idx;
      assign lsu_rd_bits[t*5 +: 5] = rd_idx;
      assign sfu_rd_bits[t*5 +: 5] = rd_idx;
      assign lsu_write_en[t]        = valid && is_lsu;
    end
  endgenerate

endmodule
