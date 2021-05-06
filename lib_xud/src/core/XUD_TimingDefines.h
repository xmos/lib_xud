// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef _XUD_USB_DEFINES_H_
#define _XUD_USB_DEFINES_H_

// Defines relating to USB/ULPI/UTMI/Phy specs
#define REF_CLK_FREQ 100
#define SUSPEND_TIMEOUT_us          3000 
#define SUSPEND_TIMEOUT             (SUSPEND_TIMEOUT_us * REF_CLK_FREQ)

// Device attach timing defines
#define T_SIGATT_ULPI_us            5000     // 5ms
#define T_SIGATT_ULPI               (T_SIGATT_ULPI_us * REF_CLK_FREQ)
#define T_ATTDB_us                  1000000  // 1000ms
#define T_ATTDB                     (T_ATTDB_us * REF_CLK_FREQ)
#define T_UCHEND_T_UCH_us           1000000  // 1000ms
#define T_UCHEND_T_UCH              (T_UCHEND_T_UCH_us * REF_CLK_FREQ)
#define T_UCHEND_T_UCH_ULPI_us      2000     //    2ms
#define T_UCHEND_T_UCH_ULPI         (T_UCHEND_T_UCH_us * REF_CLK_FREQ)
#define T_FILT_us                   3       //   2.5us
#define T_FILT                      (T_FILT_us * REF_CLK_FREQ)

#define SUSPEND_T_WTWRSTHS_us       200     // 200us Time beforechecking for J after asserting XcvrSelect and Termselect
#define SUSPEND_T_WTWRSTHS          (SUSPEND_T_WTWRSTHS_us * REF_CLK_FREQ)

#define OUT_TIMEOUT_us              500     // How long we wait for data after OUT token
#define OUT_TIMEOUT                 (OUT_TIMEOUT_us * REF_CLK_FREQ)
#define TX_HANDSHAKE_TIMEOUT_us     5      // How long we wait for handshake after sending tx data
#define TX_HANDSHAKE_TIMEOUT        (TX_HANDSHAKE_TIMEOUT_us * REF_CLK_FREQ)

#endif
