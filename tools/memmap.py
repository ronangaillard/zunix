# Draws docs/memmap.svg, the memory map at the three steps of the boot (README), in the style of the
# memory maps of the book: it uses the book's SVG kit, docs/explications/fig.py in z80-motherboard
# (this repository is os/kernel in it).
#   python3 tools/memmap.py      (after make and make monitor: sizes come from the builds)
#
# Heights follow the sizes (64 KB = the height of a column), with one scale for all the columns, so
# that an address is at the same height everywhere; small intervals get a minimum height to stay
# readable, and the biggest one gives up that room: a dashed cut shows it is drawn shorter.
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
BOOK = os.path.join(ROOT, "..", "..", "docs", "explications")
sys.path.insert(0, BOOK)
try:
    from fig import SVG, C_ADDR, C_INK, C_SOFT
except ImportError:
    sys.exit("cannot find the book's fig.py in %s" % os.path.normpath(BOOK))

# sizes from the builds
mon_map = open(os.path.join(ROOT, "mon", "build", "monitor.map")).read()


def symbol(name):
    return int(re.search(r"([0-9A-F]{8})\s+%s\b" % name, mon_map).group(1), 16)


CODE, CODE_END = symbol("s__CODE"), symbol("s__CODE") + symbol("l__CODE")
DATA, DATA_END = symbol("s__DATA"), symbol("s__DATA") + symbol("l__DATA")
STORED_END = 0x0100 + symbol("l__CODE")            # the code as stored in the ROM
kernel_bin = os.path.join(ROOT, "build", "kernel.bin")
KERNEL_END = os.path.getsize(kernel_bin) if os.path.exists(kernel_bin) else 0x2000

ROM, ROM2 = "#cfe8d6", "#b3d9bf"          # flash
RAM, COMMON = "#d8e4fb", "#b9cdf5"        # banked RAM, common RAM (same colours as in the book)
FREE = "#f3f6fc"
MON = "#fde3b5"                           # the monitor
KERNEL = "#e9dcfa"
OLD = "#e3e6ec"

# columns: title, subtitle, areas from 0x0000 up: (name, detail, colour, start, end, show the start),
# and whether to mark the start of the common RAM (0xC000) inside the areas
COLUMNS = [
    ("1. Reset", "the ROM is at 0x0000", False, [
        ("vectors.s", "copy 0x0100 -> 0xE000, jp init", ROM2, 0x0000, 0x0100, True),
        ("monitor code, stored", "linked for 0x%04X" % CODE, ROM2, 0x0100, STORED_END, True),
        ("rest of the ROM", "0xFF", ROM, STORED_END, 0x8000, True),
        ("RAM", "bank 0", RAM, 0x8000, 0xC000, True),
        ("common RAM", "nothing yet", COMMON, 0xC000, 0x10000, True),
    ]),
    ("2. Monitor running in RAM", "copied to 0xE000, ROM switched off", True, [
        ("vectors", "written again by init", RAM, 0x0000, 0x0100, True),
        ("free", "for the kernel", FREE, 0x0100, CODE, True),
        ("monitor code", "CODE_ADDR", MON, CODE, CODE_END, True),
        ("free", "", FREE, CODE_END, DATA, True),
        ("monitor variables", "DATA_ADDR", MON, DATA, DATA_END, True),
        ("free, stack", "the stack grows down from 0xFFFF", COMMON, DATA_END, 0x10000, True),
    ]),
    ("3. Kernel started", "boot, or load + run, then jp 0x0000", True, [
        ("crt0", "jp init, IM 1, NMI", KERNEL, 0x0000, 0x0100, True),
        ("kernel", "code, C globals", KERNEL, 0x0100, KERNEL_END, True),
        ("free", "", FREE, KERNEL_END, CODE, False),
        ("old monitor", "not used anymore", OLD, CODE, DATA_END, True),
        ("free, kernel stack", "crt0: from 0xFFFF too", KERNEL, DATA_END, 0x10000, False),
    ]),
]

H = 640                           # height of a column: 64 KB
MIN_H = 30                        # smallest interval drawn
X0, COL_W, GAP = 90, 230, 95      # first column, width of a column, room for the addresses between
Y_TOP = 90                        # top of the columns (0xFFFF)

# One vertical scale for all the columns, so that an address is at the same height everywhere: the
# boundaries of every column (and 0xC000) cut 0x0000-0xFFFF into intervals; an interval is drawn at
# its size, at least MIN_H, and the biggest one gives up the extra room (it gets the dashed cut).
bounds = sorted({0xC000} | {a for _, _, _, areas in COLUMNS for area in areas for a in area[3:5]})
sizes = [hi - lo for lo, hi in zip(bounds, bounds[1:])]
hs = [max(MIN_H, n * H / 0x10000) for n in sizes]
big = sizes.index(max(sizes))
hs[big] -= sum(hs) - H
Y = {}                            # address of a boundary -> its height in the picture
y = Y_TOP + H
for lo, h in zip(bounds, hs):
    Y[lo] = y
    y -= h
Y[0x10000] = Y_TOP
CUT_LO, CUT_HI = bounds[big], bounds[big + 1]
CUT_Y = Y[CUT_LO] - min(40, hs[big] / 4)        # the cut: low in the biggest interval

s = SVG(X0 + 3 * COL_W + 2 * GAP + 20, Y_TOP + H + 20)
for i, (title, sub, common, areas) in enumerate(COLUMNS):
    x = X0 + i * (COL_W + GAP)
    s.text(x + COL_W / 2, 28, title, 15, "middle", C_INK, "bold")
    s.text(x + COL_W / 2, 52, sub, 12, "middle", C_SOFT)
    for name, detail, colour, start, end, show in areas:
        bottom, top = Y[start], Y[end]
        h = bottom - top
        s.rect(x, top, COL_W, h, fill=colour, stroke=C_INK, sw=1.8, r=2)
        mid = (top + bottom) / 2
        if start <= CUT_LO and CUT_HI <= end:     # dashed cut: drawn shorter than it is
            s.rect(x - 3, CUT_Y - 6, COL_W + 6, 12, fill="#ffffff", stroke="none", sw=0, r=0)
            s.line([(x - 6, CUT_Y - 6), (x + COL_W + 6, CUT_Y - 6)], C_SOFT, 1.5, dash="6 4")
            s.line([(x - 6, CUT_Y + 6), (x + COL_W + 6, CUT_Y + 6)], C_SOFT, 1.5, dash="6 4")
            mid = (top + CUT_Y - 6) / 2
        size = end - start
        info = "%d KB" % (size // 1024) if size >= 2048 else "%d bytes" % size
        detail = detail + ", " + info if detail else info
        if h >= 44:
            s.text(x + COL_W / 2, mid - 9, name, 14, "middle", C_INK, "bold")
            s.text(x + COL_W / 2, mid + 11, detail, 12, "middle", C_SOFT)
        else:
            s.text(x + COL_W / 2, mid, name + " (" + info + ")", 13, "middle", C_INK, "bold")
        if show:
            s.text(x - 8, bottom, "0x%04X" % start, 12, "end", C_ADDR, "bold", mono=True)
            s.line([(x - 5, bottom), (x, bottom)], C_ADDR, 2)
        if common and start < 0xC000 < end:      # discreet: a thin dashed line, the address in grey
            yc = Y[0xC000]
            s.line([(x, yc), (x + COL_W, yc)], C_SOFT, 1, dash="2 3")
            s.text(x + COL_W - 6, yc - 9, "common RAM above (bank 0)", 11, "end", C_SOFT, italic=True)
            s.text(x - 8, yc, "0xC000", 12, "end", C_SOFT, mono=True)
    s.text(x - 8, Y_TOP, "0xFFFF", 12, "end", C_ADDR, "bold", mono=True)
    s.line([(x - 5, Y_TOP), (x, Y_TOP)], C_ADDR, 2)

os.makedirs(os.path.join(ROOT, "docs"), exist_ok=True)
s.save(os.path.join(ROOT, "docs", "memmap.svg"))
