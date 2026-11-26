#include "dev/sio.h"

static void puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            sio_putc('\r');
        sio_putc(*s++);
    }
}

void main(void)
{
    puts("Z80 kernel 0.0\n");
    for (;;)
        sio_putc(sio_getc());   /* echo, until there is something better to do */
}
