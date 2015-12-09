
#ifndef _XUD_USBTILE_SUPPORT_H_
#define _XUD_USBTILE_SUPPORT_H_ 1

#include "XUD_Support.h"

unsigned XUD_EnableUsbPortMux();

unsigned XUD_DisableUsbPortMux();

int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data);

int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data);

unsigned get_tile_id(tileref ref);
#endif
