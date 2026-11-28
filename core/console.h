/* The kernel console: where the kernel reads and writes characters. The platform provides it
 * (platform/console.c); kputchar, the output side, is declared in core/kprintf.h. */
#ifndef CORE_CONSOLE_H
#define CORE_CONSOLE_H

/* Sets up the console's device. Call it first: kprintf needs it. */
void console_init(void);

/* Waits for a character typed on the console and returns it. */
char kgetchar(void);

#endif
