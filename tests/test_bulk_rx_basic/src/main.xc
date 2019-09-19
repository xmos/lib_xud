// Copyright (c) 2016-2018, XMOS Ltd, All rights reserved
/*
 * Test the use of the ExampleTestbench. Test that the value 0 and 1 can be sent
 * in both directions between the ports.
 *
 * NOTE: The src/testbenches/ExampleTestbench must have been compiled for this to run without error.
 *
 */
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START 10
#endif


#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END 14
#endif

#ifndef TEST_EP_NUM
#define TEST_EP_NUM   1
#endif


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};


#define NLOCK  (1<<30)
#define NRESET (1<<31)

#define PLL_VAL_1000 (NRESET | (0 << 23) | (79 << 8) | (0 << 0))
#define PLL_VAL_800  (NRESET | (0 << 23) |(127 << 8) | (0 << 0))
#define PLL_VAL_500  (NRESET | (1 << 23) | (79 << 8) | (0 << 0))

void default_main();

void enable(int node) 
{
  write_pswitch_reg(node, XS1_PSWITCH_PLL_CLK_DIVIDER_NUM, 0);
  setps(XS1_PS_XCORE_CTRL0, XS1_XCORE_CTRL0_CLK_DIVIDER_EN_SET(0,1));
}

void makePllGoAt800MHz()
{
   enable(1);
   write_sswitch_reg(0, XS1_SSWITCH_CLK_DIVIDER_NUM, 2);

   write_sswitch_reg(0, XS1_SSWITCH_REF_CLK_DIVIDER_NUM, 15);
   write_sswitch_reg(0, XS1_SSWITCH_CLK_DIVIDER_NUM, 2);

   int pllValue = PLL_VAL_800 ; // output 1GHz   
   write_node_config_reg_no_ack(tile[0], XS1_SSWITCH_PLL_CTL_NUM, pllValue);

}
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        on stdcore[0]:
        {
            //makePllGoAt800MHz();
            unsigned fail;
            
            par
            {

                XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                        null, epTypeTableOut, epTypeTableIn,
                        null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

                {
                    fail = TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END);
                    
                    if(fail)
                        TerminateFail(fail);
                    else
                        TerminatePass(fail);    
                    
                    XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
                    XUD_Kill(ep0);
                    //exit(0);
                }
            }
        }

        on stdcore[1]: default_main();
    }

    return 0;
}
