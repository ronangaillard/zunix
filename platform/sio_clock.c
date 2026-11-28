/* Baud rate clock of the SIO on this board: CTC channel 0 divides the 1.8432 MHz oscillator */
#include "dev/sio.h"
#include "dev/z80ctc.h"
#include "platform/board.h"

static const uint8_t ctc_divisor[] = {12, 6, 3, 2, 1};

void plt_sio_set_speed(uint8_t speed)
{
    if (speed > SIO_115200)
        speed = SIO_115200;
    ctc_0 = CTC_MODE_COUNTER | CTC_TIME_CONSTANT | CTC_RESET | CTC_CONTROL;
    ctc_0 = ctc_divisor[speed];
}
