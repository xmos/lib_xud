#ifndef _glx_h_
#define _glx_h_

int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data);
int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data);

void write_periph_word_two_part_start(chanend tmpchan, tileref tile, unsigned peripheral,
                                      unsigned base_address, unsigned data);
void write_periph_word_two_part_end(chanend tmpchan, unsigned data);

#endif // _glx_h_
