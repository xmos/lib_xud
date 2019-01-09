#include <platform.h>
#include <stdio.h>
#include <xs2_su_registers.h>

unsigned XUD_EnableUsbPortMux();
int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data);
int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data);

int write_periph_word_chanend(chanend c, tileref tile,
                              unsigned peripheral,
                              unsigned addr, unsigned data);
int main(void)
{
  chan c;
  XUD_EnableUsbPortMux();
  write_sswitch_reg(get_tile_id(usb_tile), 0x50, ( 1 << 0x3));
  par {
    //write_periph_word(usb_tile, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_PHY_CONTROL_NUM, 1);
    write_periph_word_chanend(c, usb_tile, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_PHY_CONTROL_NUM, 1);
  }
  unsigned val;
  read_periph_word(usb_tile, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_PHY_CONTROL_NUM, val);
  printf("%d\n", val);
  return 0;
}
