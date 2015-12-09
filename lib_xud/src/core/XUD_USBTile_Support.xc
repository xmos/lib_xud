
#include <xs1.h>

#define STRINGIFY0(x) #x
#define STRINGIFY(x) STRINGIFY0(x)
#define ENABLE_INTERRUPTS()   asm("setsr " STRINGIFY(XS1_SR_IEBLE_SET(0, 1)))
#define DISABLE_INTERRUPTS()  asm("clrsr " STRINGIFY(XS1_SR_IEBLE_SET(0, 1)))

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
