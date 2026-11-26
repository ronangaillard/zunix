# Kernel in C (SDCC): make builds $(BUILD)/kernel.bin, to be loaded at 0x0000.
# The parent Makefile sets BUILD and runs it in the emulator (make run-kernel there).

# Sources, one directory per layer (see README):
#   core/      the kernel itself, touches no port
#   dev/       drivers
#   platform/  what is specific to this board: entry point, port addresses
# Every .c of these directories is compiled. Headers are included from the kernel root
# (#include "dev/sio.h"), hence -I.
BUILD  ?= build
DIRS   := core dev platform
CSRC   := $(foreach d,$(DIRS),$(wildcard $(d)/*.c))
HDRS   := $(foreach d,$(DIRS),$(wildcard $(d)/*.h))

# crt0 first: the linker places the areas in the order it first sees them
OBJ    := $(BUILD)/platform/crt0.rel $(patsubst %.c,$(BUILD)/%.rel,$(CSRC))

all: $(BUILD)/kernel.bin

$(BUILD)/platform/crt0.rel: platform/crt0.s
	mkdir -p $(dir $@)
	sdasz80 -plosgff -o $@ $<

$(BUILD)/%.rel: %.c $(HDRS)
	mkdir -p $(dir $@)
	sdcc -mz80 --opt-code-size -I. -c -o $@ $<

# crt0 first (vectors at 0x0000), code at 0x0100, data right after it, no C library
$(BUILD)/kernel.bin: $(OBJ)
	sdcc -mz80 --no-std-crt0 --nostdlib --code-loc 0x0100 --data-loc 0 -o $(BUILD)/kernel.ihx $(OBJ)
	makebin -p $(BUILD)/kernel.ihx $@

# sends the kernel to the monitor (load, then run: it starts at 0x0000), then serial console;
# it must end below the monitor (0xE000), which load does not check
send-kernel: $(BUILD)/kernel.bin
	@test $$(wc -c < $<) -le 57344 || { echo "kernel.bin is bigger than 0x0000-0xDFFF"; exit 1; }
	python3 tools/monitor-send.py $(BUILD)/kernel.ihx

.PHONY: all send-kernel

# 	The monitor lives in mon/ (own Makefile)
monitor:
	$(MAKE) -C mon

flash-monitor send-monitor serial:
	$(MAKE) -C mon $(patsubst %-monitor,%,$@)

.PHONY: monitor flash-monitor send-monitor serial

# 	Formatter for the assembly sources (tools/asmfmt)
ASMFMT  := tools/asmfmt/asmfmt
ASM_SRC := $(wildcard platform/*.s platform/*.inc mon/*.s mon/*.inc)

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

# 	Git hook that runs fmt-check on the staged assembly sources before each commit
hooks:
	git config core.hooksPath tools/git-hooks

.PHONY: fmt fmt-check test-asmfmt hooks
