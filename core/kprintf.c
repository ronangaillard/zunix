#include "core/kprintf.h"

#include <stdarg.h>
#include <stdint.h>

static void print_unsigned(unsigned int n, uint8_t base)
{
    unsigned char string[16];
    unsigned char *next_char = string;

    if (n == 0) {
        kputchar('0');
    }

    while (n) {
        unsigned char number = n % base;

        if (number < 10) {
            *next_char = '0' + number;
        } else {
            *next_char = 'a' + number - 10;
        }

        n = n / base;

        next_char += 1;
    }

    while (next_char > string) {
        next_char -= 1;
        kputchar(*next_char);
    }
}

static void print_signed(int n)
{
    if (n >= 0) {
        print_unsigned(n, 10);
    } else {
        kputchar('-');

        print_unsigned(-(unsigned int)n, 10);
    }
}

void kprintf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);

    while (*fmt) {
        if (*fmt != '%') {
            kputchar(*fmt);
        } else {
            fmt += 1;

            if (*fmt == 0) {
                va_end(ap);
                return;
            }

            if (*fmt == 'c') {
                const char c = va_arg(ap, const int);
                kputchar(c);
            }

            if (*fmt == 's') {
                const char *string = va_arg(ap, const char *);
                while (*string) {
                    kputchar(*string);
                    string += 1;
                }
            }

            if (*fmt == 'd') {
                int number = va_arg(ap, const int);
                print_signed(number);
            }

            if (*fmt == 'u') {
                int number = va_arg(ap, const int);
                print_unsigned(number, 10);
            }

            if (*fmt == 'x') {
                int number = va_arg(ap, const int);
                print_unsigned(number, 16);
            }

            if (*fmt == '%') {
                kputchar('%');
            }
        }

        fmt += 1;
    }

    va_end(ap);
}
