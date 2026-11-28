/* Layout of the IM 2 table (platform/vectors.s), seen from C
 *
 * A chip's vector is the offset of its first entry in the table: I holds the table's high byte,
 * the chip sends the low byte. Each value below must match the .dw lines of vectors.s: moving a
 * block there means changing its value here, and the other way round.
 */
#ifndef PLATFORM_VECTORS_H
#define PLATFORM_VECTORS_H

/* CTC: 4 entries (channels 0 to 3), the CTC puts the channel number in bits 1-2 and bit 0 must
 * be 0, so a multiple of 8. */
#define CTC_VECTOR 0x00

/* SIO: 8 entries (4 causes for channel B, then 4 for channel A), with status affects vector the
 * SIO replaces bits 1-3 and bit 0 must be 0, so a multiple of 16. 0x08-0x0F stay unused. */
#define SIO_VECTOR 0x10

#endif
