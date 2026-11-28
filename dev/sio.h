/* Z80 SIO driver
 *
 * What the platform must provide:
 *   - a header named board.h, that defines these ports (__sfr):
 *       sio_ac   channel A control: WR0-WR5 writes, RR0/RR1 reads
 *       sio_ad   channel A data: the byte sent or received
 *       sio_bc   channel B control: only for WR2, the interrupt vector of both channels
 *   - the function plt_sio_set_speed(speed): starts the baud rate clock of channel A at one of
 *     the SIO_ speeds below
 */
#ifndef DEV_SIO_H
#define DEV_SIO_H

#include <stdint.h>

#define SIO_9600 0
#define SIO_19200 1
#define SIO_38400 2
#define SIO_57600 3
#define SIO_115200 4

void sio_init(uint8_t speed, uint8_t vector);
void sio_putc(char c); /* waits until the transmitter is empty, then sends c */
char sio_getc(void);   /* waits for a received byte and returns it */

/* Provided by the platform (see the contract above): starts the baud rate clock of channel A. */
void plt_sio_set_speed(uint8_t speed);

#endif
