// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_device.h"

/* Number of Endpoints used by this app */
#define EP_COUNT_OUT   1
#define EP_COUNT_IN    2

/* Endpoint type tables - informs XUD what the transfer types for each Endpoint in use and also
 * if the endpoint wishes to be informed of USB bus resets
 */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL};

/* Prototype for Endpoint0 function in endpoint0.xc */
void Endpoint0(chanend c_ep0_out, chanend c_ep0_in);

/* Global report buffer, global since used by Endpoint0 core */
unsigned char g_reportBuffer[4] = {0, 0, 0, 0};

/*
 * This function responds to the HID requests 
 * - It draws a square using the mouse moving 40 pixels in each direction
 * - The sequence repeats every 500 requests.
 */
void hid_mouse(chanend chan_ep_hid)
{
    int counter = 0;
    int state = 0;

    XUD_ep ep_hid = XUD_InitEp(chan_ep_hid);

    while (1)
    {
      /* Unsafe region so we can use shared memory. */
      unsafe {
        char * unsafe p_reportBuffer = g_reportBuffer;
        int x;
        p_reportBuffer[1] = 0;
        p_reportBuffer[2] = 0;

        /* Move the pointer around in a square (relative) */
        counter++;
        if (counter >= 500)
        {
            counter = 0;
            if (state == 0)
            {
                p_reportBuffer[1] = 40;
                p_reportBuffer[2] = 0;
                state+=1;
            }
            else if (state == 1)
            {
                p_reportBuffer[1] = 0;
                p_reportBuffer[2] = 40;
                state+=1;
            }
            else if (state == 2)
            {
                p_reportBuffer[1] = -40;
                p_reportBuffer[2] = 0;
                state+=1;
            }
            else if (state == 3)
            {
                p_reportBuffer[1] = 0;
                p_reportBuffer[2] = -40;
                state = 0;
            }
        }

        /* Send the buffer off to the host.  Note this will return when complete */
        XUD_SetBuffer(ep_hid, (char *) p_reportBuffer, 4);
      }
    }
}



/* The main function runs three cores: the XUD manager, Endpoint 0, and a HID endpoint. An array of
 * channels is used for both IN and OUT endpoints, endpoint zero requires both, HID requires just an
 * IN endpoint to send HID reports to the host.
 */
int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
      on tile[0]: XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                      null, epTypeTableOut, epTypeTableIn, 
                      null, null, -1 , XUD_SPEED_HS, XUD_PWR_BUS);

      on tile[0]: Endpoint0(c_ep_out[0], c_ep_in[0]);

      on tile[0]: hid_mouse(c_ep_in[1]);

    }

    return 0;
}
