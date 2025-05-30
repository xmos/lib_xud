// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "xud_shared.h"

extern unsigned char crc5Table[2048];

extern void crc_tester(chanend ch);

extern void XUD_SetCrcTableAddr(unsigned addr);

static inline void do_test(chanend ch, unsigned addr, unsigned ep, unsigned eq){
  unsigned tok = addr | (ep << 7);
  // get the crc from all valid table
  unsigned crc5 = crc5Table[tok];
  tok |= (crc5 << 11);
  tok <<= 16;
  outuint(ch, tok);
  unsigned crc5_rcv = inuint(ch);

  if(eq)
    asm("ecallf %0":: "r" (crc5 == crc5_rcv));
  else
    asm("ecallf %0":: "r" (crc5 != crc5_rcv));
}

void crc_host(chanend ch){
  for(unsigned addr = 0; addr < 128; addr++){
    XUD_SetCrcTableAddr(addr);

    for(unsigned ep = 0; ep < 16; ep++){
      do_test(ch, addr, ep, 1);
    }

    unsigned invalid_addr = (addr + 1) % 128;
    do_test(ch, invalid_addr, 0, 0);
  }

  printstr("Test done\n");
  exit(0);
}

void main(void){
  chan ch;

  par{
    crc_host(ch);
    crc_tester(ch);
  }
}
