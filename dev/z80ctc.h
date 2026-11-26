/* Z80 CTC registers
 *
 * The CTC has four channels, one port each
 *   - bit 0 = 1: a control word (the masks below, combined with |)
 *   - bit 0 = 0: the interrupt vector, written to channel 0 only. Bits 3-7 are the vector, the
 *     CTC fills bits 1-2 with the number of the channel that interrupts.
 *   - right after a control word with CTC_TIME_CONSTANT set: the time constant, 1-255,
 *     and 0 means 256. This byte is taken as the constant whatever its bit 0.
 * Reading a channel gives the current value of its down-counter.
 *
 */
#ifndef DEV_Z80CTC_H
#define DEV_Z80CTC_H

/* Control word */
#define CTC_CONTROL 0x01       /* this byte is a control word (0: interrupt vector) */
#define CTC_RESET 0x02         /* software reset: the channel stops until it gets a constant */
#define CTC_TIME_CONSTANT 0x04 /* the next byte written to this channel is the time constant */
#define CTC_TRIGGER_AUTO 0x00  /* timer mode: start as soon as the constant is loaded */
#define CTC_TRIGGER_PULSE 0x08 /* timer mode: start on the next active edge of CLK/TRG */
#define CTC_EDGE_FALLING 0x00  /* active edge of CLK/TRG */
#define CTC_EDGE_RISING 0x10
#define CTC_PRESCALER_16 0x00 /* timer mode: system clock / 16 */
#define CTC_PRESCALER_256 0x20
#define CTC_MODE_TIMER 0x00   /* counts the system clock (through the prescaler) */
#define CTC_MODE_COUNTER 0x40 /* counts edges on CLK/TRG */
#define CTC_INT_ENABLE 0x80   /* interrupt each time the down-counter reaches 0 */

#endif
