#define __XS1_L__
#include <xs1.h>
#include <platform.h>
#include <xa1_registers.h>

extern int write_sswitch_reg_noresp(unsigned coreid, unsigned reg, unsigned data);
extern int write_sswitch_reg_nodeid_noresp(unsigned coreid, unsigned reg, unsigned data);

// Set the clock frequency in MHz
#define CLK_FREQ_MHZ 48

#define XVBS2

#if ( defined XVBGX1 )
    // Xlink 3 connected in the separately packaged galaxian bringup board
    #define SLINK_DEF XS1_SSWITCH_SLINK_3_NUM
    #define XLINK_DEF XS1_SSWITCH_XLINK_3_NUM
#elif ( defined MCM ) || ( defined XVBS1 )
    //
    #if ( defined SPECIAL_XVBS1 )
        // Change the link setups when actually building for the separately packaged galaxian bringup board
        // Xlink 3 is used.
        #define SLINK_DEF XS1_SSWITCH_SLINK_3_NUM
        #define XLINK_DEF XS1_SSWITCH_XLINK_3_NUM
    #else
        // Xlink 5 is used in the S1 and S2 MCMs
        #define SLINK_DEF XS1_SSWITCH_SLINK_5_NUM
        #define XLINK_DEF XS1_SSWITCH_XLINK_5_NUM
    #endif
#elif ( defined XVBS2 )
    #define SLINK_DEF XS1_SSWITCH_SLINK_0_NUM
    #define XLINK_DEF XS1_SSWITCH_XLINK_0_NUM
#else
    // Xlink 7 is used in the testbench
    #define SLINK_DEF XS1_SSWITCH_SLINK_7_NUM
    #define XLINK_DEF XS1_SSWITCH_XLINK_7_NUM
#endif


void glx_link_setup_no_link_or_hello (unsigned myid, unsigned glxid)
{
  unsigned link_mismatch1_u = 0;
  unsigned link_mismatch0_u = 0;
  unsigned i;
  unsigned temp_glxid_u = glxid;
  unsigned temp_myid_u  = myid;

  // detect MSB for which myid != glxid
  for (i=0; i<16; i=i+1)
  {
    if ((temp_glxid_u & 0x01) != (temp_myid_u & 0x01))
    {
      if (i>7)
      {
        link_mismatch1_u = 0x01 << ((i-8)*4);
      }
      else
      {
        link_mismatch0_u = 0x01 << (i*4);
      }
    }

    temp_glxid_u = temp_glxid_u >> 1;
    temp_myid_u  = temp_myid_u >> 1;
  }

  if (link_mismatch1_u)
  {
    link_mismatch0_u = 0;
  }

  //set my core id to non-zero setup id
  write_sswitch_reg_nodeid_noresp(0, XS1_SSWITCH_NODE_ID_NUM, myid);

  //setup network and direction
  write_sswitch_reg_noresp(myid, XS1_SSWITCH_DIMENSION_DIRECTION1_NUM, link_mismatch1_u);
  write_sswitch_reg_noresp(myid, XS1_SSWITCH_DIMENSION_DIRECTION0_NUM, link_mismatch0_u);
  write_sswitch_reg_noresp(myid, SLINK_DEF, 0x00000100);

}


void glx_link_setup (unsigned myid, unsigned glxid)
{
    unsigned link_delay_vals, link_delay_vals_rem, glx_period_val, link_setup_val;
    glx_link_setup_no_link_or_hello(myid,glxid);

    // Calc the value of the GLX clock period (in ps)
    glx_period_val      = 1000000 / CLK_FREQ_MHZ;

    // divide by the XCore clock period (in ps)
    link_delay_vals     = (glx_period_val / 2000) * 2; //2500

    // Round up the division
    link_delay_vals_rem = ((glx_period_val % 2000) > (2000/2)) ? 2 : 0; //2500

    // Set the link to run half the rate of the glx clock freq
    link_delay_vals     = (link_delay_vals + link_delay_vals_rem) & 0x7ff;

    // perate in 5w mode, send hello and set the delays.
    link_setup_val      = 0x3 << 30 | 0x1 << 24 | (link_delay_vals << 11) | link_delay_vals;

    // enable link to galaxian in 5w mode with delays of calculated above and send hello from xevious
    write_sswitch_reg_noresp(myid, XLINK_DEF, link_setup_val);

    // send hello from galaxian
    write_sswitch_reg_noresp(glxid, XS1_GLX_CFG_LINK_CTRL_ADRS, 0xc1000000);

    // set the galaxian clock frequency register
    write_sswitch_reg_noresp(glxid, XS1_GLX_CFG_SYS_CLK_FREQ_ADRS, CLK_FREQ_MHZ);
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
