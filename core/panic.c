#include "core/panic.h"

#include "core/kprintf.h"

void panic(const char *msg)
{
    kprintf("panic: %s\n", msg);
    plt_halt();
}
