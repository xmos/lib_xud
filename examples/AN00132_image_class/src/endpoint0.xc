// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/*
 * @brief Implements endpoint zero for an example image acquisition device.
 */
#include <xs1.h>
#include <string.h>

#include "xud_device.h"

/* USB Device ID defines */
#define BCD_DEVICE   0x1000
#define VENDOR_ID    0x20B1
#define PRODUCT_ID   0x00C1

/* USB Still Image Capture Class defines */
#define STILL_IMAGE_SUBCLASS 0x01
#define STILL_IMAGE_PROTOCOL 0x01

/* Class-Specific Requests - bRequest values */
#define STILL_IMAGE_CANCEL_REQUEST      0x64
#define STILL_IMAGE_GET_EXT_EVENT_DATA  0x65
#define STILL_IMAGE_DEV_RESET_REQ       0x66
#define STILL_IMAGE_GET_DEV_STATUS      0x67

/* Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType */
    0x10,                  /* 2  bcdUSB */
    0x01,                  /* 3  bcdUSB */
    0x00,                  /* 4  bDeviceClass */
    0x00,                  /* 5  bDeviceSubClass */
    0x00,                  /* 6  bDeviceProtocol */
    0x40,                  /* 7  bMaxPacketSize */
    (VENDOR_ID & 0xFF),    /* 8  idVendor */
    (VENDOR_ID >> 8),      /* 9  idVendor */
    (PRODUCT_ID & 0xFF),   /* 10 idProduct */
    (PRODUCT_ID >> 8),     /* 11 idProduct */
    (BCD_DEVICE & 0xFF),   /* 12 bcdDevice */
    (BCD_DEVICE >> 8),     /* 13 bcdDevice */
    0x01,                  /* 14 iManufacturer */
    0x02,                  /* 15 iProduct */
    0x03,                  /* 16 iSerialNumber */
    0x01                   /* 17 bNumConfigurations */
};



static unsigned char cfgDesc[] = {
    /* Configuration Descriptor */
    0x09,                       /* 0  bLength */
    USB_DESCTYPE_CONFIGURATION, /* 1  bDescriptortype */
    0x27, 0x00,                 /* 2  wTotalLength = 39*/
    0x01,                       /* 4  bNumInterfaces */
    0x01,                       /* 5  bConfigurationValue */
    0x04,                       /* 6  iConfiguration */
    0x80,                       /* 7  bmAttributes - Bus powered */
    0xFA,                       /* 8  bMaxPower - 500 mA*/

    /* Interface Descriptor */
    0x09,                       /* 0  bLength */
    USB_DESCTYPE_INTERFACE,     /* 1  bDescriptorType */
    0x00,                       /* 2  bInterfacecNumber */
    0x00,                       /* 3  bAlternateSetting */
    0x03,                       /* 4: bNumEndpoints */
    USB_CLASS_IMAGE,            /* 5: bInterfaceClass */
    STILL_IMAGE_SUBCLASS,       /* 6: bInterfaceSubClass */
    STILL_IMAGE_PROTOCOL,       /* 7: bInterfaceProtocol*/
    0x00,                       /* 8  iInterface */

    /* Data-in Bulk Endpoint Descriptor */
    0x07,                     /* 0  bLength */
    USB_DESCTYPE_ENDPOINT,    /* 1  bDescriptorType */
    0x01,                     /* 2  bEndpointAddress - Data EP1 OUT */
    0x02,                     /* 3  bmAttributes - Bulk transfer*/
    0x40,                     /* 4  wMaxPacketSize - set to 64 */
    0x00,                     /* 5  wMaxPacketSize */
    0x00,                     /* 6  bInterval */

    /* Data-out Bulk Endpoint Descriptor */
    0x07,                     /* 0  bLength */
    USB_DESCTYPE_ENDPOINT,    /* 1  bDescriptorType */
    0x81,                     /* 2  bEndpointAddress - Data EP1 IN */
    0x02,                     /* 3  bmAttributes - Bulk transfer*/
    0x40,                     /* 4  wMaxPacketSize */
    0x00,                     /* 5  wMaxPacketSize */
    0x00,                     /* 6  bInterval */

    /* Interrupt Endpoint Descriptor */
    0x07,                     /* 0  bLength */
    USB_DESCTYPE_ENDPOINT,    /* 1  bDescriptorType */
    0x82,                     /* 2  bEndpointAddress - Data EP1 IN */
    0x03,                     /* 3  bmAttributes - Interrupt transfer*/
    0x40,                     /* 4  wMaxPacketSize */
    0x00,                     /* 5  wMaxPacketSize */
    0x01                      /* 6  bInterval */

};


unsafe{
/* String table */
static char * unsafe stringDescriptors[]=
{
    "\x09\x04",                   // Language ID string (US English)
    "XMOS",                       // iManufacturer
    "USB Still Image Capture",    // iProduct
    "0123456789",                 // iSerialNumber
    "config",                     // iConfiguration
};}

/* Still Image Class-Specific Requests */
XUD_Result_t StillImageClassRequests(XUD_ep c_ep0_out, XUD_ep c_ep0_in, USB_SetupPacket_t sp)
{
    unsigned buffer[64];
    unsigned TransactionID, length;
    XUD_Result_t result;

    switch(sp.bRequest)
    {
        case STILL_IMAGE_CANCEL_REQUEST:
            /* Receives the transaction ID that was cancelled by the host */
            if((result = XUD_GetBuffer(c_ep0_out, (buffer, unsigned char[]), length)) != XUD_RES_OKAY)
            {
                return result;
            }
            memcpy (&TransactionID, &(buffer, unsigned char[])[2], 4);
            result = XUD_DoSetRequestStatus(c_ep0_in);
            return result;
            break;

        case STILL_IMAGE_GET_EXT_EVENT_DATA:
            /* Transfers the extended information on an asynchronous event stored in the buffer to the host */
            return XUD_DoGetRequest(c_ep0_out, c_ep0_in, (buffer, unsigned char[]), length, sp.wLength);
            break;

        case STILL_IMAGE_DEV_RESET_REQ:
            /* Put the device in the idle state */
            result = XUD_DoSetRequestStatus(c_ep0_in);
            return result;
            break;

         case STILL_IMAGE_GET_DEV_STATUS:
            /* Transfers information regarding the status of the device */
            return XUD_DoGetRequest(c_ep0_out, c_ep0_in, (buffer, unsigned char[]), length, sp.wLength);
            break;

         default:
             /* Error */
             return XUD_RES_ERR;
             break;

    }
    /* Never hit */
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
            bmRequestType = (sp.bmRequestType.Direction<<7) | (sp.bmRequestType.Type<<5) |
                            (sp.bmRequestType.Recipient);

             /* Handle specific requests first */
            switch(bmRequestType)
            {
                /* Direction: Device-to-host and Host-to-device
                 * Type: Class      Recipient: Interface
                 */
                case USB_BMREQ_H2D_CLASS_INT:
                case USB_BMREQ_D2H_CLASS_INT:

                    if(sp.wIndex == 0)
                        /* Returns  XUD_RES_OKAY if handled, XUD_RES_ERR if not handled,
                         *          XUD_RES_RST for bus reset */
                        result = StillImageClassRequests(ep0_out, ep0_in, sp);
                    break;
            }
        }

        /* If we haven't handled the request above then do standard enumeration requests */
        if(result == XUD_RES_ERR)
            /* Returns  XUD_RES_OKAY if handled okay, XUD_RES_RST if USB Reset,
             *          XUD_RES_ERR if request was not handled (i.e. STALLed) */
            result = USB_StandardRequests(ep0_out, ep0_in, devDesc, sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
                        null, 0, null, 0, stringDescriptors,
                        sizeof(stringDescriptors)/sizeof(stringDescriptors[0]), sp, usbBusSpeed);

        /* USB bus reset detected, reset EP and get new bus speed */
        if(result == XUD_RES_RST)
            usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
    }
}

