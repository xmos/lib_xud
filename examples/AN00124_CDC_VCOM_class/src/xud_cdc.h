// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef XUD_CDC_H_
#define XUD_CDC_H_

#include <xccompat.h>
#include "xud_device.h"

#define DEBUG 0

interface usb_cdc_interface {

    [[guarded]] void put_char(char byte);

    [[guarded]] char get_char(void);

    [[guarded]] int write(unsigned char data[], REFERENCE_PARAM(unsigned, length));

    [[guarded]] int read(unsigned char data[], REFERENCE_PARAM(unsigned, count));

    int available_bytes(void);

    void flush_buffer(void);
};

/* Endpoint 0 handling both std USB requests and CDC class specific requests */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in);

/* Function to handle all endpoints of the CDC class excluding control endpoint0 */
void CdcEndpointsHandler(chanend c_epint_in, chanend c_epbulk_out, chanend c_epbulk_in,
                         SERVER_INTERFACE(usb_cdc_interface, cdc));

#endif /* XUD_CDC_H_ */
