// FILE: mesh_router.sv
// Minimal 2D mesh-like router template for small NoC (parameterized node count and flit width)
module mesh_router #(parameter NODES = 6, FLIT_WIDTH = 64) (
  input  logic                  clk,
  input  logic                  rst_n
  // For template: provide aggregated in/out arrays when integrating
);

  // Simple round-robin crossbar: accept flit from one node and broadcast to all (toy)
  typedef struct packed {
    logic [FLIT_WIDTH-1:0]  data;
    logic                   valid;
    logic                   last;
    logic [$clog2(NODES)-1:0] dest; // destination id
  } flit_t;

  flit_t in_flits [NODES];
  flit_t out_flits [NODES];

  // router arbiter - round robin for demonstration
  logic [$clog2(NODES)-1:0] rr_ptr;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr_ptr <= 0;
      integer j; for (j=0;j<NODES;j++) out_flits[j].valid <= 0;
    end else begin
      // simple scan
      integer k;
      for (k=0;k<NODES;k++) begin
        if (in_flits[k].valid) begin
          out_flits[in_flits[k].dest] <= in_flits[k];
          in_flits[k].valid <= 0;
        end
      end
    end
  end

  // Note: real router would have per-port input FIFOs, VC, flow control, credits, XY routing, etc.
endmodule

