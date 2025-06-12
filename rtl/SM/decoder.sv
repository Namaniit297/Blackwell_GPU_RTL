//==============================================================================
// AGNI V1.0 - General PTX Decoder
//------------------------------------------------------------------------------
// Author       : Naman Kalra
// Copyright    : © 2025 IIT Tirupati
// Description  : Decodes PTX instruction into operands, type flags, and
//                functional unit categories.
//==============================================================================

module ptx_decoder #(
  parameter INST_WIDTH = 32,
  parameter REG_WIDTH  = 5
)(
  input  logic [INST_WIDTH-1:0] instr,

  // Outputs
  output logic [5:0]            opcode,        // opcode or instruction tag
  output logic [REG_WIDTH-1:0]  rd, rs1, rs2,  // register indices
  output logic [15:0]           imm,           // immediate
  output logic                  use_imm,       // if immediate is used

  output logic                  is_scalar_op,  // reg type flags
  output logic                  is_vector_op,

  // FU decoding
  output logic                  is_alu,
  output logic                  is_fpu,
  output logic                  is_lsu,
  output logic                  is_sfu,
  output logic                  is_branch,
  output logic                  valid
);

  // Example PTX encoding for mock-up: [31:26]=opcode, [25:21]=rd, [20:16]=rs1, [15:11]=rs2, [15:0]=imm
  assign opcode = instr[31:26];
  assign rd     = instr[25:21];
  assign rs1    = instr[20:16];
  assign rs2    = instr[15:11];
  assign imm    = instr[15:0];     // reuse for ALU/LSU etc.

  // Basic decoding for opcode → functional unit (example only, customizable)
  always_comb begin
    is_alu       = 0;
    is_fpu       = 0;
    is_lsu       = 0;
    is_sfu       = 0;
    is_branch    = 0;
    use_imm      = 0;
    is_scalar_op = 1;  // default (e.g. SReg)
    is_vector_op = 0;
    valid        = 1;

    unique case (opcode)
      6'h00: begin is_alu = 1; use_imm = 0; end  // add
      6'h01: begin is_alu = 1; use_imm = 1; end  // addi
      6'h02: begin is_fpu = 1; end              // fadd
      6'h03: begin is_fpu = 1; end              // fmul
      6'h04: begin is_lsu = 1; end              // ld
      6'h05: begin is_lsu = 1; end              // st
      6'h06: begin is_branch = 1; end           // bra
      6'h07: begin is_sfu = 1; end              // rsqrt
      6'h08: begin is_alu = 1; is_vector_op = 1; end // vector add
      6'h09: begin is_fpu = 1; is_vector_op = 1; end // vector fmul
      default: valid = 0;
    endcase
  end

endmodule

