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
TESTS := $(wildcard cores/*/test)
ALL := $(DOCS) $(TESTS)

.PHONY: all, clean, docs, tests

all: docs tests

clean: $(ALL)/Makefile
	for dir in $(ALL); do \
		$(MAKE) -C $$dir clean; \
	done

docs: $(DOCS)/Makefile
	for dir in $(DOCS); do \
		$(MAKE) -C $$dir; \
	done

tests: $(TESTS)/Makefile
	for dir in $(TESTS); do \
		$(MAKE) -C $$dir; \
	done