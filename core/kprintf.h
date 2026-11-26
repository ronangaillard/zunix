/* Kernel messages: formatted output, without the C library */
#ifndef CORE_KPRINTF_H
#define CORE_KPRINTF_H

/* Formats fmt with the arguments that follow and sends the result to kputchar.
 * Supported: %s %c %x %d %u %% */
void kprintf(const char *fmt, ...);

/* Sends one character to the kernel console. The platform provides it. */
void kputchar(char c);

#endif
