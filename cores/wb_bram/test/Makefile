################################################################################
##
## Copyright (c) 2026 Buzz Pendarvis
##
## Filename: Makefile
## Project: CoreVid
## Description: Runs wb_bram tests
## 
################################################################################

SBY_SCRIPT := wb_bram.sby

.PHONY: all clean formal

all: formal

clean: 
	rm -rf wb_bram

formal: $(SBY_SCRIPT)
	sby -f $(SBY_SCRIPT)