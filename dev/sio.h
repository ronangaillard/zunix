/* Z80 SIO driver */
#ifndef DEV_SIO_H
#define DEV_SIO_H

#include <stdint.h>

#define SIO_9600 0
#define SIO_19200 1
#define SIO_38400 2
#define SIO_57600 3
#define SIO_115200 4

void sio_init(uint8_t speed);
void sio_putc(char c); /* waits until the transmitter is empty, then sends c */
char sio_getc(void);   /* waits for a received byte and returns it */

#endif
