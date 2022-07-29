// Copyright 2013-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifdef __XS2A__

#include <xs1.h>

#define STRINGIFY0(x) #x
#define STRINGIFY(x) STRINGIFY0(x)
#define ENABLE_INTERRUPTS()   asm("setsr " STRINGIFY(XS1_SR_IEBLE_SET(0, 1)))
#define DISABLE_INTERRUPTS()  asm("clrsr " STRINGIFY(XS1_SR_IEBLE_SET(0, 1)))

#define CT_PERIPH_WRITE 0x24
#define JUNK_RETURN_ADDRESS 0xFF

unsigned getsr_int();

int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data)
{
    unsigned tmp[1];
    tmp[0] = data;
    return write_periph_32(tile, peripheral, addr, 1, tmp);
}

int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data)
{
    unsigned tmp[1];
    unsigned prevSr = 0;

    /* Get current interrupt bit from SR */
    asm volatile("getsr r11, 2; mov %0, r11" :"=r"(prevSr) :: "r11");

    /* Clear the interrupt bit in SR  */
    DISABLE_INTERRUPTS();

    int retval = read_periph_32(tile, peripheral, addr, 1, tmp);

    /* Re-enable interrupts if they were previously enabled */
    if(prevSr)
        ENABLE_INTERRUPTS();

    data = tmp[0];
    return retval;
}

void write_periph_word_two_part_start(chanend tmpchan, tileref tile, unsigned peripheral,
                                      unsigned base_address, unsigned data)
{
    asm("setd res[%0], %1" ::
        "r"(tmpchan),
        "r"((get_tile_id(tile) << 16) | (peripheral << 8) | XS1_RES_TYPE_CHANEND));

    /* Preload as much as possible, everything up to last byte of data */
    outct(tmpchan, CT_PERIPH_WRITE);
    outuint(tmpchan, (JUNK_RETURN_ADDRESS << 8) | (base_address & 0xFF));
    outuchar(tmpchan, sizeof(unsigned));
    outuchar(tmpchan, data >> 24);
    outuchar(tmpchan, data >> 16);
    outuchar(tmpchan, data >> 8);
}

void write_periph_word_two_part_end(chanend tmpchan, unsigned data)
{
    /* Send last byte of data to bring the write to effect */
    outuchar(tmpchan, data);
    outct(tmpchan, XS1_CT_END);
}
#endif
