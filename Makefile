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

ROM_CHIP   ?= SST39SF040
ROM_COPIES ?= 4

monitor: $(BUILD)/monitor.rom

$(BUILD)/monitor.rel: monitor.s
	mkdir -p $(BUILD)
	sdasz80 -plosgff -o $@ $<

$(BUILD)/monitor.ihx: $(BUILD)/monitor.rel
	sdldz80 -i $@ $<

$(BUILD)/monitor.bin: $(BUILD)/monitor.ihx
	makebin -p $< $@

# 	On rev A board A17 and A18 are left floating, so we need to 
#	copy the monitor at 4 different places so that A17 and A18 don't bother
#	This is fixed in rev B, so once I receive revB this is not needed anymore
$(BUILD)/monitor.rom: $(BUILD)/monitor.bin
	python3 -c "import sys; d = open(sys.argv[1], 'rb').read(); \
	assert len(d) <= 0x20000, 'monitor > 128 KB'; \
	open(sys.argv[2], 'wb').write((d + b'\xff' * (0x20000 - len(d))) * $(ROM_COPIES))" $< $@
	@echo "$@: $$(wc -c < $<) bytes of code, image for $(ROM_CHIP)"

flash-monitor: $(BUILD)/monitor.rom
	minipro -p "$(ROM_CHIP)" -w $<

# 	Sends the new build to the monitor and then runs it 
SEND ?= tools/monitor-send.py

send-monitor: $(BUILD)/monitor.ihx
	python3 $(SEND) $<

# 	Serial console only (resets the board: to keep a program in RAM, stay in send-monitor)
serial:
	python3 $(SEND)

.PHONY: monitor flash-monitor send-monitor serial

# 	Formatter for the assembly sources (tools/asmfmt)
ASMFMT  := tools/asmfmt/asmfmt
ASM_SRC := $(wildcard *.s *.inc)

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
