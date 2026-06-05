#set page(
  paper: "us-letter",
  header: align(right)[
    wb_uart 1
  ],
)
#set text(size: 12pt, font: "DejaVu Sans Mono")

#text(size: 25pt, weight: "bold", [CoreVid #sym.dash.em wb_uart])

#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Features:])
- Wishbone interface for data, control, and status
- One full-duplex asynchronous serial interface
  - 8-bit, no parity, one start and stop bit
  - Runtime-configurable baud rate generator (divides Wishbone clock)
- RX and TX queues
- Generation of multiple kinds of interrupts

#v(2%)
#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Hardware Parameters:])
#table(
  columns: (auto, 1fr),
  [*Name*], [*Description*],
  [FIFO_SIZE], [Used to calculate queue depth. $"Depth" = 2^"FIFO_SIZE"$.],
  [INTERRUPT_THRESHOLD], [Number of entries that constitutes a "majority" of the queue.\ Set to 3/4 of FIFO_SIZE by default.],
  [DEFAULT_DIVISOR], [Value that the baud rate generator's divisor register gets set to on reset.],
)

#v(2%)
#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Registers:])
#table(
  align:center,
  columns: (2.5fr, 1fr, 1fr, 1fr, 1fr, 4fr, 4fr, 4fr, 4fr),
  stroke: (x, y) => if y > 0 {black} else {none},
  [*Address*], table.cell(colspan: 8, [*Bits*]),
  [], [*7*], [*6*], [*5*], [*4*], [*3*], [*2*], [*1*], [*0*],
  [*0*], table.cell(colspan: 8, [RX Queue Read / TX Queue Write]),
  [*1*], table.cell(colspan: 4, [0]), [TX Full], [TX Empty], [RX Full], [RX Empty],
  [*2*], table.cell(colspan: 8, [Divisor (Least Significant Byte)]),
  [*3*], table.cell(colspan: 8, [Divisor (Most Significant Byte)]),
)



#pagebreak()
#set page(
  paper: "us-letter",
  header: align(right)[
    wb_uart 2
  ],
)

#v(2%)
#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Baud Rate Generator:])

The baud rate can be modified at runtime by setting the value of the "Divisor" registers.
On reset, the divisor is set to a specific, hardware-set value.

$
  "Baud Rate" = "Wishbone Clock"/(16 times"Divisor")
$

The factor of 16 is due to the 16x oversampling rate of the RX circuitry.

#v(2%)
#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Interrupts:])

#table(
  columns: (auto, auto),
  [*Signal Name*], [*Description*],
  [o_rx_ready], [Asserted while the RX queue is not empty.],
  [o_rx_almost_full], [Asserted while the RX queue has more than INTERRUPT_THRESHOLD bytes enqueued.],
  [o_rx_full], [Asserted while the RX queue is full.],
  [o_tx_ready], [Asserted while the TX queue is not full.],
  [o_tx_almost_empty], [Asserted while the TX queue has fewer than INTERRUPT_THRESHOLD bytes enqueued],
  [o_tx_empty], [Asserted while TX queue is empty.],
)

#pagebreak()
#set page(
  paper: "us-letter",
  header: align(right)[
    wb_uart 3
  ],
)

#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Wishbone Datasheet:])
#table(
  align: left,
  columns: (1fr, 2fr),
  [Revision], [4B],
  [Interface Type], [Slave],
  [Signal names], [#table(
    stroke: none,
    align: center,
    columns: (5fr, 1fr, 5fr),
    [*CoreVid Name*], [], [*WB Name*],
    [i_clk], [#sym.arrow.l.r.long], [CLK_I],
    [i_rst], [#sym.arrow.l.r.long], [RST_I],
    [i_cyc], [#sym.arrow.l.r.long], [CYC_I],
    [i_stb], [#sym.arrow.l.r.long], [STB_I],
    [i_we], [#sym.arrow.l.r.long], [WE_I],
    [o_ack], [#sym.arrow.l.r.long], [ACK_O],
    [o_rty], [#sym.arrow.l.r.long], [RTY_O],
    [i_dat], [#sym.arrow.l.r.long], [DAT_I()],
    [o_dat], [#sym.arrow.l.r.long], [DAT_O()],
    [i_adr], [#sym.arrow.l.r.long], [ADR_I()],
  )],
  [RTY signal function], [
    On a read, this indicates that the RX queue is empty. \
    On a write, this indicates that the TX queue is full.
  ],
  [Port size \ Port granularity \ Maximum operand size], [8-bit],
  [Data transfer ordering], [BIG/LITTLE ENDIAN],
  [Data transfer sequence],[UNDEFINED],
  [Clock constraints], [None],
)