#include "core/panic.h"

void plt_halt(void)
{
    __asm__("di");
    while (1) {
        __asm__("halt");
    }
}
