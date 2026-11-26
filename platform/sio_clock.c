#include "platform/sio_clock.h"
#include "dev/sio.h"
#include "dev/z80ctc.h"
#include "platform/ports.h"

static const uint8_t ctc_divisor[] = {12, 6, 3, 2, 1};

void plt_sio_set_speed(uint8_t speed)
{
    if (speed > SIO_115200)
        speed = SIO_115200;
    ctc_0 = CTC_MODE_COUNTER | CTC_TIME_CONSTANT | CTC_RESET | CTC_CONTROL;
    ctc_0 = ctc_divisor[speed];
}
