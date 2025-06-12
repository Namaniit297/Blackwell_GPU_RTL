//****************************************************************************** 
// Copyright (c)
// Indian Institute of Science, Bangalore. All Rights Reserved.
//******************************************************************************

`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module ADD (
    input  [65:0] INPUT_1,
    input  [65:0] INPUT_2,
    input  [2:0]  Rounding_Mode,
    input         SP_DP,     // FLIPPED MEANING: 1 = SP, 0 = DP
    input         ADD_SUB,
    output reg [65:0] OUTPUT,
    output reg        INVALID,
    output reg        OVERFLOW,
    output reg        UNDERFLOW,
    output reg        INEXACT
);

wire [65:0] INPUT_1_DP;
wire [65:0] INPUT_2_DP;
wire [65:0] INPUT_2_DP_NEG;
wire [65:0] OUTPUT_DP;

wire [33:0] INPUT_1_SP;
wire [33:0] INPUT_2_SP;
wire [33:0] INPUT_2_SP_NEG;
wire [33:0] OUTPUT_SP;

wire INEXACT_SP;
wire INEXACT_DP;

// ----------- Assignments (SP_DP = 1 => SP, 0 => DP) -----------

assign INPUT_1_SP     = SP_DP ? INPUT_1[33:0] : 34'b0;
assign INPUT_2_SP     = SP_DP ? INPUT_2[33:0] : 34'b0;
assign INPUT_2_SP_NEG = SP_DP ? {INPUT_2_SP[33:32], INPUT_2_SP[31] ^ 1'b1, INPUT_2_SP[30:0]} : 34'b0;

assign INPUT_1_DP     = ~SP_DP ? INPUT_1 : 66'b0;
assign INPUT_2_DP     = ~SP_DP ? INPUT_2 : 66'b0;
assign INPUT_2_DP_NEG = ~SP_DP ? {INPUT_2[65:64], INPUT_2[63] ^ 1'b1, INPUT_2[62:0]} : 66'b0;

// ----------- Floating Point Adders -----------

(* keep_hierarchy = "yes" *) FPAdd_8_23_comb_uid2 FPADD_SP (
    .X(INPUT_1_SP),
    .Y(ADD_SUB ? INPUT_2_SP_NEG : INPUT_2_SP),
    .RM(Rounding_Mode),
    .R(OUTPUT_SP),
    .INEXACT(INEXACT_SP)
);

(* keep_hierarchy = "yes" *) FPAdd_11_52_comb_uid2 FPADD_DP (
    .X(INPUT_1_DP),
    .Y(ADD_SUB ? INPUT_2_DP_NEG : INPUT_2_DP),
    .RM(Rounding_Mode),
    .R(OUTPUT_DP),
    .INEXACT(INEXACT_DP)
);

// ----------- Output Muxing -----------

always @(*) begin
    if (SP_DP) begin
        OUTPUT <= {32'b0, OUTPUT_SP};
    end else begin
        OUTPUT <= OUTPUT_DP;
    end
end

// ----------- Overflow / Underflow Detection -----------

wire [1:0] EXC_BITS = SP_DP ? OUTPUT_SP[33:32] : OUTPUT_DP[65:64];
wire       EXP_ZERO = SP_DP ? !(|OUTPUT_SP[30:23]) : !(|OUTPUT_DP[62:52]);

always @(*) begin
    INEXACT <= SP_DP ? INEXACT_SP : INEXACT_DP;

    case (EXC_BITS)
        2'b00: begin OVERFLOW <= 0; UNDERFLOW <= 1; end
        2'b01: begin OVERFLOW <= 0; UNDERFLOW <= EXP_ZERO ? 1 : 0; end
        2'b10: begin OVERFLOW <= 1; UNDERFLOW <= 0; end
        default: begin OVERFLOW <= 0; UNDERFLOW <= 0; end
    endcase
end

// ----------- Invalid Operation Detection -----------

wire [1:0] IN_1_EXC_BITS = SP_DP ? INPUT_1[33:32] : INPUT_1[65:64];
wire [1:0] IN_2_EXC_BITS = SP_DP ? INPUT_2[33:32] : INPUT_2[65:64];

wire       IN_1_SNAN_BIT = SP_DP ? INPUT_1[22] : INPUT_1[51];
wire       IN_2_SNAN_BIT = SP_DP ? INPUT_2[22] : INPUT_2[51];

wire       IN_1_SIGN = SP_DP ? INPUT_1[31] : INPUT_1[63];
wire       IN_2_SIGN = SP_DP ? INPUT_2[31] : INPUT_2[63];

always @(*) begin
    if (((IN_1_EXC_BITS == 2'b11) && (IN_1_SNAN_BIT == 1'b0)) ||
        ((IN_2_EXC_BITS == 2'b11) && (IN_2_SNAN_BIT == 1'b0))) begin
        INVALID <= 1;
    end else if ((IN_1_EXC_BITS == 2'b10) && (IN_2_EXC_BITS == 2'b10)) begin
        if (ADD_SUB)
            INVALID <= (IN_1_SIGN == IN_2_SIGN) ? 1 : 0;
        else
            INVALID <= (IN_1_SIGN != IN_2_SIGN) ? 1 : 0;
    end else begin
        INVALID <= 0;
    end
end

endmodule

