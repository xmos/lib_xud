// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xcore/parallel.h>
#include <xcore/chanend.h>
#include <xcore/channel.h>
#include <xcore/hwtimer.h>

#include <xud_device.h>
#include "hid_defs.h"
#include "hid.h"

#include <stdio.h>

/* Number of Endpoints used by this app */
#define EP_COUNT_OUT   1
#define EP_COUNT_IN    2

/* Endpoint type tables - informs XUD what the transfer types for each Endpoint in use and also
 * if the endpoint wishes to be informed of USB bus resets
 */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = { XUD_EPTYPE_CTL | XUD_STATUS_ENABLE };
XUD_EpType epTypeTableIn[EP_COUNT_IN]   = { XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL };

/* It is essential that HID_REPORT_BUFFER_SIZE, defined in hid_defs.h, matches the   */
/* infered length of the report described in hidReportDescriptor above. In this case */
/* it is three bytes, three button bits padded to a byte, plus a byte each for X & Y */
unsigned char g_reportBuffer[HID_REPORT_BUFFER_SIZE] = {0, 0, 0};

/* HID Class Requests */
XUD_Result_t HidInterfaceClassRequests(XUD_ep c_ep0_out, XUD_ep c_ep0_in, USB_SetupPacket_t sp)
{
    unsigned buffer[64];

    switch(sp.bRequest)
    {
        case HID_GET_REPORT:

            /* Mandatory. Allows sending of report over control pipe */
            /* Send a hid report - note the use of unsafe due to shared mem */
            buffer[0] = g_reportBuffer[0];
            return XUD_DoGetRequest(c_ep0_out, c_ep0_in, (void*)buffer, 4, sp.wLength);
            break;

        case HID_GET_IDLE:
            /* Return the current Idle rate - optional for a HID mouse */

            /* Do nothing - i.e. STALL */
            break;

        case HID_GET_PROTOCOL:
            /* Required only devices supporting boot protocol devices,
             * which this example does not */

            /* Do nothing - i.e. STALL */
            break;

         case HID_SET_REPORT:
            /* The host sends an Output or Feature report to a HID
             * using a cntrol transfer - optional */

            /* Do nothing - i.e. STALL */
            break;

        case HID_SET_IDLE:
            /* Set the current Idle rate - this is optional for a HID mouse
             * (Bandwidth can be saved by limiting the frequency that an
             * interrupt IN EP when the data hasn't changed since the last
             * report */

            /* Do nothing - i.e. STALL */
            break;

        case HID_SET_PROTOCOL:
            /* Required only devices supporting boot protocol devices,
             * which this example does not */

            /* Do nothing - i.e. STALL */
            break;
    }

    return XUD_RES_ERR;
}

DECLARE_JOB(Endpoint0, (chanend_t, chanend_t));
/* Endpoint 0 Task */
void Endpoint0(chanend_t chan_ep0_out, chanend_t chan_ep0_in)
{
    USB_SetupPacket_t sp;

    unsigned bmRequestType;
    XUD_BusSpeed_t usbBusSpeed;

    printf("Endpoint0: out: %x\n", chan_ep0_out);
    printf("Endpoint0: in:  %x\n", chan_ep0_in);

    XUD_ep ep0_out = XUD_InitEp(chan_ep0_out);
    XUD_ep ep0_in  = XUD_InitEp(chan_ep0_in);

    while(1)
    {
        /* Returns XUD_RES_OKAY on success */
        XUD_Result_t result = USB_GetSetupPacket(ep0_out, ep0_in, &sp);

        if(result == XUD_RES_OKAY)
        {
            /* Set result to ERR, we expect it to get set to OKAY if a request is handled */
            result = XUD_RES_ERR;

            /* Stick bmRequest type back together for an easier parse... */
            bmRequestType = (sp.bmRequestType.Direction << 7) |
                            (sp.bmRequestType.Type << 5) |
                            (sp.bmRequestType.Recipient);

            if ((bmRequestType == USB_BMREQ_H2D_STANDARD_DEV) &&
                (sp.bRequest == USB_SET_ADDRESS))
            {
              // Host has set device address, value contained in sp.wValue
            }

            switch(bmRequestType)
            {
                /* Direction: Device-to-host
                 * Type: Standard
                 * Recipient: Interface
                 */
                case USB_BMREQ_D2H_STANDARD_INT:

                    if(sp.bRequest == USB_GET_DESCRIPTOR)
                    {
                        /* HID Interface is Interface 0 */
                        if(sp.wIndex == 0)
                        {
                            /* Look at Descriptor Type (high-byte of wValue) */
                            unsigned short descriptorType = sp.wValue & 0xff00;

                            switch(descriptorType)
                            {
                                case HID_HID:
                                    result = XUD_DoGetRequest(ep0_out, ep0_in, hidDescriptor, sizeof(hidDescriptor), sp.wLength);
                                    break;

                                case HID_REPORT:
                                    result = XUD_DoGetRequest(ep0_out, ep0_in, hidReportDescriptor, sizeof(hidReportDescriptor), sp.wLength);
                                    break;
                            }
                        }
                    }
                    break;

                /* Direction: Device-to-host and Host-to-device
                 * Type: Class
                 * Recipient: Interface
                 */
                case USB_BMREQ_H2D_CLASS_INT:
                case USB_BMREQ_D2H_CLASS_INT:

                    /* Inspect for HID interface num */
                    if(sp.wIndex == 0)
                    {
                        /* Returns  XUD_RES_OKAY if handled,
                         *          XUD_RES_ERR if not handled,
                         *          XUD_RES_RST for bus reset */
                        result = HidInterfaceClassRequests(ep0_out, ep0_in, sp);
                    }
                    break;
            }
        }

        /* If we haven't handled the request about then do standard enumeration requests */
        if(result == XUD_RES_ERR )
        {
            /* Returns  XUD_RES_OKAY if handled okay,
             *          XUD_RES_ERR if request was not handled (STALLed),
             *          XUD_RES_RST for USB Reset */

            hwtimer_realloc_xc_timer(); // realocate logical core xC hw timer

            result = USB_StandardRequests(ep0_out, ep0_in, devDesc,
                        sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
                        NULL, 0, NULL, 0, stringDescriptors, sizeof(stringDescriptors)/sizeof(stringDescriptors[0]),
                        &sp, usbBusSpeed);

            hwtimer_free_xc_timer();    // free timer
        }

        /* USB bus reset detected, reset EP and get new bus speed */
        if(result == XUD_RES_RST)
        {
            usbBusSpeed = XUD_ResetEndpoint(ep0_out, &ep0_in);
        }
    }
}

DECLARE_JOB(hid_mouse, (chanend_t));
/*
 * This function responds to the HID requests
 * - It draws a square using the mouse moving 40 pixels in each direction
 * - The sequence repeats every 500 requests.
 */
void hid_mouse(chanend_t chan_ep_hid)
{
    unsigned int counter = 0;
    enum {RIGHT, DOWN, LEFT, UP} state = RIGHT;

    printf("hid_mouse: %x\n", chan_ep_hid);
    XUD_ep ep_hid = XUD_InitEp(chan_ep_hid);

    for(;;)
    {
        /* Move the pointer around in a square (relative) */
        if(counter++ >= 500)
        {
            int x;
            int y;

            switch(state) {
            case RIGHT:
                x = 40;
                y = 0;
                state = DOWN;
                break;

            case DOWN:
                x = 0;
                y = 40;
                state = LEFT;
                break;

            case LEFT:
                x = -40;
                y = 0;
                state = UP;
                break;

            case UP:
            default:
                x = 0;
                y = -40;
                state = RIGHT;
                break;
            }

            /* Unsafe region so we can use shared memory. */
                /* global buffer 'g_reportBuffer' defined in hid_defs.h */
                g_reportBuffer[1] = x;
                g_reportBuffer[2] = y;

                /* Send the buffer off to the host.  Note this will return when complete */
                XUD_SetBuffer(ep_hid, (void*)g_reportBuffer, sizeof(g_reportBuffer));
                counter = 0;
        }
    }
}

DECLARE_JOB(_XUD_Main, (chanend_t*, int, chanend_t*, int, chanend_t, XUD_EpType*, XUD_EpType*, XUD_BusSpeed_t, XUD_PwrConfig));
void _XUD_Main(chanend_t *c_epOut, int noEpOut, chanend_t *c_epIn, int noEpIn, chanend_t c_sof, XUD_EpType *epTypeTableOut, XUD_EpType *epTypeTableIn, XUD_BusSpeed_t desiredSpeed, XUD_PwrConfig pwrConfig)
{
    for(int i = 0; i < EP_COUNT_OUT; ++i) {
        printf("out[%d]: %x\n", i, c_epOut[i]);
    }
    for(int i = 0; i < EP_COUNT_IN; ++i) {
        printf("in[%d]: %x\n", i, c_epIn[i]);
    }
    XUD_Main(c_epOut, noEpOut, c_epIn, noEpIn, c_sof,
        epTypeTableOut, epTypeTableIn, desiredSpeed, pwrConfig);
}

int main()
{
    channel_t channel_ep_out[EP_COUNT_OUT];
    channel_t channel_ep_in[EP_COUNT_IN];

    for(int i = 0; i < sizeof(channel_ep_out) / sizeof(*channel_ep_out); ++i) {
        channel_ep_out[i] = chan_alloc();
    }
    for(int i = 0; i < sizeof(channel_ep_in) / sizeof(*channel_ep_in); ++i) {
        channel_ep_in[i] = chan_alloc();
    }

    chanend_t c_ep_out[EP_COUNT_OUT];
    chanend_t c_ep_in[EP_COUNT_IN];

    for(int i = 0; i < EP_COUNT_OUT; ++i) {
        c_ep_out[i] = channel_ep_out[i].end_a;
    }
    for(int i = 0; i < EP_COUNT_IN; ++i) {
        c_ep_in[i] = channel_ep_in[i].end_a;
    }

    PAR_JOBS(
        PJOB(_XUD_Main, (c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN, 0, epTypeTableOut, epTypeTableIn, XUD_SPEED_HS, XUD_PWR_BUS)),
        PJOB(Endpoint0, (channel_ep_out[0].end_b, channel_ep_in[0].end_b)),
        PJOB(hid_mouse, (channel_ep_in[1].end_b))
    );

    return 0;
}
