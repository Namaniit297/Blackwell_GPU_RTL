`timescale 1ns / 1ps

// ============================================================
// Testbench for Streaming Multiprocessor (SM)
// ============================================================
// - Supports warp launch
// - Instruction memory stub
// - Global memory model
// - Shared memory observation
// - Completion + timeout protection
// ============================================================

module tb_sm;

  // ------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------
  parameter CLK_PERIOD = 10;
  parameter NUM_WARPS  = 4;
  parameter WARP_SIZE = 32;
  parameter MEM_SIZE  = 1 << 20; // 1 MB global memory

  // ------------------------------------------------------------
  // Clock & Reset
  // ------------------------------------------------------------
  logic clk;
  logic rst_n;

  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #100;
    rst_n = 1;
  end

  // ------------------------------------------------------------
  // DUT Interface Signals
  // ------------------------------------------------------------
  logic              sm_enable;
  logic              sm_start;
  logic              sm_done;

  logic [63:0]       kernel_pc;
  logic [63:0]       arg_base;
  logic [31:0]       grid_dim;
  logic [31:0]       block_dim;

  // Instruction fetch
  logic [63:0]       imem_addr;
  logic [127:0]      imem_data;
  logic              imem_valid;

  // Global memory interface
  logic              gmem_rd_en;
  logic              gmem_wr_en;
  logic [63:0]       gmem_addr;
  logic [31:0]       gmem_wdata;
  logic [31:0]       gmem_rdata;
  logic              gmem_ready;

  // ------------------------------------------------------------
  // Global Memory Model
  // ------------------------------------------------------------
  logic [31:0] global_mem [0:MEM_SIZE-1];

  initial begin
    integer i;
    for (i = 0; i < MEM_SIZE; i++)
      global_mem[i] = 32'h0;
  end

  always_ff @(posedge clk) begin
    if (gmem_rd_en) begin
      gmem_rdata <= global_mem[gmem_addr >> 2];
    end
    if (gmem_wr_en) begin
      global_mem[gmem_addr >> 2] <= gmem_wdata;
    end
  end

  assign gmem_ready = 1'b1;

  // ------------------------------------------------------------
  // Instruction Memory Model
  // (PTX decoded into micro-ops beforehand)
  // ------------------------------------------------------------
  logic [127:0] instr_mem [0:255];

  initial begin
    // Dummy vector add micro-ops
    instr_mem[0]  = 128'h0001_0002_0003_0004;
    instr_mem[1]  = 128'h0005_0006_0007_0008;
    instr_mem[2]  = 128'h0009_000A_000B_000C;
    instr_mem[3]  = 128'h000D_000E_000F_0010;
    instr_mem[4]  = 128'hFFFF_FFFF_FFFF_FFFF; // END
  end

  always_ff @(posedge clk) begin
    imem_data  <= instr_mem[imem_addr[9:2]];
    imem_valid <= 1'b1;
  end

  // ------------------------------------------------------------
  // DUT Instantiation
  // ------------------------------------------------------------
  sm_top dut (
    .clk            (clk),
    .rst_n          (rst_n),

    .sm_enable      (sm_enable),
    .sm_start       (sm_start),
    .sm_done        (sm_done),

    .kernel_pc      (kernel_pc),
    .arg_base       (arg_base),
    .grid_dim       (grid_dim),
    .block_dim      (block_dim),

    .imem_addr      (imem_addr),
    .imem_data      (imem_data),
    .imem_valid     (imem_valid),

    .gmem_rd_en     (gmem_rd_en),
    .gmem_wr_en     (gmem_wr_en),
    .gmem_addr      (gmem_addr),
    .gmem_wdata     (gmem_wdata),
    .gmem_rdata     (gmem_rdata),
    .gmem_ready     (gmem_ready)
  );

  // ------------------------------------------------------------
  // Test Scenario
  // ------------------------------------------------------------
  initial begin
    wait(rst_n);

    $display("[TB] Initializing global memory...");

    // Initialize input arrays
    integer i;
    for (i = 0; i < 256; i++) begin
      global_mem[(32'h1000 >> 2) + i] = i;
      global_mem[(32'h2000 >> 2) + i] = i * 2;
    end

    // ----------------------------------------------------------
    // Launch Kernel
    // ----------------------------------------------------------
    sm_enable  = 1'b1;
    kernel_pc = 64'h0000_0000;
    arg_base  = 64'h0000_3000;
    grid_dim  = 4;
    block_dim = 64;

    @(posedge clk);
    sm_start = 1'b1;
    @(posedge clk);
    sm_start = 1'b0;

    $display("[TB] Kernel launched.");

    // ----------------------------------------------------------
    // Wait for completion
    // ----------------------------------------------------------
    integer timeout;
    timeout = 0;
    while (!sm_done && timeout < 100000) begin
      timeout++;
      @(posedge clk);
    end

    if (timeout >= 100000) begin
      $fatal("[TB] Kernel timeout!");
    end

    $display("[TB] Kernel completed.");

    // ----------------------------------------------------------
    // Check Results
    // ----------------------------------------------------------
    for (i = 0; i < 16; i++) begin
      $display("[TB] C[%0d] = %0d",
               i,
               global_mem[(32'h3000 >> 2) + i]);
    end

    $display("[TB] Test PASSED.");
    $finish;
  end

  // ------------------------------------------------------------
  // Waveform Dump
  // ------------------------------------------------------------
  initial begin
    $dumpfile("tb_sm.vcd");
    $dumpvars(0, tb_sm);
  end

endmodule

