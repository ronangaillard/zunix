#include "core/timer.h"
#include <stdint.h>

static volatile uint16_t ticks;

void timer_interrupt(void)
{
    ticks += 1;
}

uint16_t timer_ticks(void)
{
    uint16_t t;

    __critical
    {
        t = ticks;
    }

    return t;
}
