/* The board's timer: which CTC channel ticks, and at what rate */
#include "core/timer.h"
#include "dev/z80ctc.h"
#include "platform/ports.h"
#include "platform/vectors.h"

/* Channel 3 in timer mode counts the CPU clock (CLK_C). Rate = CPU clock / 256 / TIMER_CONSTANT: at
 * 10 MHz, about 153 Hz (6.5 ms). */
#define TIMER_CONSTANT 255

void plt_timer_init(void)
{
    ctc_0 = CTC_VECTOR; /* for the 4 channels: written to channel 0 only */
    ctc_3 = CTC_CONTROL | CTC_TIME_CONSTANT | CTC_TRIGGER_AUTO | CTC_PRESCALER_256 |
            CTC_MODE_TIMER | CTC_INT_ENABLE;
    ctc_3 = TIMER_CONSTANT;
}
