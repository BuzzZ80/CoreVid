# CoreVid

A collection of Verilog cores, centered around the Wishbone bus.

Get it? Like, Wishbone? Like... like Corvids have? And also core? :3

This is a personal project to practice and demonstrate my ability to create
such a system/library in Verilog, as well as write tests in Verilator, and
document core functionality.

# Contents
Each folder within `/cores/` is one core / design, and has the following
file structure:

- `rtl/`: Contains the designs themselves, organized by filename
- `tb/`: Contains tests for designs.
- `docs/`: Contains documentation about using each design.

## Cores:

- `wb_uart`: Basic 8-bit UART with configurable clock divisor. 
Baud generated off of wishbone clock.
