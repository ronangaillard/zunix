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
