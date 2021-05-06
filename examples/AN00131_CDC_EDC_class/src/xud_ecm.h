// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef XUD_ECM_H_
#define XUD_ECM_H_

#include <xccompat.h>
#include "xud.h"

#define DEBUG 0

/* Interface to receive or transmit Ethernet frames
 * via USB endpoints */
interface usb_cdc_ecm_if {

    int is_frame_available();

    [[guarded]] void read_frame(unsigned char buf[], REFERENCE_PARAM(unsigned, length));

    [[guarded]] void send_frame(unsigned char buf[], REFERENCE_PARAM(unsigned, length));

};

/* Function to handle all endpoints of the CDC class excluding control endpoint0
 * It manages the data endpoints, handles buffers and also provides xC interface
 * for applications to receive or transmit Ethernet frames */
void CdcEcmEndpointsHandler(chanend c_epint_in, chanend c_epbulk_out, chanend c_epbulk_in,
                            SERVER_INTERFACE(usb_cdc_ecm_if, cdc_ecm));

/* Endpoint 0 handles both std USB requests and CDC class specific requests */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in);


#endif /* __XUD_ECM_H__ */
