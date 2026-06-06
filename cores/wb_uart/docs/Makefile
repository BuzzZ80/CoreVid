################################################################################
##
## Copyright (c) 2026 Buzz Pendarvis
##
## Filename: Makefile
## Project: CoreVid
## Description: Builds the documentation for wb_uart, from a .typ to a .pdf
##     using typst
## 
################################################################################

.PHONY: all clean
all: wb_uart.pdf
clean:

wb_uart.pdf: wb_uart.typ
	typst compile --format pdf $< $@