#include "core/kprintf.h"
#include "dev/sio.h"

void main(void)
{
    sio_init(SIO_115200);
    kprintf("Z80 kernel version 0.0\n");
    kprintf("SIO and CTC initialized\n");
    for (;;)
        sio_putc(sio_getc()); /* echo, until there is something better to do */
}
