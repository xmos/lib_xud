// Martin Vickers : 24/9/10
#define __XS1_L__
#include <xs1.h>
#include <platform.h>
#include "print.h"
//#include "ctrlReg.h"

extern int write_sswitch_reg_noresp(unsigned coreid, unsigned reg, unsigned data);
extern int write_sswitch_reg_nodeid_noresp(unsigned coreid, unsigned reg, unsigned data);
extern void     TerminateFail(signed int);
extern unsigned int ReadPS_XC0 (unsigned int);

#define XVBGX1 1
#ifdef XVBGX1
  #define SLINK_DEF XS1_SSWITCH_SLINK_3_NUM
  #define XLINK_DEF XS1_SSWITCH_XLINK_3_NUM
#else
  #ifdef MCM
    #define SLINK_DEF XS1_SSWITCH_SLINK_5_NUM
    #define XLINK_DEF XS1_SSWITCH_XLINK_5_NUM
  #else
    #define SLINK_DEF XS1_SSWITCH_SLINK_7_NUM
    #define XLINK_DEF XS1_SSWITCH_XLINK_7_NUM
  #endif
#endif

void glx_link_setup_no_link_or_hello (unsigned myid, unsigned glxid) {
  unsigned link_mismatch1_u = 0;
  unsigned link_mismatch0_u = 0;
  unsigned i;
  unsigned temp_glxid_u = glxid;
  unsigned temp_myid_u  = myid;

// detect MSB for which myid != glxid
  for (i=0; i<16; i=i+1) {

    if ((temp_glxid_u & 0x01) != (temp_myid_u & 0x01)) {
     if (i>7) {
        link_mismatch1_u = 0x01 << ((i-8)*4);
      } else {
        link_mismatch0_u = 0x01 << (i*4);
      }
    }
    temp_glxid_u = temp_glxid_u >> 1;
    temp_myid_u  = temp_myid_u >> 1;

  }
  if (link_mismatch1_u) {
    link_mismatch0_u = 0;
  }

  //set my core id to non-zero setup id
  write_sswitch_reg_nodeid_noresp(0, XS1_SSWITCH_NODE_ID_NUM, myid);
  //setup network and direction
  write_sswitch_reg_noresp(myid, XS1_SSWITCH_DIMENSION_DIRECTION1_NUM, link_mismatch1_u);
  write_sswitch_reg_noresp(myid, XS1_SSWITCH_DIMENSION_DIRECTION0_NUM, link_mismatch0_u);
  write_sswitch_reg_noresp(myid, SLINK_DEF, 0x00000100);

}

#include <xa1_registers.h>
void glx_link_setup_no_set_sys_clk_freq (unsigned myid, unsigned glxid) {

  unsigned link_delay_vals, link_delay_vals_rem, glx_period_val, link_setup_val,read_data_u;

  glx_link_setup_no_link_or_hello(myid,glxid);

  //GLX hackery, the value of the GLX clock period (in ps) is forced into the ring_osc registers = 50ns = 50000ps.
  glx_period_val      = 50000; //ReadPS_XC0(0x80b) << 16 | ReadPS_XC0(0x70b);

  //divide by the XCore clock period (in ps)
  link_delay_vals     = (glx_period_val / 2500) * 2; //2500

  //Round up the division
  link_delay_vals_rem = ((glx_period_val % 2500) > (2500/2)) ? 2 : 0; //2500

  //Set the link to run half the rate of the glx clock freq
  link_delay_vals     = (link_delay_vals + link_delay_vals_rem) & 0x7ff;

  //  link_delay_vals = 0x7ff;
  //operate in 5w mode, send hello and set the delays.
  link_setup_val      = 0x3 << 30 | 0x1 << 24 | (link_delay_vals << 11) | link_delay_vals;

  //enable link to galaxian in 5w mode with delays of calculated above and send hello from xevious
  write_sswitch_reg_noresp(myid, XLINK_DEF, /*0xc100a014*/link_setup_val);

  //read_sswitch_reg(glxid, XS1_GLX_CFG_DEV_ID_ADRS, link_setup_val);
  //printhexln(link_setup_val);

  //send hello from galaxian
  write_sswitch_reg_noresp(glxid, XS1_GLX_CFG_LINK_CTRL_ADRS, 0xc1000000);

}

void glx_link_setup_set_sys_clk_freq (unsigned myid, unsigned glxid) {


  unsigned  link_delay_vals,link_setup_val,glx_period_val, read_data_u;

  read_sswitch_reg(glxid, XS1_GLX_CFG_DEV_ID_ADRS, read_data_u);

  //test to see if the on-chip osc is being used.
  if ((read_data_u & (1<<XS1_GLX_CFG_MODE_BOOT_BASE)) == 0) {
    //update galaxians system clock frequency register
    read_data_u = 24; //ReadPS_XC0(0xA0b) << 16 | ReadPS_XC0(0x90b);
    write_sswitch_reg_noresp(glxid, XS1_GLX_CFG_SYS_CLK_FREQ_ADRS, read_data_u);
  }

}


void glx_link_setup (unsigned myid, unsigned glxid) {
  glx_link_setup_no_set_sys_clk_freq(myid,glxid);
  glx_link_setup_set_sys_clk_freq(myid,glxid);

}


void glx_link_setup_with (unsigned myid, unsigned glxid, unsigned link_setup_val) {

  glx_link_setup_no_link_or_hello(myid,glxid);

  //enable link to galaxian in 5w mode with delays of calculated above and send hello from zaxxon
  write_sswitch_reg_noresp(myid, XLINK_DEF, /*0xc100a014*/link_setup_val);

  //send hello from galaxian
  write_sswitch_reg_noresp(glxid, XS1_GLX_CFG_LINK_CTRL_ADRS, 0xc1000000);

  glx_link_setup_set_sys_clk_freq(myid,glxid);
}

// Disable the xlinks for GLX so that the terminate sequence works properly
void glx_link_unsetup (unsigned myid, unsigned glxid) {

  //setup network and direction
  write_sswitch_reg_noresp(myid, XS1_SSWITCH_DIMENSION_DIRECTION1_NUM, 0);
  write_sswitch_reg_noresp(myid, XS1_SSWITCH_DIMENSION_DIRECTION0_NUM, 0);
  write_sswitch_reg_noresp(myid, SLINK_DEF, 0);

  //enable link to galaxian in 5w mode with delays of 0x15 and send hello from zaxxon
  write_sswitch_reg_noresp(myid, XLINK_DEF, 0);
}

void glx_1bh_mode (unsigned myid, unsigned glxid) {
  unsigned read_data_u;
  // set Galaxian to 1bh mode
  read_sswitch_reg(glxid, XS1_SSWITCH_NODE_CONFIG_NUM, read_data_u);
  write_sswitch_reg_noresp(glxid, XS1_SSWITCH_NODE_CONFIG_NUM, (read_data_u | 0x01));
  // set Zaxxon/Xevious to 1bh mode
  read_sswitch_reg(myid, XS1_SSWITCH_NODE_CONFIG_NUM, read_data_u);
  write_sswitch_reg_noresp(myid, XS1_SSWITCH_NODE_CONFIG_NUM, (read_data_u | 0x01));
}

void glx_3bh_mode (unsigned myid, unsigned glxid) {
  unsigned read_data_u;
  read_sswitch_reg(glxid, XS1_SSWITCH_NODE_CONFIG_NUM, read_data_u);
  write_sswitch_reg_noresp(glxid, XS1_SSWITCH_NODE_CONFIG_NUM, (read_data_u & 0xfffffffe));
  read_sswitch_reg(myid, XS1_SSWITCH_NODE_CONFIG_NUM, read_data_u);
  write_sswitch_reg(myid, XS1_SSWITCH_NODE_CONFIG_NUM, (read_data_u & 0xfffffffe));
}


