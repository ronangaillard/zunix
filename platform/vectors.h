/* Layout of the IM 2 table (platform/vectors.s), seen from C
 *
 * A chip's vector is the offset of its first entry in the table: I holds the table's high byte,
 * the chip sends the low byte. Each value below must match the .dw lines of vectors.s: moving a
 * block there means changing its value here, and the other way round.
 */
#ifndef PLATFORM_VECTORS_H
#define PLATFORM_VECTORS_H

/* CTC: the CTC puts the channel number in bits 1-2 and bit 0 must
 * be 0, so a multiple of 8. */
#define CTC_VECTOR 0x00

#endif
