// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <platform.h>
#include "xud_device.h"

#define XUD_EP_COUNT_OUT   2
#define XUD_EP_COUNT_IN    2

/* Endpoint type tables - informs XUD what the transfer types for each Endpoint in use and also
 * if the endpoint wishes to be informed of USB bus resets
 */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL | XUD_STATUS_ENABLE};


/* Prototype for Endpoint0 function in endpoint0.xc */
void Endpoint0(chanend c_ep0_out, chanend c_ep0_in);

#define BUFFER_SIZE 128

/* A optimized endpoint for the read benchmark test
 * both host and device stay in sync.
 */
void bulk_endpoint_read_benchmark(chanend chan_ep_from_host, chanend chan_ep_to_host)
{
    char host_transfer_buf[BUFFER_SIZE*4];
    unsigned host_transfer_length = 512;

    XUD_ep ep_to_host = XUD_InitEp(chan_ep_to_host);
    XUD_ep ep_from_host = XUD_InitEp(chan_ep_from_host);

    while(1)
    {
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
        XUD_SetBuffer(ep_to_host, host_transfer_buf, host_transfer_length);
    }
}


/* A basic endpoint function that receives 512-byte packets of data, processes
 * them and sends them back to the host. If at any point an error is detected
 * (return value < 0) then the process needs to be started again so that
 * both host and device stay in sync.
 */
void bulk_endpoint(chanend chan_ep_from_host, chanend chan_ep_to_host)
{
    int host_transfer_buf[BUFFER_SIZE];
    unsigned host_transfer_length = 0;
    XUD_Result_t result;

    XUD_ep ep_from_host = XUD_InitEp(chan_ep_from_host);
    XUD_ep ep_to_host = XUD_InitEp(chan_ep_to_host);

    while(1)
    {
        /* Receive a buffer (512-bytes) of data from the host */
        if((result = XUD_GetBuffer(ep_from_host, (host_transfer_buf, char[BUFFER_SIZE * 4]), host_transfer_length)) == XUD_RES_RST)
        {
            XUD_ResetEndpoint(ep_from_host, ep_to_host);
            continue;
        }

        /* Perform basic processing (increment data) */
        for (int i = 0; i < host_transfer_length/4; i++)
            host_transfer_buf[i]++;

        /* Send the modified buffer back to the host */
        if((result = XUD_SetBuffer(ep_to_host, (host_transfer_buf, char[BUFFER_SIZE * 4]), host_transfer_length)) == XUD_RES_RST)
        {
            XUD_ResetEndpoint(ep_from_host, ep_to_host);
        }
    }
}

/* The main function runs three tasks: the XUD manager, Endpoint 0, and bulk
 * endpoint. An array of channels is used for both IN and OUT endpoints,
 * endpoint zero requires both, bulk endpoint requires an IN and an OUT endpoint
 * to receive and send a data buffer to the host.
 */
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        on USB_TILE: XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                      null, epTypeTableOut, epTypeTableIn,
                      XUD_SPEED_HS, XUD_PWR_BUS);


        on USB_TILE: Endpoint0(c_ep_out[0], c_ep_in[0]);

        on USB_TILE: bulk_endpoint(c_ep_out[1], c_ep_in[1]);
    }

    return 0;
}
