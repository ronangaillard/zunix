#include "dev/sio.h"
#include "platform/ports.h"

void sio_putc(char c)
{
    while (!(sio_ac & 0x04))
        ;
    sio_ad = c;
}

char sio_getc(void)
{
    while (!(sio_ac & 0x01))
        ;
    return sio_ad;
}
