################################################################################
##
## Copyright (c) 2026 Buzz Pendarvis
##
## Filename: Makefile
## Project: CoreVid
## Description: Runs tests and builds documentation
## 
################################################################################

DOCS := $(wildcard cores/*/docs)
TESTS := $(wildcard cores/*/tb)
ALL := $(DOCS) $(TESTS)

.PHONY: all, clean, docs, tests

all: docs tests

clean: 
	$(MAKE) clean -C $(DOCS)
	$(MAKE) clean -C $(TESTS)

docs: $(DOCS)/Makefile
	$(MAKE) -C $(DOCS)

tests: $(DOCS)/Makefile
	$(MAKE) -C $(TESTS)