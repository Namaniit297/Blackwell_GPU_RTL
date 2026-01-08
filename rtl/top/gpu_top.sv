// FILE: gpu_top.sv
// Top-level GPU integration (connects SMs, L2, NoC/router, DRAM controller, MMU)
module gpu_top #(parameter NUM_SMS = 4, ADDR_WIDTH = 40, DATA_WIDTH = 64)
(
  input  logic                       clk,
  input  logic                       rst_n,
  // CPU/Host control AXI-lite (simple)
  input  logic                       host_awvalid,
  input  logic [31:0]                host_awaddr,
  input  logic                       host_wvalid,
  input  logic [31:0]                host_wdata,
  input  logic                       host_bready,
  output logic                       host_arready,
  output logic [31:0]                host_rdata,
  output logic                       host_rvalid
);

  // Simple interconnect wires (tile-level NoC/AXI stream omitted for brevity)
  // Instantiate mesh router
  mesh_router #(.NODES(NUM_SMS+2), .FLIT_WIDTH(DATA_WIDTH)) u_mesh (
    .clk(clk), .rst_n(rst_n)
    // ports can be added per-SM — for template we keep single aggregated ports
  );

  // L2 bank (single bank here for template)
  l2_bank #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_l2bank (
    .clk(clk), .rst_n(rst_n)
    // memory ports omitted; connect through l2_controller
  );

  // L2 controller
  l2_controller #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_l2ctl (
    .clk(clk), .rst_n(rst_n)
  );

  // DRAM controller (simple model)
  dram_ctrl #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_dram (
    .clk(clk), .rst_n(rst_n)
  );

  // MMU+TLB
  mmu_top #(.ADDR_WIDTH(ADDR_WIDTH)) u_mmu(
    .clk(clk), .rst_n(rst_n)
  );

  // Instantiate multiple SMs
  genvar i;
  generate
    for (i=0; i<NUM_SMS; i++) begin : SMS
      sm_top #(.ID(i)) u_sm (
        .clk(clk), .rst_n(rst_n)
      );
    end
  endgenerate

  // Simple host response defaults
  assign host_arready = 1'b1;
  assign host_rdata = 32'h0;
  assign host_rvalid = 1'b0;

endmodule

