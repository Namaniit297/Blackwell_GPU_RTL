// FILE: mmu_top.sv
// Simple MMU top that forwards lookups to a TLB instance
module mmu_top #(
  parameter ADDR_WIDTH = 40,
  parameter VPN_WIDTH = 24,
  parameter PPN_WIDTH = 24
)(
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   translate_req,
  input  logic [ADDR_WIDTH-1:0]  vaddr,
  output logic                   translate_ready,
  output logic                   hit,
  output logic [ADDR_WIDTH-1:0]  paddr
);

  // instantiate TLB
  tlb #(.VPN_WIDTH(VPN_WIDTH), .PPN_WIDTH(PPN_WIDTH)) u_tlb (
    .clk(clk), .rst_n(rst_n),
    .req(translate_req), .vaddr(vaddr),
    .ready(translate_ready), .hit(hit), .paddr(paddr)
  );

endmodule

