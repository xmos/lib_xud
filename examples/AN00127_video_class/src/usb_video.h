// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef USB_VIDEO_H_
#define USB_VIDEO_H_

#include "xud_device.h"
#include "uvc_req.h"
#include "uvc_defs.h"

#define DEBUG 0

/* Function to handle all endpoints of the Video class excluding control endpoint0 */
void VideoEndpointsHandler(chanend c_epint_in, chanend c_episo_in);

/* Endpoint 0 handles both std USB requests and Video class-specific requests */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in);

#endif /* USB_VIDEO_H_ */
