#include "glx.h"
#include <xs1.h>

int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data)
{
    unsigned tmp[1];
    tmp[0] = data;
    return write_periph_32(tile, peripheral, addr, 1, tmp);
}

int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data)
{
    unsigned tmp[1];
    int retval = read_periph_32(tile, peripheral, addr, 1, tmp);
    data = tmp[0];
    return retval;
}
