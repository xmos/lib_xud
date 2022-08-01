// Copyright 2018-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "xud.h"
#include "glx.h"
#include "strings.h"

typedef unsigned XUD_chan;

clock cb1 = XS1_CLKBLK_1;
out port lb_usb_clk = XS1_PORT_1L;
out port lb_flag0 = XS1_PORT_1A;
out port lb_flag1 = XS1_PORT_1B;
out port lb_flag2 = XS1_PORT_1C;

enum event {
  READ_OTG_FLAGS,
  DEVICEATTACHHS,
  LLD_LOOP,
  PHY_WRITE_TWO_PART_START
};

const char str_event[][40] = {
  "READ_OTG_FLAGS",
  "DEVICEATTACHHS",
  "LLD_LOOP",
  "PHY_WRITE_TWO_PART_START"
};

static void event(enum event event, unsigned &value);

void loopback_setup(void)
{
  set_port_clock(lb_usb_clk, cb1);
  set_clock_div(cb1, 4);
  set_port_mode_clock(lb_usb_clk);
  start_clock(cb1);
}

void XUD_UserSuspend(void)
{
  printf("UserSuspend\n");
}

void XUD_UserResume(void)
{
  printf("UserResume\n");
}

int write_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned data)
{
  assert(peripheral == 1);

  char text[128] = "";
  describe_phy_access(text, addr, data);
  printf("W U %02X %08X %s\n", addr, data, text);

  return 0;
}

int test_write_sswitch_reg(unsigned tileid, unsigned reg, unsigned data)
{
  char text[128] = "";
  describe_galaxian_access(text, reg, data);
  printf("W G %02X %08X %s\n", reg, data, text);

  return 0;
}

void write_periph_word_two_part_start(chanend tmpchan, tileref tile, unsigned peripheral,
                                      unsigned base_address, unsigned data)
{
  char text[128] = "";
  describe_galaxian_access(text, base_address, data);
  printf("W G %02X %08X part1 %s\n", base_address, data, text);

  event(PHY_WRITE_TWO_PART_START, data);
}

void write_periph_word_two_part_end(chanend tmpchan, unsigned data)
{
  printf("W G part2\n");
}

int read_periph_word(tileref tile, unsigned peripheral, unsigned addr, unsigned &data)
{
  if (addr == XS1_GLX_PER_UIFM_OTG_FLAGS_NUM)
    event(READ_OTG_FLAGS, data);
  else
    assert(0);

  char text[128] = "";
  describe_phy_access(text, addr, data);
  printf("R U %02X %08X %s\n", addr, data, text);

  return 0;
}

int XUD_DeviceAttachHS(XUD_PwrConfig p)
{
  unsigned retval = 0;
  event(DEVICEATTACHHS, retval);
  printf("DeviceAttachHS -> %d\n", retval);
  return retval;
}

int XUD_LLD_IoLoop(in buffered port:32 rxd_port, in port rxa_port,
                   out buffered port:32 txd_port, in port rxe_port,
                   in port flag0_port, in port ?read, out port ?write, int x,
                   XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[],
                   XUD_chan epChans[], int epCount, chanend? c_sof)
{
  printf("LLD_IoLoop\n");
  unsigned dummy;
  event(LLD_LOOP, dummy);
  return 0;
}

static void event(enum event event, unsigned &value)
{
  const int preserve_sessvldb = 1;

  static enum {
    FIRST,
    SUBSEQUENT,
    K,
    SE0
  } previous, state = FIRST;

  static const char str_state[][20] = {
    "FIRST",
    "SUBSEQUENT",
    "K",
    "SE0"
  };

  static unsigned otg_flag_reads = 0;

  previous = state;

  switch (event)
  {
    case READ_OTG_FLAGS:
      if (state == FIRST) {
        value = (1 << XS1_UIFM_OTG_FLAGS_SESSVLDB_SHIFT);
        lb_flag2 <: 1;
      }
      else if (state == SUBSEQUENT) {
        value = (preserve_sessvldb << XS1_UIFM_OTG_FLAGS_SESSVLDB_SHIFT);
        lb_flag2 <: 0;
      }
      else {
        assert(0);
      }
      if (otg_flag_reads == 10) {
        state = K;
        lb_flag0 <: 1;
      }
      otg_flag_reads++;
      break;

    case DEVICEATTACHHS:
      assert(state == FIRST);
      value = 1;
      break;

    case LLD_LOOP:
      if (state == SE0) {
	printf("success\n");
	exit(0);
      }
      else {
	state = SUBSEQUENT;
      }
      break;

    case PHY_WRITE_TWO_PART_START:
      assert(state == K);
      lb_flag2 <: 1;
      state = SE0;
      break;

    default:
      assert(0);
      break;
  }

  printf("%s: %s -> %s\n", str_event[event],
         str_state[previous], str_state[state]);
}

static void test_bench(chanend c_ep_out, chanend c_ep_in)
{
  // nothing
}

int main(void)
{
  chan c_ep_out[1], c_ep_in[1];
  XUD_EpType ep_table[2][1] = {{XUD_EPTYPE_DIS}, {XUD_EPTYPE_DIS}};
  loopback_setup();
  par {
    XUD_Main(c_ep_out, 1, c_ep_in, 1, null, ep_table[0], ep_table[1],
             null, null, 0, XUD_SPEED_HS, XUD_PWR_SELF);
    test_bench(c_ep_out[0], c_ep_in[0]);
  }
  return 0;
}
