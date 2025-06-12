
`timescale 1ns/1ps

module cuda_thread_regfile (
    input  logic         clk,
    input  logic         rst,

    // Write port
    input  logic         write_en,
    input  logic [4:0]   write_addr,
    input  logic [31:0]  write_data,
    input  logic         write_is_float,  // 1 for float, 0 for int

    // Read port 1
    input  logic [4:0]   read_addr1,
    output logic [31:0]  read_data1,
    output logic         read_is_float1,

    // Read port 2
    input  logic [4:0]   read_addr2,
    output logic [31:0]  read_data2,
    output logic         read_is_float2
);

    typedef struct packed {
        logic [31:0] data;
        logic        is_float;
    } reg_entry_t;

    reg_entry_t regfile [0:31];

    // Write logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            foreach (regfile[i]) begin
                regfile[i].data     <= 32'b0;
                regfile[i].is_float <= 1'b0;
            end
        end else if (write_en && |write_addr) begin
            regfile[write_addr].data     <= write_data;
            regfile[write_addr].is_float <= write_is_float;
        end
    end

    // Read logic (combinational)
    assign read_data1     = regfile[read_addr1].data;
    assign read_is_float1 = regfile[read_addr1].is_float;

    assign read_data2     = regfile[read_addr2].data;
    assign read_is_float2 = regfile[read_addr2].is_float;

endmodule
