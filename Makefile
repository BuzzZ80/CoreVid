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

clean: 
	for dir in $(ALL); do \
		$(MAKE) -C $$dir clean; \
	done

docs: $(DOCS)/Makefile
	$(MAKE) -C $(DOCS)

tests: $(DOCS)/Makefile
	$(MAKE) -C $(TESTS)