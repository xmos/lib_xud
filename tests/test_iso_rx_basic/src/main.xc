// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT       (6)
#define EP_COUNT_IN        (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START   (10)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END     (14)
#endif

#ifndef EP_LENGTH
#define EP_LENGTH           (14)
#endif

#include "xud_shared.h"

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    /**
    The code below hits the limitation in xmake when the shared code (shared.xc) used by multiple build configs of this test
    is present in a shared location outside the test_iso_rx_basic directory.

    When compiling, the .o for the shared.xc file gets created in the test_iso_rx_basic/shared/src directory
    and not within the test_iso_rx_basic/.build_<config> directory.
    When compiling 2 tests, one which defines XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME to 2 and the other to 1, the test_iso_rx_basic/shared/src/shared.o
    contains one of TestEp_Rx_Hbw or TestEp_Rx, depending on which test compiled first and the other test gives an error like
    ../../shared/test_main.xc:(.text+0x8): Error: undefined reference to '_STestEp_Rx_0'

    To workaround this, I have included the shared.xc in the test (see #include "src/shared.xc below") instead of compiling it separately
    as a src file in the Makefile.
    As a result, the Makefile for this test now includes a modified version of the common makefile (test_makefile.mak)
    which doesnt compile the shared.xc file.
    */

    #if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
        unsigned fail = TestEp_Rx_Hbw(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END, EP_LENGTH);
    #else
        unsigned fail = TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END);
    #endif

    return fail;
}

#include "test_main.xc"
#include "src/shared.xc" // including shared file in the test instead of compiling it as shared code in the Makefile. Read comment above

