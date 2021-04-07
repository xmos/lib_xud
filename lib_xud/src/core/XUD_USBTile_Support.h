// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

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
