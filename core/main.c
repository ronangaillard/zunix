#include "core/kprintf.h"
#include "core/timer.h"
#include "dev/sio.h"

void main(void)
{
    sio_init(SIO_115200);
    plt_timer_init();
    __asm__("ei");

    kprintf("Z80 kernel version 0.0\n");
    kprintf("SIO and CTC initialized\n");
    for (;;) {
        if (timer_ticks() == 1667) {
            kprintf("10 seconds elapsed\n");
        }
    }
}
