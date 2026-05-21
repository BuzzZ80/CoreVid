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
    parameter integer FIFO_SIZE = 4, // depth is 2**FIFO_SIZE
    parameter [15:0] DEFAULT_DIVISOR = 641 // default is 9600 baud for 100MHz
) (
    // Wishbone interface
    input wire i_clk,
    input wire i_rst,
    input wire i_cyc,
    input wire i_stb,
    input wire i_we,
    output reg o_ack,
    output reg o_rty,
    input wire [7 : 0] i_dat,
    output reg [7 : 0] o_dat,
    input wire [1:0] i_adr,

    // UART interface
    input wire i_uart_rx,
    output reg o_uart_tx
);
    // control/status registers
    reg [15:0] divisor; // baud = clock/(16*divisor)
    reg [7:0] status;
    
    // RX-related signals
    reg rx_full;
    reg rx_empty;
    // rp and wp are one bit larger than the fifo's address size so that the full fifo can be used
    reg [FIFO_SIZE : 0] rx_fifo_rp; // read pointer
    reg [FIFO_SIZE : 0] rx_fifo_wp; // write pointer
    reg [7:0] rx_fifo [0 : 2**FIFO_SIZE - 1];
    reg [19:0] rx_clock_counter; // number of i_clk cycles until next sample
    reg [3:0] rx_bit_counter; // number of bits remaining to be received
    reg [7:0] rx_buffer; // serial to parallel shift register
    reg rx_busy; // used by state machine to determine when it's ready for new input

    // TX-related signals
    reg tx_full;
    reg tx_empty;
    // rp and wp are one bit larger than the fifo's address size so that the full fifo can be used
    reg [FIFO_SIZE : 0] tx_fifo_rp; // read pointer
    reg [FIFO_SIZE : 0] tx_fifo_wp; // write pointer
    reg [7:0] tx_fifo [0 : 2**FIFO_SIZE - 1];
    reg [19:0] tx_clock_counter; // number of i_clk cycles until next tx transition
    reg [3:0] tx_bit_counter; // number of bits to be transmitted
    reg [8:0] tx_buffer; // parallel to serial shift register
    reg tx_busy;

    // Wishbone interface logic
    always @ (*) begin
        // ack/rty response to write access
        if (i_cyc && i_stb && i_we) begin
            o_ack = (i_adr == 0) ? !tx_full : 1;
            o_rty = (i_adr == 0) ? tx_full : 1;
        end
        // ack/rty response to read access
        else if (i_cyc && i_stb && !i_we) begin
            o_ack = (i_adr == 0) ? !rx_empty : 1;
            o_rty = (i_adr == 0) ? rx_empty : 1;
        end
        else begin
            o_ack = 0;
            o_rty = 0;
        end
        
        // sets o_dat for reads (doesn't care if it's even being requested)
        case (i_adr)
            0: o_dat = rx_fifo[rx_fifo_rp[FIFO_SIZE - 1 : 0]];
            1: o_dat = status;
            2: o_dat = divisor[7:0];
            3: o_dat = divisor[15:8];
        endcase
    end
    always @ (posedge i_clk)
        if (i_rst) begin
            divisor <= DEFAULT_DIVISOR;
        end
    
    // RX logic
    always @ (*) begin
        // fifo is full if all but the MSB are the same (indicating wp wrapped around)
        rx_full = (rx_fifo_rp ^ rx_fifo_wp) == {1'b1, {FIFO_SIZE {1'b0}}};
        // it's empty if the pointers are exactly identical.
        rx_empty = rx_fifo_rp == rx_fifo_wp;
    end
    always @ (posedge i_clk) begin
        if (i_rst) begin
            rx_fifo_rp <= 0;
            rx_fifo_wp <= 0;
            rx_clock_counter <= 0;
            rx_bit_counter <= 0;
            rx_buffer <= 0;
            rx_busy <= 0;
        end
        // handles read requests from wishbone bus
        else if (i_cyc && i_stb && !i_we) begin
            // only need to increment read pointer if reading data from addr 0
            // and if there's data available
            if (i_adr == 0 && !rx_empty) rx_fifo_rp <= rx_fifo_rp + 1;
        end
        
        // busy flag indicates rx is in the middle of receiving a word
        if (rx_busy) begin
            // if all counters have run out, exit to waiting mode
            if (rx_clock_counter == 0 && rx_bit_counter == 0) begin
                rx_busy <= 0;
                
                // also enqueue rx_buffer, which has not sampled the stop bit
                rx_fifo[rx_fifo_wp[FIFO_SIZE - 1 : 0]] <= rx_buffer;
                rx_fifo_wp <= rx_fifo_wp + 1;
            end
            // else, transmission is not over - sample when the timer runs out,
            // reset the timer, and count down the number of bits
            else if (rx_clock_counter == 0) begin
                rx_buffer <= {i_uart_rx, rx_buffer[7:1]};
                rx_clock_counter <= {divisor, 4'b1111};
                rx_bit_counter <= rx_bit_counter - 1;
            end
            // otherwise, just keep counting down the clocks
            else begin
                rx_clock_counter <= rx_clock_counter - 1;
            end
        end
        // waiting for incoming data on rx line
        else if (i_uart_rx) begin
            // wait half the time of one bit the first time, to sample in the middle of each bit
            rx_clock_counter <= {divisor, 4'b1111} >> 1;
            rx_bit_counter <= 9;
            rx_busy <= 1;
        end
    end
    
    // TX logic
    always @ (*) begin
        // fifo is full if all but the MSB are the same (indicating wp wrapped around)
        tx_full = (tx_fifo_rp ^ tx_fifo_wp) == {1'b1, {FIFO_SIZE {1'b0}}};
        // it's empty if the pointers are exactly identical.
        tx_empty = tx_fifo_rp == tx_fifo_wp;
        
        o_uart_tx = tx_buffer[0];
    end
    always @ (posedge i_clk) begin
        if (i_rst) begin
            tx_fifo_rp <= 0;
            tx_fifo_wp <= 0;
            tx_clock_counter <= 0;
            tx_bit_counter <= 0;
            tx_buffer <= 0;
            tx_busy <= 0;
        end
        // handles write requests from wishbone bus
        else if (i_cyc && i_stb && i_we) begin
            case (i_adr)
                // writes to TX fifo only if there's space available
                0: if (!tx_full) begin
                    tx_fifo_wp <= tx_fifo_wp + 1;
                    tx_fifo[tx_fifo_wp[FIFO_SIZE - 1 : 0]] <= i_dat;
                end
                // 1: do nothing, there are no control flags
                2: divisor[7:0] <= i_dat;
                3: divisor[15:8] <= i_dat;
            endcase
        end
        
        // Busy flag indicates that FSM is running
        if (tx_busy) begin
            // if all timers run out, get ready to send next byte
            if (tx_clock_counter == 0 && tx_bit_counter == 0) begin
                tx_busy <= 0;
            end
            // if just the clock timer has run out but there are more bits to send
            else if (tx_clock_counter == 0) begin
                tx_buffer <= tx_buffer >> 1;
                tx_clock_counter <= {divisor, 4'b1111};
                tx_bit_counter <= tx_bit_counter - 1;
            end
            else begin
                // run clock divider
                tx_clock_counter <= tx_clock_counter - 1;
            end
        end
        // If not currently busy, attempt to start a new transmission
        else if (!tx_empty) begin
            tx_fifo_rp <= tx_fifo_rp + 1;
            tx_clock_counter <= {divisor, 4'b1111};
            tx_bit_counter <= 9;
            tx_buffer <= {tx_fifo[tx_fifo_rp], 1'b1}; // byte and start bit
            tx_busy <= 1;
        end
    end
endmodule