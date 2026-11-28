/* Kernel console of the board: SIO channel A at 115200. Ties core's console (core/console.h,
 * core/kprintf.h) to the generic SIO driver. */
#include "core/console.h"
#include "core/kprintf.h"
#include "dev/sio.h"
#include "platform/vectors.h"

void console_init(void)
{
    sio_init(SIO_115200, SIO_VECTOR);
}

char kgetchar(void)
{
    return sio_getc();
}

void kputchar(char c)
{
    if (c == '\n') {
        sio_putc('\r');
    }
    sio_putc(c);
}
