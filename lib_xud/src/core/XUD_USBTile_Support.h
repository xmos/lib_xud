// Copyright (c) 2015-2018, XMOS Ltd, All rights reserved

#ifndef _XUD_USBTILE_SUPPORT_H_
#define _XUD_USBTILE_SUPPORT_H_ 1

#include "XUD_Support.h"

unsigned XUD_EnableUsbPortMux();

unsigned XUD_DisableUsbPortMux();

int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data);

int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data);

unsigned get_tile_id(tileref ref);

void write_periph_word_two_part_start(chanend tmpchan, tileref tile, unsigned peripheral,
                                              unsigned base_address, unsigned data);
void write_periph_word_two_part_end(chanend tmpchan, unsigned data);
#endif
