# Kernel in C (SDCC): make builds $(BUILD)/kernel.bin, to be loaded at 0x0000.
# The parent Makefile sets BUILD and runs it in the emulator (make run-kernel there).

# Sources, one directory per layer (see README):
#   core/      the kernel itself, touches no port
#   dev/       drivers
#   platform/  what is specific to this board: entry point, port addresses
# Every .c and .s of these directories is built. Headers are included from the kernel root
# (#include "dev/sio.h"), hence -I.
BUILD  ?= build
DIRS   := core dev platform
CSRC   := $(foreach d,$(DIRS),$(wildcard $(d)/*.c))
ASRC   := $(filter-out platform/crt0.s,$(foreach d,$(DIRS),$(wildcard $(d)/*.s)))
HDRS   := $(foreach d,$(DIRS),$(wildcard $(d)/*.h))

# crt0 first: the linker places the areas in the order it first sees them
OBJ    := $(BUILD)/platform/crt0.rel $(patsubst %.s,$(BUILD)/%.rel,$(ASRC)) \
          $(patsubst %.c,$(BUILD)/%.rel,$(CSRC))

all: $(BUILD)/kernel.bin

$(BUILD)/%.rel: %.s
	mkdir -p $(dir $@)
	sdasz80 -plosgff -o $@ $<

$(BUILD)/%.rel: %.c $(HDRS)
	mkdir -p $(dir $@)
	sdcc -mz80 --opt-code-size -I. -c -o $@ $<

# SDCC's own library for the Z80 (z80.lib), next to the sdcc binary.
LIBZ80 := $(abspath $(dir $(shell command -v sdcc))../share/sdcc/lib/z80)

# crt0 first (vectors at 0x0000), code at 0x0100, data right after it. --nostdlib drops the C
# library that sdcc would add by default; -l z80 adds back only the helpers above.
# -Wl passes the rest of the option to the linker as is: -b _AREA=address sets the base address
# of an area, whatever the link order. In common RAM (see crt0.s): the IM 2 table at 0xC000,
# 256-byte aligned, then _COMMONMEM. The awk line fails the build if the table (l__VECTORS in
# the map, 8 hex digits, compared as text) grew past 256 bytes, onto _COMMONMEM: the linker
# would not complain.
# makebin: -s 65536 since the image now goes up to common RAM (its default is 32 KB), and -p
# cuts it after the last byte used.
$(BUILD)/kernel.bin: $(OBJ) Makefile
	sdcc -mz80 --no-std-crt0 --nostdlib -L $(LIBZ80) -l z80 --code-loc 0x0100 --data-loc 0 \
		-Wl-b_VECTORS=0xC000 -Wl-b_COMMONMEM=0xC100 \
		-o $(BUILD)/kernel.ihx $(OBJ)
	@awk '$$2 == "l__VECTORS" && ($$1 "") > "00000100" { print "_VECTORS is bigger than 256 bytes"; exit 1 }' \
		$(BUILD)/kernel.map
	makebin -p -s 65536 $(BUILD)/kernel.ihx $@

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
