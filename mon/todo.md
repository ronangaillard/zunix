# Monitor: to do

## `readline`: bound the line and handle erasing (`readline.s`, `main.s`)

- Nothing limits the line to `COMMAND_MAX_LENGTH` (64): a line that is too long overflows
  `commandbuf` into the variables that follow it in `_DATA`, then towards the stack.
  - Count the characters (in C, as `putc` destroys B) and ignore those beyond the limit.
- No erase key: handle 0x08 (Backspace) and 0x7F (Delete, sent by most terminals for ⌫).
  - Move HL and the counter back, then send `0x08`, `' '`, `0x08` to erase the character on the
    screen.
  - Do nothing on an empty line.
- Ignore the other control characters (< `' '`): Escape, arrows...
- `main.s`: on an empty line, show the prompt again instead of calling `find_command`. This covers
  Enter alone, and a terminal that sends `\r\n` (otherwise: "no command named" for the empty line
  of the `\n`).

## `load_file_to_ram`: one loop for the direct and indirect blocks (`file_system.s`)

Both loops walk the same thing: a table of 2-byte block numbers.

- One `load_blocks` routine: HL = table, B = number of entries (`djnz`; B = 0 gives 256 rounds).
  - Call it with `inodebuf + OFFSET_ADDRESS` / 18, then with `sectorbuf` / 0 after reading the
    indirect block.
- Keep the destination in a variable (`load_address`) instead of on the stack.
  - No more stack juggling, no more `end_of_file` / `read_error` popping before `ret`.
  - `sector_pointer` goes away.
- A `DIRECT_BLOCKS = 18` constant in `file_system.inc`, instead of the hard-coded `18` and `36`.
- Limit (already there): loading stops at the first block 0, so a file with a hole would be cut
  short.
