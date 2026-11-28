/* Kernel time: a counter of ticks, one per timer interrupt */
#ifndef CORE_TIMER_H
#define CORE_TIMER_H

#include <stdint.h>

/* Called by the timer interrupt handler (platform/vectors.s), with interrupts off. */
void timer_interrupt(void);

/* Number of ticks since the timer was started. Safe to call with interrupts on. */
uint16_t timer_ticks(void);

/* Sets up the board's timer to interrupt at a fixed rate. The platform provides it. */
void plt_timer_init(void);

#endif
