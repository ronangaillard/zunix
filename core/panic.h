/* Stop the kernel when it finds itself in a state that should never happen */
#ifndef CORE_PANIC_H
#define CORE_PANIC_H

/* Prints "panic: " and msg on the console, then stops the machine. Never returns. */
_Noreturn void panic(const char *msg);

/* Stops the machine after the panic message. */
_Noreturn void plt_halt(void);

#endif
