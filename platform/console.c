/* Kernel console of the board: where kputchar (core/kprintf.h) sends kernel messages */
#include "core/kprintf.h"
#include "dev/sio.h"

void kputchar(char c)
{
    if (c == '\n') {
        sio_putc('\r');
    }
    sio_putc(c);
}
