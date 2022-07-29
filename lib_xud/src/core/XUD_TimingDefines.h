// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef _XUD_USB_DEFINES_H_
#define _XUD_USB_DEFINES_H_

#ifndef REF_CLK_FREQ
#define REF_CLK_FREQ                (100)
#endif

// Defines relating to USB/ULPI/UTMI/Phy specs
#ifndef SUSPEND_TIMEOUT_us
#define SUSPEND_TIMEOUT_us          (3000)
#endif
#define SUSPEND_TIMEOUT_ticks       (SUSPEND_TIMEOUT_us * REF_CLK_FREQ)

// Device attach timing defines
#define T_UCHEND_T_UCH_us           (1000000)  // 1000ms
#define T_UCHEND_T_UCH              (T_UCHEND_T_UCH_us * REF_CLK_FREQ)

#ifndef T_FILT_us
#define T_FILT_us                   (3)       //   2.5us
#endif
#define T_FILT_ticks                (T_FILT_us * REF_CLK_FREQ)

#ifndef SUSPEND_T_WTWRSTHS_us
#define SUSPEND_T_WTWRSTHS_us       (200)     // 200us Time beforechecking for J after asserting XcvrSelect and Termselect: T_WTRSTHS: 100-875us
#endif
#define SUSPEND_T_WTWRSTHS_ticks    (SUSPEND_T_WTWRSTHS_us * REF_CLK_FREQ)

#define OUT_TIMEOUT_us              (500)     // How long we wait for data after OUT token
#define OUT_TIMEOUT_ticks           (OUT_TIMEOUT_us * REF_CLK_FREQ)
#define TX_HANDSHAKE_TIMEOUT_us     (5)      // How long we wait for handshake after sending tx data
#define TX_HANDSHAKE_TIMEOUT_ticks  (TX_HANDSHAKE_TIMEOUT_us * REF_CLK_FREQ)

#endif
