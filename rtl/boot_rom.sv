// FILE: boot_rom.sv
// Small boot ROM to store initial firmware/bootloader instructions/data
module boot_rom #(
  parameter ADDR_W=12, // 4KB bootrom
  parameter DATA_W=32
)(
  input logic [ADDR_W-1:0] addr,
  output logic [DATA_W-1:0] data
);
  // small ROM init (for template we return addr)
  assign data = { { (DATA_W-32){1'b0} }, addr };
endmodule
