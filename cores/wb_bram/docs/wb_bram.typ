#set page(
  paper: "us-letter",
  header: align(right)[
    wb_bram 1
  ],
)
#set text(size: 12pt, font: "DejaVu Sans Mono")

#text(size: 25pt, weight: "bold", [CoreVid #sym.dash.em wb_bram])

#line(length:100%)
Wishbone wrapper for synchronous Block RAM.

#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Features:])
- Synchronous access for implementation as an FPGA BRAM
- Byte-wide write enable via i_sel[] inputs
- Pipelined wishbone interface for maximum throughput
- Configurable parameters for word size and number of words

#v(2%)
#line(length:100%)
#v(-2%)
#text(size: 18pt, weight: "semibold", [Hardware Parameters:])
#table(
  columns: (auto, 1fr),
  [*Name*], [*Description*],
  [DATA_SIZE_IN_BYTES], [The number of bytes in one word.\ Generally either 1, 2, 4, or 8, corresponding to 8, 16, 32, and 64 bits.],
  [ADDRESS_SIZE], [Number of bits in address i_adr[]. Size of BRAM in words ],
)

#pagebreak()
#set page(
  paper: "us-letter",
  header: align(right)[
    wb_bram 2
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
    [i_sel], [#sym.arrow.l.r.long], [SEL_I()],
    [i_we], [#sym.arrow.l.r.long], [WE_I],
    [o_ack], [#sym.arrow.l.r.long], [ACK_O],
    [o_rty], [#sym.arrow.l.r.long], [RTY_O],
    [i_dat], [#sym.arrow.l.r.long], [DAT_I()],
    [o_dat], [#sym.arrow.l.r.long], [DAT_O()],
    [i_adr], [#sym.arrow.l.r.long], [ADR_I()],
  )],
  [Port size and\ Maximum operand size], [$8 times "DATA_SIZE_IN_BYTES"$],
  [Port granularity], [8-bit],
  [Data transfer ordering], [LITTLE ENDIAN (doesn't actually matter)],
  [Data transfer sequence],[UNDEFINED],
  [Clock constraints], [None],
)

This core uses the pipelined handshaking protocol, and supports block and single transfers.