# CoreVid

A collection of Verilog cores, centered around the Wishbone bus.

Get it? Like, Wishbone? Like... like Corvids have? And also core? :3

This is a personal project to practice and demonstrate my ability to create
such a system/library in Verilog, as well as write tests and
document core functionality.

# Contents
Each folder within `/cores/` is one core / design, and has the following
file structure:

- `rtl/`: Contains the designs themselves, organized by filename
- `test/`: Contains tests for designs.
- `docs/`: Contains documentation about using each design.

You can run all tests using `make tests`, or build all docs using `make docs`.
Running tests will require SmybiYosys (`sby`), and building docs will require `typst`.

## Cores:

- `wb_uart`: Basic 8-bit UART with configurable clock divisor.
- `wb_bram`: Wishbone wrapper for synchronous Block RAM
