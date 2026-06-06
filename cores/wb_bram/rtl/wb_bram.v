////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (c) 2026 Buzz Pendarvis
//
// Filename: wb_bram
// Project: CoreVid
// Description: Wishbone wrapper for an FPGA's BRAM. Uses pipelined
//     wishbone bus, since this fits well with BRAMs' synchronous
//     access
//
////////////////////////////////////////////////////////////////////////////////

module wb_bram(
    parameter integer DATA_SIZE_IN_BYTES = 4,
    parameter integer ADDRESS_SIZE = 10
) (
    // Wishbone interface
    input wire i_clk,
    // input wire i_rst, // not needed
    input wire i_cyc,
    input wire i_stb,
    input wire [DATA_SIZE_IN_BYTES - 1 : 0] i_sel,
    input wire i_we,
    output reg o_ack,
    input wire [8 * DATA_SIZE_IN_BYTES - 1 : 0] i_dat,
    output reg [8 * DATA_SIZE_IN_BYTES - 1 : 0] o_dat,
    input wire [ADDRESS_SIZE - 1 : 0] i_adr
)
    localparam DATA_SIZE = 8 * DATA_SIZE_IN_BYTES;
    localparam NUM_WORDS = 2**ADDRESS_SIZE;

    reg [DATA_SIZE - 1 : 0] bram [0 : NUM_WORDS - 1];
    
    integer i;
    // Synchronous write to BRAM, with byte-enable
    always @ (posedge i_clk) begin
        for (i = 0; i < DATA_SIZE_IN_BYTES; i = i + 1) begin
            if (i_cyc && i_stb && i_sel[i] && i_we) 
                bram[i_adr][8 * i +: 8] <= i_dat[8 * i +: 8];
        end
    end

    // Synchronous read to BRAM
    always @ (posedge i_clk) begin
        if (i_cyc && i_stb && !i_we) begin
            o_dat <= bram[i_adr];
        end
    end

    // Wait states are never inserted, errors never occur, so ACK can
    // simply be asserted whenever an access occurs, on the next
    // cycle according to the pipelined handshaking protocol
    always @ (posedge i_clk) begin
        o_ack <= i_cyc && i_stb
    end
endmodule