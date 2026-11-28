#include "core/console.h"
#include "core/kprintf.h"
#include "core/timer.h"

void main(void)
{
    console_init();
    plt_timer_init();
    __asm__("ei");

    kprintf("Z80 kernel version 0.0\n");
    kprintf("SIO and CTC initialized\n");
    for (;;)
        kputchar(kgetchar()); /* echo, until there is something better to do */
}
