################################################################################
##
## Copyright (c) 2026 Buzz Pendarvis
##
## Filename: Makefile
## Project: CoreVid
## Description: Runs wb_uart tests
## 
################################################################################

SBY_SCRIPT := wb_uart.sby

.PHONY: all clean formal

all: formal

clean: 
	rm -rf wb_uart/

formal: $(SBY_SCRIPT)
	sby -f $(SBY_SCRIPT)