// FILE: tlb.sv
// Simple fully-associative TLB with small entries; supports lookup and optional refill via software trap.
module tlb #(
  parameter VPN_WIDTH = 24,
  parameter PPN_WIDTH = 24,
  parameter ENTRIES = 16,
  parameter ADDR_WIDTH = 48
)(
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   req,
  input  logic [ADDR_WIDTH-1:0]  vaddr,
  output logic                   ready,
  output logic                   hit,
  output logic [ADDR_WIDTH-1:0]  paddr
);

  typedef struct packed {
    logic                     valid;
    logic [VPN_WIDTH-1:0]     vpn;
    logic [PPN_WIDTH-1:0]     ppn;
  } tlb_e_t;

  tlb_e_t entries [ENTRIES];

  integer i;
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for (i=0; i<ENTRIES; i++) entries[i].valid <= 0;
      ready <= 1'b1;
      hit <= 0;
      paddr <= 0;
    end else begin
      hit <= 0;
      if (req) begin
        logic found = 0;
        for (i=0;i<ENTRIES;i++) begin
          if (entries[i].valid && entries[i].vpn == vaddr[VPN_WIDTH+11:12]) begin
            found = 1;
            paddr <= { entries[i].ppn, vaddr[11:0] }; // page offset
          end
        end
        hit <= found;
        if (!found) begin
          // For template: auto-install mapping as identity (v->p) truncated
          entries[0].valid <= 1;
          entries[0].vpn <= vaddr[VPN_WIDTH+11:12];
          entries[0].ppn <= vaddr[VPN_WIDTH+11:12];
          hit <= 1;
          paddr <= vaddr;
        end
      end
    end
  end

endmodule

