// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "xud_shared.h"

extern size_t g_dummyThreadCount;

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN]);

#ifdef XUD_SIM_RTL
int testmain()
#else
int main()
#endif
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
        {

#ifndef XUD_TEST_SPEED
#error XUD_TEST_SPEED must be defined
#endif
		 	const unsigned speed = XUD_TEST_SPEED;

            const int epCountOut = sizeof(epTypeTableOut)/sizeof(epTypeTableOut[0]);
            const int epCountIn = sizeof(epTypeTableIn)/sizeof(epTypeTableIn[0]);

            assert(epCountOut == EP_COUNT_OUT);
            assert(epCountIn == EP_COUNT_IN);

            XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                speed, XUD_PWR_BUS);
        }

        {
            set_thread_fast_mode_on();
            unsigned fail = test_func(c_ep_out, c_ep_in);

#ifdef XUD_SIM_RTL
            /* Note, this test relies on checking at the host side */
            if(fail)
                TerminateFail(fail);
            else
                TerminatePass(fail);
#endif
            unsafe{
                unsigned * unsafe p = &g_dummyThreadCount;
                *p = 0;
            }
            if(TEST_EP_NUM != 0)
            {
                XUD_ep ep_out_0 = XUD_InitEp(c_ep_out[0]);
                XUD_Kill(ep_out_0);
            }
            exit(0);
        }

        dummyThreads();
    }

    return 0;
}
