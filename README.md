# Z80 kernel

A small Unix-like kernel in C (SDCC) for my Z80 board (rev B), plus the monitor that lives in the
ROM (`mon/`, in assembly). On reset the monitor copies itself to high RAM, then you can load a
kernel at 0x0000 from the CF card (`boot`) or over serial (`load` then `run`).

## Building and running

```bash
make                  # build/kernel.bin and build/kernel.ihx
make send-kernel      # send the kernel to the monitor and start it, then serial console
make monitor          # mon/build/monitor.rom
make flash-monitor    # write the ROM with the TL866 (minipro)
make send-monitor     # run a new monitor from RAM, to test it without flashing
make serial           # just the serial console (Ctrl-] to quit)
make fmt              # format the asm sources (fmt-check to only check)
make hooks            # run fmt-check before each commit (once per clone)
```

The serial port is shared by the NAS on `tower:7023` (ser2net, over Tailscale). If the board is
plugged into the Mac instead, set `Z80_PORT=/dev/cu.usbserial-XXXX`.

## Monitor commands

```
help    list the commands
list    files at the root of the CF card (Fuzix file system)
load    receive an Intel HEX file and write it to RAM
run     jump to 0x0000 (a ret comes back to the prompt)
boot    load kernel.bin from the CF card at 0x0000 and jump to it
```

## Kernel layers

The C sources are split in three directories, and what matters is who includes whom:

```
core/      the kernel itself       includes only core/
dev/       generic chip drivers    includes only dev/, plus "board.h" by name
platform/  this board              includes core/, dev/ and platform/
```

`platform/` is the only layer that knows the other two. It is the glue: it decides that the console
is SIO channel A at 115200, which CTC channel ticks, and where each chip's entries sit in the IM 2
table. Porting to another board means rewriting `platform/` only.

Calls still go both ways, through prototypes that a layer declares and `platform/` defines:

- `core/` declares what it needs from the board (`kputchar` in `core/kprintf.h`, `console_init` and
  `kgetchar` in `core/console.h`, `plt_timer_init` in `core/timer.h`).
- A driver declares the hooks it calls back (`plt_sio_set_speed` in `dev/sio.h`). Values the board
  chooses, like the SIO's interrupt vector, are passed as parameters instead.
- Port addresses can't be parameters, since `__sfr __at` must be known at compile time. A driver
  includes `"board.h"` with no directory, and lists in its header the names it expects there.
  `-I$(BOARD)` in the Makefile makes that name point to `platform/board.h`. The editor (clangd)
  reads `compile_flags.txt` instead of the Makefile, so it carries the same `-I`.

Booting the console, for instance: `main` (core) calls `console_init` (platform), which calls
`sio_init(SIO_115200, SIO_VECTOR)` (dev), which calls back `plt_sio_set_speed` (platform) to program
the CTC.

## Memory map

512 KB of RAM in 8 banks of 64 KB. 0x0000-0xBFFF shows the bank selected in the latch (port 0x38,
bits 1-3), and 0xC000-0xFFFF is always bank 0. When ROM_DIS (bit 0 of the latch) is 0, the first
32 KB of the ROM hide the RAM at 0x0000-0x7FFF. Everything below happens in bank 0.

![Memory map at the three steps of the boot](docs/memmap.svg)

**1. Reset.** The latch is cleared, so the ROM is at 0x0000 and the Z80 starts there. `vectors.s`
copies `l__CODE` bytes from 0x0100 to `s__CODE` (0xE000) and jumps to `init`.

**2. Monitor running in RAM.** `init` runs from 0xE000. It sets the stack at the top of RAM,
disables the ROM (RAM at 0x0000 from now on), writes the two vectors again in RAM, and sets up the
CTC, the SIO and the CF card. `CODE_ADDR` and `DATA_ADDR` are set in `mon/Makefile`.

**3. Kernel started.** `boot` reads `kernel.bin` block by block from 0x0000 and gives up if it
would go past 0xDFFF. `load` just writes wherever the HEX file says, it doesn't check anything. Both
end with `jp 0x0000`, with interrupts off, bank 0, the SIO at 115200 8N1 and the CF card in 8-bit
mode. There's no way back to the monitor except a reset.

The figure is drawn by `tools/memmap.py` with the SVG kit of the book (`docs/explications/fig.py` in
z80-motherboard). It reads the sizes from `mon/build/monitor.map` and `build/kernel.bin`, so run it
again after `make` and `make monitor` when they change.
