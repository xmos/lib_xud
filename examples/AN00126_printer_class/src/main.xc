// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_device.h"
#include "debug_print.h"
#include <xscope.h>

/* USB Endpoint Defines */
#define XUD_EP_COUNT_OUT   2    //Includes EP0 (1 out EP0 + Printer data output EP)
#define XUD_EP_COUNT_IN    1    //Includes EP0 (1 in EP0)


/* Endpoint type tables - informs XUD what the transfer types for each Endpoint in use and also
 * if the endpoint wishes to be informed of USB bus resets
 */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};

/* xSCOPE Setup Function */
#if (USE_XSCOPE == 1)
void xscope_user_init(void) {
    xscope_register(0, 0, "", 0, "");
    xscope_config_io(XSCOPE_IO_BASIC); /* Enable fast printing over links */
}
#endif

/* Prototype for Endpoint0 function in endpoint0.xc */
void Endpoint0(chanend c_ep0_out, chanend c_ep0_in);

/* Global report buffer, global since used by Endpoint0 core */
unsigned char g_reportBuffer[] = {0, 0, 0, 0};

/* Version of print string that doesn't terminate on null */
void print_string(unsigned char *string, unsigned size)
{
    for (int i=0; i<size; i++)
    {
        switch(*string){
            /* ignore nulls */
            case 0x00:
            break;

#ifdef IGNORE_WHITESPACE
            case 0x20:  //space
            case 0x0a:  //tab
            break;
#endif

            default:
            printchar(*string);
            break;
        }
        string++;
    }
    printchar('\n');
}

/* This function receives the printer endpoint transfers from the host */
void printer_main(chanend c_ep_prt_out)
{
    unsigned size;
    unsigned char print_packet[1024]; // Buffer for storing printer packets sent from host

    debug_printf("USB printer class demo started\n");

    /* Initialise the XUD endpoints */
    XUD_ep ep_out = XUD_InitEp(c_ep_prt_out);

    while (1)
    {
        // Perform a blocking read waiting for data to be received at the endpoint
        XUD_GetBuffer(ep_out, print_packet, size);
        debug_printf("**** Received %d byte print buffer ****\n", size);
        print_string(print_packet, size);
    }
}

/* The main function runs three cores: the XUD manager, Endpoint 0, and a Printer endpoint. An array of
   channels is used for both IN and OUT endpoints */
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        on USB_TILE: XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        on USB_TILE: Endpoint0(c_ep_out[0], c_ep_in[0]);

        on USB_TILE: printer_main(c_ep_out[1]);

    }
    return 0;
}
