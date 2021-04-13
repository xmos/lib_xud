// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/*
 * @brief Implements endpoint zero for an example Printer class device.
 */

#include <xs1.h>
#include "xud_device.h"
#include "debug_print.h"

/* USB Device ID Defines */
#define BCD_DEVICE   0x1000
#define VENDOR_ID    0x20B1
#define PRODUCT_ID   0x00ed

/* USB Printer Subclass Definition */
#define USB_PRINTER_SUBCLASS        0x01

/* USB Printer interface types */
#define USB_PRINTER_UNIDIRECTIONAL  0x01
#define USB_PRINTER_BIDIRECTIONAL   0x02
#define USB_PRINTER_1284_4_COMPAT   0x03

/* USB Printer Request types */
#define PRINTER_GET_DEVICE_ID       0x00
#define PRINTER_GET_PORT_STATUS     0x01
#define PRINTER_SOFT_RESET          0x02

/* USB Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType */
    0x00,                  /* 2  bcdUSB version */
    0x02,                  /* 3  bcdUSB version */
    0x00,                  /* 4  bDeviceClass - Specified by interface */
    0x00,                  /* 5  bDeviceSubClass  - Specified by interface */
    0x00,                  /* 6  bDeviceProtocol  - Specified by interface */
    0x40,                  /* 7  bMaxPacketSize for EP0 - max = 64*/
    (VENDOR_ID & 0xFF),    /* 8  idVendor */
    (VENDOR_ID >> 8),      /* 9  idVendor */
    (PRODUCT_ID & 0xFF),   /* 10 idProduct */
    (PRODUCT_ID >> 8),     /* 11 idProduct */
    (BCD_DEVICE & 0xFF),   /* 12 bcdDevice */
    (BCD_DEVICE >> 8),     /* 13 bcdDevice */
    0x01,                  /* 14 iManufacturer - index of string*/
    0x02,                  /* 15 iProduct  - index of string*/
    0x00,                  /* 16 iSerialNumber  - index of string*/
    0x01                   /* 17 bNumConfigurations */
};

/* USB Configuration Descriptor */
static unsigned char cfgDesc[] = {
    0x09,                 /* 0  bLength */
    USB_DESCTYPE_CONFIGURATION, /* 1  bDescriptortype = configuration*/
    0x19, 0x00,           /* 2  wTotalLength of all descriptors */
    0x01,                 /* 4  bNumInterfaces */
    0x01,                 /* 5  bConfigurationValue */
    0x03,                 /* 6  iConfiguration - index of string*/
    0x40,                 /* 7  bmAttributes - Self powered*/
    0xFA,                 /* 8  bMaxPower - 500mA */

    0x09,                 /* 0  bLength */
    USB_DESCTYPE_INTERFACE,/* 1  bDescriptorType */
    0x00,                 /* 2  bInterfacecNumber */
    0x00,                 /* 3  bAlternateSetting */
    0x01,                 /* 4: bNumEndpoints */
    USB_CLASS_PRINTER,    /* 5: bInterfaceClass */
    USB_PRINTER_SUBCLASS, /* 6: bInterfaceSubClass */
    USB_PRINTER_UNIDIRECTIONAL, /* 7: bInterfaceProtocol*/
    0x00,                 /* 8  iInterface */

    0x07,                 /* 0  bLength */
    USB_DESCTYPE_ENDPOINT,/* 1  bDescriptorType */
    0x01,                 /* 2  bEndpointAddress - EP1, OUT*/
    XUD_EPTYPE_BUL,       /* 3  bmAttributes */
    0x00,                 /* 4  wMaxPacketSize - Low */
    0x02,                 /* 5  wMaxPacketSize - High */
    0x01,                 /* 6  bInterval */
};

unsafe{
  /* String table - unsafe as accessed via shared memory */
  static char * unsafe stringDescriptors[]=
  {
    "\x09\x04",             // Language ID string (US English)
    "XMOS",                 // iManufacturer
    "Printomatic 2000",     // iProduct
    "Test config",          // iConfiguration string
  };
}

/* Class specific string IEEE1288 string descriptor */
static unsigned char deviceIDstring[] = "  MFG:Generic;MDL:Generic_/_Text_Only;CMD:1284.4;CLS:PRINTER;DES:Generic text only printer;";

/*
       "MFG:Generic;"                     -   manufacturer (case sensitive)
       "MDL:Generic_/_Text_Only;"         -   model (case sensitive)
       "CMD:1284.4;"                      -   PDL command set
       "CLS:PRINTER;"                     -   class
       "DES:Generic text only printer;"   -   description
*/


/* Printer Class Requests */
XUD_Result_t PrinterInterfaceClassRequests(XUD_ep c_ep0_out, XUD_ep c_ep0_in, USB_SetupPacket_t sp)
{
    unsigned char PRT_STATUS[] = {0b00011000}; /* Paper not empty, selected, no error */

    deviceIDstring[0] = 0;
    deviceIDstring[1] = sizeof(deviceIDstring-1);

    switch(sp.bRequest)
    {
        case PRINTER_GET_DEVICE_ID:
            debug_printf("Class request - get device id\n");
            debug_printf(&deviceIDstring[2]); //Skip first two characters
            debug_printf("\n");

            return XUD_DoGetRequest(c_ep0_out, c_ep0_in, (deviceIDstring, unsigned char []),
                    sizeof(deviceIDstring-1), sp.wLength);
            break;

        case PRINTER_GET_PORT_STATUS:
            debug_printf("Class request - get port status id\n");
            return XUD_DoGetRequest(c_ep0_out, c_ep0_in, PRT_STATUS, 1, sp.wLength);
            break;

        case PRINTER_SOFT_RESET:
            debug_printf("Class request - soft reset id\n");
            /* Do nothing - i.e. STALL */
            /* TODO flush buffers and reset Bulk Out endpoint to default state*/
            break;
    }

    return XUD_RES_ERR;
}

/* Endpoint 0 Task */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in)
{
    USB_SetupPacket_t sp;

    unsigned bmRequestType;
    XUD_BusSpeed_t usbBusSpeed;

    XUD_ep ep0_out = XUD_InitEp(chan_ep0_out);
    XUD_ep ep0_in  = XUD_InitEp(chan_ep0_in);

    while(1)
    {
        /* Returns XUD_RES_OKAY on success */
        XUD_Result_t result = USB_GetSetupPacket(ep0_out, ep0_in, sp);

        if(result == XUD_RES_OKAY)
        {
            /* Set result to ERR, we expect it to get set to OKAY if a request is handled */
            result = XUD_RES_ERR;

            /* Stick bmRequest type back together for an easier parse... */
            bmRequestType = (sp.bmRequestType.Direction<<7) |
                            (sp.bmRequestType.Type<<5) |
                            (sp.bmRequestType.Recipient);

            if(USE_XSCOPE)
            {
                if ((bmRequestType == USB_BMREQ_H2D_STANDARD_DEV) &&
                    (sp.bRequest == USB_SET_ADDRESS))
                {
                    debug_printf("Address allocated %d\n", sp.wValue);
                }
            }

            /* Handle specific requests first */
            switch(bmRequestType)
            {

                /* Direction: Device-to-host and Host-to-device
                 * Type: Class
                 * Recipient: Interface
                 */
                case USB_BMREQ_H2D_CLASS_INT:
                case USB_BMREQ_D2H_CLASS_INT:

                    /* Inspect for printer interface num */
                    if(sp.wIndex == 0)
                    {
                        /* Returns  XUD_RES_OKAY if handled,
                         *          XUD_RES_ERR if not handled,
                         *          XUD_RES_RST for bus reset */
                        result = PrinterInterfaceClassRequests(ep0_out, ep0_in, sp);
                    }
                    break;
            }
        }

        /* If we haven't handled the request above then do standard enumeration requests */
        if(result == XUD_RES_ERR )
        {
            /* Returns  XUD_RES_OKAY if handled okay,
             *          XUD_RES_ERR if request was not handled (STALLed),
             *          XUD_RES_RST for USB Reset */
             unsafe{
             result = USB_StandardRequests(ep0_out, ep0_in, devDesc,
                        sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
                        null, 0, null, 0, stringDescriptors, sizeof(stringDescriptors)/sizeof(stringDescriptors[0]),
                        sp, usbBusSpeed);
             }
        }

        /* USB bus reset detected, reset EP and get new bus speed */
        if(result == XUD_RES_RST)
        {
            usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
        }
    }
}







