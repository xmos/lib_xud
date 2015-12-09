#ifndef _glx_h_
#define _glx_h_

int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data);
int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data);

#endif // _glx_h_
