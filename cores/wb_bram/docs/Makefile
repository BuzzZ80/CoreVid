################################################################################
##
## Copyright (c) 2026 Buzz Pendarvis
##
## Filename: Makefile
## Project: CoreVid
## Description: Builds the documentation for wb_bram, from a .typ to a .pdf
##     using typst
## 
################################################################################

.PHONY: all clean
all: wb_bram.pdf
clean:

wb_bram.pdf: wb_bram.typ
	typst compile --format pdf $< $@