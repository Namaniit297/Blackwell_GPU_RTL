// FILE: coherence_dir.sv
// Small coherence directory for a few L1 caches (snooping not implemented). Supports basic ownership and invalidation entries.
module coherence_dir #(
  parameter N_LINES = 1024,
  parameter N_SHARERS = 8, // number of L1s
  parameter ADDR_W = 32
)(
  input logic clk, rst_n,
  input logic [ADDR_W-1:0] line_addr,
  input logic cmd_set_owner, // set owner + sharer mask
  input logic [$clog2(N_LINES)-1:0] line_idx,
  input logic [N_SHARERS-1:0] sharer_mask_in,
  output logic [N_SHARERS-1:0] sharer_mask_out
);

  typedef struct packed { logic valid; logic [N_SHARERS-1:0] sharers; logic [$clog2(N_LINES)-1:0] tag; } dir_entry_t;
  dir_entry_t dir [N_LINES];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0;i<N_LINES;i++) dir[i].valid <= 0;
    end else begin
      if (cmd_set_owner) begin
        dir[line_idx].valid <= 1;
        dir[line_idx].sharers <= sharer_mask_in;
      end
      sharer_mask_out <= dir[line_idx].sharers;
    end
  end

endmodule
