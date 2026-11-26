/* Z80 SIO driver */
#ifndef DEV_SIO_H
#define DEV_SIO_H

void sio_putc(char c);     /* waits until the transmitter is empty, then sends c */
char sio_getc(void);       /* waits for a received byte and returns it */

#endif
