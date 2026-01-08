// FILE: axi_crossbar.sv
// Minimal AXI-lite crossbar for control path + simple data path arbitration.
// Supports up to M masters (masters are initiators) and N slaves (slaves are targets).
module axi_crossbar #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter M = 2, // number of master ports (e.g., host + DMA)
  parameter S = 4  // number of slave ports (e.g., cfg, mmu, periph, mem)
)(
  input  logic                      clk,
  input  logic                      rst_n,
  // For simplicity: single multiplexed write/read per master per cycle (AXI-lite-like)
  input  logic [M-1:0]              m_awvalid,
  input  logic [M*ADDR_W-1:0]       m_awaddr,
  input  logic [M-1:0]              m_wvalid,
  input  logic [M*DATA_W-1:0]       m_wdata,
  output logic [M-1:0]              m_bvalid,
  input  logic [M-1:0]              m_bready,
  input  logic [M-1:0]              m_arvalid,
  input  logic [M*ADDR_W-1:0]       m_araddr,
  output logic [M*DATA_W-1:0]       m_rdata,
  output logic [M-1:0]              m_rvalid,

  // Slave side
  output logic [S-1:0]              s_awvalid,
  output logic [S*ADDR_W-1:0]       s_awaddr,
  output logic [S-1:0]              s_wvalid,
  output logic [S*DATA_W-1:0]       s_wdata,
  input  logic [S-1:0]              s_bvalid,
  output logic [S-1:0]              s_bready,
  output logic [S-1:0]              s_arvalid,
  output logic [S*ADDR_W-1:0]       s_araddr,
  input  logic [S*DATA_W-1:0]       s_rdata,
  input  logic [S-1:0]              s_rvalid
);

  // Address decoding policy (simple fixed ranges). In a real system make this programmable.
  function automatic int decode (input logic [ADDR_W-1:0] addr);
    if (addr >= 32'h0000_0000 && addr < 32'h1000_0000) decode = 0; // slave0: cfg
    else if (addr >= 32'h1000_0000 && addr < 32'h2000_0000) decode = 1; // slave1: mmu
    else if (addr >= 32'h2000_0000 && addr < 32'h8000_0000) decode = 2; // slave2: mem
    else decode = S-1;
  endfunction

  // Round-robin arbitration for masters requests: service requests one-by-one
  int m_idx;
  logic [M-1:0] pending_aw, pending_w, pending_ar;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_idx <= 0;
      pending_aw <= '0; pending_w <= '0; pending_ar <= '0;
      s_awvalid <= '0; s_wvalid <= '0; s_arvalid <= '0;
      s_bready <= '0;
      m_bvalid <= '0; m_rvalid <= '0;
    end else begin
      // collect incoming requests
      for (int i=0;i<M;i++) begin
        if (m_awvalid[i]) pending_aw[i] <= 1;
        if (m_wvalid[i])  pending_w[i]  <= 1;
        if (m_arvalid[i]) pending_ar[i] <= 1;
      end

      // serve one AW/W/AR if pending
      // write address+data combined: find first master with pending request
      integer served = -1;
      for (int j=0;j<M;j++) begin
        int idx = (m_idx + j) % M;
        if (pending_aw[idx] && pending_w[idx]) begin
          // decode address
          logic [ADDR_W-1:0] addr = m_awaddr[ADDR_W*idx +: ADDR_W];
          int s = decode(addr);
          // forward to slave
          s_awvalid[s] <= 1;
          s_awaddr[s*ADDR_W +: ADDR_W] <= addr;
          s_wvalid[s] <= 1;
          s_wdata[s*DATA_W +: DATA_W] <= m_wdata[DATA_W*idx +: DATA_W];
          // mark serviced
          pending_aw[idx] <= 0; pending_w[idx] <= 0;
          m_idx <= idx + 1;
          served = idx;
          break;
        end
      end
      // ack bvalid when slave asserts bvalid
      for (int si=0; si<S; si++) begin
        if (s_bvalid[si]) begin
          // return to calling master — naive: match last serviced master
          int resp_master = (m_idx + M -1) % M;
          m_bvalid[resp_master] <= 1;
          s_bready[si] <= 1;
        end else s_bready[si] <= 0;
      end
      // read handling
      for (int j=0;j<M;j++) begin
        int idx = (m_idx + j) % M;
        if (pending_ar[idx]) begin
          logic [ADDR_W-1:0] addr = m_araddr[ADDR_W*idx +: ADDR_W];
          int s = decode(addr);
          s_arvalid[s] <= 1;
          s_araddr[s*ADDR_W +: ADDR_W] <= addr;
          pending_ar[idx] <= 0;
          m_idx <= idx + 1;
          break;
        end
      end
      // deliver reads
      for (int si=0; si<S; si++) begin
        if (s_rvalid[si]) begin
          int resp_master = (m_idx + M -1) % M;
          m_rdata[DATA_W*resp_master +: DATA_W] <= s_rdata[si*DATA_W +: DATA_W];
          m_rvalid[resp_master] <= 1;
        end
      end

      // clear slave valid signals when not driven
      for (int si=0; si<S; si++) begin
        if (!s_awvalid[si]) s_awvalid[si] <= 0;
        if (!s_wvalid[si]) s_wvalid[si] <= 0;
        if (!s_arvalid[si]) s_arvalid[si] <= 0;
      end

      // clear master response flags when consumer ready
      for (int mi=0; mi<M; mi++) begin
        if (m_bready[mi]) m_bvalid[mi] <= 0;
        if (m_rvalid[mi]) m_rvalid[mi] <= 0; // in real design only when master reads
      end
    end
  end

endmodule
