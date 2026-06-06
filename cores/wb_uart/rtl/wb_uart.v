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

module wb_uart #(
    parameter integer FIFO_SIZE = 4, // depth is 2**FIFO_SIZE
    parameter integer INTERRUPT_THRESHOLD = (2**FIFO_SIZE) / 2,
    parameter [15:0] DEFAULT_DIVISOR = 641 // default is 9600 baud for 100MHz
) (
    // Wishbone interface
    input wire i_clk,
    input wire i_rst,
    input wire i_cyc,
    input wire i_stb,
    input wire i_we,
    output reg o_ack,
    output reg o_stall,
    input wire [7 : 0] i_dat,
    output reg [7 : 0] o_dat,
    input wire [1:0] i_adr,

    // interrupts
    output reg o_rx_ready,
    output reg o_rx_almost_full,
    output reg o_rx_full,
    output reg o_tx_ready,
    output reg o_tx_almost_empty,
    output reg o_tx_empty,

    // UART interface
    input wire i_uart_rx,
    output reg o_uart_tx
);
    // Wishbone interface registers for handling pipelining
    reg [7:0] r_i_dat;
    reg [1:0] r_i_adr;
    reg r_i_we;
    reg r_i_stb;

    // control/status registers
    reg [15:0] divisor; // baud = clock/(16*divisor)
    reg [7:0] status;
    
    // rx-related signals
    // rx fifo
    reg rx_full;
    reg rx_empty;
    reg [FIFO_SIZE : 0] rx_fifo_rp; // read pointer
    reg [FIFO_SIZE : 0] rx_fifo_wp; // write pointer
    reg [7:0] rx_fifo [0 : 2**FIFO_SIZE - 1];
    // rx finite state machine
    reg [19:0] rx_clock_counter; // number of i_clk cycles until next sample
    reg [3:0] rx_bit_counter; // number of bits remaining to be received
    reg [7:0] rx_buffer; // serial to parallel shift register
    reg rx_busy; // used by state machine to determine when it's ready for new input

    // TX-related signals
    // tx fifo
    reg tx_full;
    reg tx_empty;
    reg [FIFO_SIZE : 0] tx_fifo_rp; // read pointer
    reg [FIFO_SIZE : 0] tx_fifo_wp; // write pointer
    reg [7:0] tx_fifo [0 : 2**FIFO_SIZE - 1];
    // tx finite state machine
    reg [19:0] tx_clock_counter; // number of i_clk cycles until next tx transition
    reg [3:0] tx_bit_counter; // number of bits to be transmitted
    reg [8:0] tx_buffer; // parallel to serial shift register
    reg tx_busy;

    // Wishbone interface logic
    always @ (posedge i_clk) begin
        if (i_rst || !o_stall) begin
            r_i_dat <= i_dat;
            r_i_adr <= i_adr;
            r_i_we <= i_we;
            r_i_stb <= i_stb && i_cyc;
        end
    end
    always @ (*) begin
        // ack/stall response to write access
        if (r_i_stb && r_i_we) begin
            o_ack = (r_i_adr == 0) ? !tx_full : 1;
            o_stall = (r_i_adr == 0) ? tx_full : 0;
        end
        // ack/stall response to read access
        else if (r_i_stb && !r_i_we) begin
            o_ack = (r_i_adr == 0) ? !rx_empty : 1;
            o_stall = (r_i_adr == 0) ? rx_empty : 0;
        end
        else begin
            o_ack = 0;
            o_stall = 0;
        end
        
        // sets o_dat for reads (doesn't care if it's even being requested)
        case (r_i_adr)
            0: o_dat = rx_fifo[rx_fifo_rp[FIFO_SIZE - 1 : 0]];
            1: o_dat = status;
            2: o_dat = divisor[7:0];
            3: o_dat = divisor[15:8];
        endcase
    end
    
    // status register logic
    always @ (*) begin
        status[0] = rx_empty;
        status[1] = rx_full;
        status[2] = tx_empty;
        status[3] = tx_full;
        status[7:4] = 0;
    end
    
    // interrupt logic
    always @ (*) begin
        o_rx_ready = !rx_empty;
        o_rx_almost_full = (rx_fifo_wp - rx_fifo_rp) > INTERRUPT_THRESHOLD;
        o_rx_full = rx_full;
        
        o_tx_ready = !tx_full;
        o_tx_almost_empty = (tx_fifo_wp - tx_fifo_rp) < (2**FIFO_SIZE - INTERRUPT_THRESHOLD);
        o_tx_empty = tx_full;
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
        else begin
            // handles reads from RX FIFO
            if (r_i_stb && !r_i_we) begin
                // only need to increment read pointer if reading data from addr 0
                // and if there's data available
                if (r_i_adr == 0 && !rx_empty) rx_fifo_rp <= rx_fifo_rp + 1;
            end

            // busy flag indicates rx is in the middle of receiving a word,
            // so writes to the RX buffer are predecated on this
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
            divisor <= DEFAULT_DIVISOR;
            tx_fifo_rp <= 0;
            tx_fifo_wp <= 0;
            tx_clock_counter <= 0;
            tx_bit_counter <= 0;
            tx_buffer <= 0;
            tx_busy <= 0;
        end
        // handles write requests from wishbone bus
        else begin
            if (r_i_stb && r_i_we) begin
                case (r_i_adr)
                    // writes to TX fifo only if there's space available
                    0: if (!tx_full) begin
                        tx_fifo_wp <= tx_fifo_wp + 1;
                        tx_fifo[tx_fifo_wp[FIFO_SIZE - 1 : 0]] <= r_i_dat;
                    end
                    // 1: do nothing, there are no control flags
                    2: divisor[7:0] <= r_i_dat;
                    3: divisor[15:8] <= r_i_dat;
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
    end

    // Formal verification
    `ifdef FORMAL
        reg f_past_valid; // ensures $past works correctly
        integer f_reqs = 0;
        integer f_acks = 0;

        // keep track of requests and acknowledgements
        always @ (posedge i_clk) begin
            if (!o_stall && i_cyc && i_stb) f_reqs <= f_reqs + 1;
            if (!i_rst && o_ack) f_acks <= f_acks + 1;
        end
        // we should never have more acknowledgements than requests
        always @ (*) begin
            if (f_reqs > f_acks) assume(i_cyc);
            assert(f_acks <= f_reqs);
        end

        // Ensures $past() works correctly
        initial f_past_valid = 0;
        always @ (posedge i_clk) f_past_valid <= 1;

        // Asserts clk0 is in reset state
        initial assume(i_rst);
        always @ (posedge i_clk) if (i_rst) begin
            assume(~i_cyc);
        end

        // Wishbone bus properties
        always @ (*) begin
            if (!i_rst && !i_cyc) assert(!o_ack && !o_stall);
        end

        // FIFO properties
        reg [FIFO_SIZE:0] f_tx_num_full; // amount of valid data in TX FIFO
        reg [FIFO_SIZE:0] f_rx_num_full; // amoutn of valid data in RX FIFO
        always @ (posedge i_clk) if (~i_rst)begin
            f_tx_num_full = tx_fifo_wp - tx_fifo_rp;
            f_rx_num_full = rx_fifo_wp - rx_fifo_rp;
            assert(f_tx_num_full <= 2**FIFO_SIZE); // data does not exceed size of FIFO
            assert(f_rx_num_full <= 2**FIFO_SIZE);
        end

        // basic UART properties
        always @ (posedge i_clk) if (~i_rst) begin
            if (f_past_valid && !$past(i_rst) && !tx_busy) assert($stable(o_uart_tx));
        end
    `endif
endmodule