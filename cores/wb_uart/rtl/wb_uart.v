////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (c) 2026 Buzz Pendarvis
//
// Filename: wb_uart
// Project: CoreVid
// Description: Basic 8-bit UART with Wishbone interface.
//   Has configurable baud rate divisor, FIFO, and interrupt generation.
//
////////////////////////////////////////////////////////////////////////////////

module uart #(
    parameter reg FIFO_ENABLED,
    parameter integer FIFO_SIZE // depth is 2**FIFO_SIZE
) (
    // Wishbone interface
    input wire i_clk,
    input wire i_rst,
    input wire i_cyc,
    input wire i_stb,
    output reg o_ack,
    input wire [7 : 0] i_dat,
    output reg [7 : 0] o_dat,
    input wire [1:0] i_adr,

    // UART interface
    input wire i_uart_rx,
    output reg o_uart_tx
)
    reg 
endmodule