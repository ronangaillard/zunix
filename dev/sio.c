#include "dev/sio.h"
#include "dev/z80ctc.h"
#include "dev/z80sio.h"
#include "platform/ports.h"

void sio_init(void)
{
    // make sure we are on register 0
    sio_ac = SIO_R0;

    // wait for waiting characters to be transmitted
    do {
        sio_ac = SIO_R1;
    } while (!(sio_ac & SIO_RR1_ALL_SENT));

    // setup CTC
    // TODO: setup elsewhere later, SIO driver should not know about CTC
    ctc_0 = CTC_MODE_COUNTER | CTC_TIME_CONSTANT | CTC_RESET | CTC_CONTROL;
    ctc_0 = 0x01; // N = 1: 1.8432 MHz / 1 (CTC) / 16 (SIO, WR4) = 115200 bauds

    sio_ac = SIO_R0 | SIO_WR0_CHANNEL_RESET;
    sio_ac = SIO_R4;
    sio_ac = SIO_WR4_CLOCK_X16 | SIO_WR4_STOP_1;
    sio_ac = SIO_R5;
    sio_ac = SIO_WR5_TX_8BITS | SIO_WR5_TX_ENABLE;
    sio_ac = SIO_R3;
    sio_ac = SIO_WR3_RX_8BITS | SIO_WR3_RX_ENABLE;
}

void sio_putc(char c)
{
    while (!(sio_ac & SIO_RR0_TX_EMPTY))
        ;
    sio_ad = c;
}

char sio_getc(void)
{
    while (!(sio_ac & SIO_RR0_RX_AVAILABLE))
        ;
    return sio_ad;
}
