// FILE: sm_top.sv
// Streaming Multiprocessor top (instantiates SM box, thread scheduler, caches, etc)
module sm_top #(parameter ID=0) (
  input logic clk, rst_n
);
  // local structures
  sm_box #(.ID(ID)) u_sm_box (.clk(clk), .rst_n(rst_n));
endmodule

