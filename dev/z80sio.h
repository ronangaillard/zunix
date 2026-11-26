/* Z80 SIO registers
 *
 * Each channel has one control port. Reading it gives RR0 and writing it goes to WR0. To reach
 * another register, write its number to WR0 first (bits 0-2), then read or write the control
 * port once more: that access goes to the selected register, and the pointer goes back to 0.
 *
 */

#ifndef DEV_Z80SIO_H
#define DEV_Z80SIO_H

/* Register numbers */
#define SIO_R0 0
#define SIO_R1 1
#define SIO_R2 2 /* WR2 / RR2: interrupt vector, channel B only */
#define SIO_R3 3
#define SIO_R4 4
#define SIO_R5 5
#define SIO_R6 6 /* sync characters, unused in async */
#define SIO_R7 7

/* WR0: register pointer (bits 0-2) and commands (bits 3-5), combined with | */
#define SIO_WR0_NULL 0x00
#define SIO_WR0_RESET_EXT_INT 0x10 /* reset external/status interrupts */
#define SIO_WR0_CHANNEL_RESET 0x18 /* channel reset: every register back to its reset state */
#define SIO_WR0_INT_NEXT_RX 0x20   /* enable interrupt on next received character */
#define SIO_WR0_RESET_TX_INT 0x28  /* reset transmitter interrupt pending */
#define SIO_WR0_ERROR_RESET 0x30   /* reset the error latches of RR1 */
#define SIO_WR0_RETI 0x38          /* return from interrupt, channel A only */

/* WR1: interrupts */
#define SIO_WR1_EXT_INT 0x01        /* external/status interrupt enable */
#define SIO_WR1_TX_INT 0x02         /* transmitter interrupt enable */
#define SIO_WR1_STATUS_VECTOR 0x04  /* status affects vector (channel B only) */
#define SIO_WR1_RX_INT_OFF 0x00     /* receive interrupts disabled */
#define SIO_WR1_RX_INT_FIRST 0x08   /* interrupt on the first received character only */
#define SIO_WR1_RX_INT_ALL_PAR 0x10 /* on every character, parity error affects vector */
#define SIO_WR1_RX_INT_ALL 0x18     /* on every character, parity does not affect vector */

/* WR3: receiver */
#define SIO_WR3_RX_ENABLE 0x01
#define SIO_WR3_AUTO_ENABLES 0x20 /* DCD enables Rx, CTS enables Tx */
#define SIO_WR3_RX_5BITS 0x00
#define SIO_WR3_RX_7BITS 0x40
#define SIO_WR3_RX_6BITS 0x80
#define SIO_WR3_RX_8BITS 0xC0

/* WR4: clock mode, stop bits, parity */
#define SIO_WR4_PARITY_ENABLE 0x01
#define SIO_WR4_PARITY_EVEN 0x02 /* 0: odd */
#define SIO_WR4_STOP_1 0x04
#define SIO_WR4_STOP_1_5 0x08
#define SIO_WR4_STOP_2 0x0C
#define SIO_WR4_CLOCK_X1 0x00
#define SIO_WR4_CLOCK_X16 0x40
#define SIO_WR4_CLOCK_X32 0x80
#define SIO_WR4_CLOCK_X64 0xC0

/* WR5: transmitter */
#define SIO_WR5_RTS 0x02
#define SIO_WR5_TX_ENABLE 0x08
#define SIO_WR5_SEND_BREAK 0x10
#define SIO_WR5_TX_5BITS 0x00
#define SIO_WR5_TX_7BITS 0x20
#define SIO_WR5_TX_6BITS 0x40
#define SIO_WR5_TX_8BITS 0x60
#define SIO_WR5_DTR 0x80

/* RR0: status, read directly from the control port */
#define SIO_RR0_RX_AVAILABLE 0x01 /* a received character is waiting */
#define SIO_RR0_INT_PENDING 0x02  /* channel A only */
#define SIO_RR0_TX_EMPTY 0x04     /* the transmit buffer can take a character */
#define SIO_RR0_DCD 0x08
#define SIO_RR0_CTS 0x20
#define SIO_RR0_BREAK 0x80

/* RR1: special receive conditions */
#define SIO_RR1_ALL_SENT 0x01 /* the last character has left the shift register */
#define SIO_RR1_PARITY_ERROR 0x10
#define SIO_RR1_RX_OVERRUN 0x20 /* a character was lost: the 3-byte receive FIFO was full */
#define SIO_RR1_FRAMING_ERROR 0x40

#endif
