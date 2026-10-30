# Kernel in C (SDCC): make builds $(BUILD)/kernel.bin, to be loaded at 0x0000.
# The parent Makefile sets BUILD and runs it in the emulator (make run-kernel there).

BUILD  ?= build
OBJ    := $(BUILD)/crt0.rel $(patsubst %.c,$(BUILD)/%.rel,$(wildcard *.c))

all: $(BUILD)/kernel.bin

$(BUILD)/crt0.rel: crt0.s
	mkdir -p $(BUILD)
	sdasz80 -plosgff -o $@ $<

$(BUILD)/%.rel: %.c $(wildcard *.h)
	mkdir -p $(BUILD)
	sdcc -mz80 --opt-code-size -c -o $@ $<

# crt0 first (vectors at 0x0000), code at 0x0100, data right after it, no C library
$(BUILD)/kernel.bin: $(OBJ)
	sdcc -mz80 --no-std-crt0 --nostdlib --code-loc 0x0100 --data-loc 0 -o $(BUILD)/kernel.ihx $(OBJ)
	makebin -p $(BUILD)/kernel.ihx $@

.PHONY: all

# 	The monitor lives in mon/ (own Makefile)
monitor:
	$(MAKE) -C mon

flash-monitor send-monitor serial:
	$(MAKE) -C mon $(patsubst %-monitor,%,$@)

.PHONY: monitor flash-monitor send-monitor serial

# 	Formatter for the assembly sources (tools/asmfmt)
ASMFMT  := tools/asmfmt/asmfmt
ASM_SRC := $(wildcard *.s *.inc mon/*.s mon/*.inc)

$(ASMFMT): $(ASMFMT).c
	cc -std=c99 -O2 -Wall -Wextra -pedantic -o $@ $<

fmt: $(ASMFMT)
	$(ASMFMT) $(ASM_SRC)

fmt-check: $(ASMFMT)
	$(ASMFMT) --check $(ASM_SRC)

# 	Each tests/X.in.s must give tests/X.out.s, and formatting X.out.s must change nothing
test-asmfmt: $(ASMFMT)
	@for t in tools/asmfmt/tests/*.in.s; do \
		exp=$${t%.in.s}.out.s; \
		$(ASMFMT) < $$t | diff -u $$exp - || exit 1; \
		$(ASMFMT) --check $$exp || { echo "$$exp: not stable"; exit 1; }; \
	done; echo "asmfmt: all tests pass"

.PHONY: fmt fmt-check test-asmfmt
