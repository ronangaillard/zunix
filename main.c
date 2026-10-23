__sfr __at(0x20) sio_ad;   /* SIO channel A data) */
__sfr __at(0x21) sio_ac;   /* SIO channel A control: RR0 bit 0 = Rx ready, bit 2 = Tx empty */

static void putc(char c)
{
    while (!(sio_ac & 0x04))
        ;
    sio_ad = c;
}

static void puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            putc('\r');
        putc(*s++);
    }
}

static char getc(void)
{
    while (!(sio_ac & 0x01))
        ;
    return sio_ad;
}

void main(void)
{
    puts("Z80 kernel 0.0\n");
    for (;;)
        putc(getc());   /* echo, until there is something better to do */
}
