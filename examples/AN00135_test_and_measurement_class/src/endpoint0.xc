// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/*
 * @brief Implements endpoint zero for an example USBTMC test device class
 */

#include <xs1.h>
#include <string.h>
#include "xud_device.h"

/* USB Device ID Defines */
#define BCD_DEVICE   0x0126
#define VENDOR_ID    0x20B1
#define PRODUCT_ID   0x2337

/* Vendor specific class defines */
#define VENDOR_SPECIFIC_CLASS    0x00
#define VENDOR_SPECIFIC_SUBCLASS 0x00
#define VENDOR_SPECIFIC_PROTOCOL 0x00

#define MANUFACTURER_STR_INDEX  0x0001
#define PRODUCT_STR_INDEX       0x0002

/*0 - USBTMC interface. No subclass specification applies. */
/*1 - USBTMC USB488 interface; not supported in this demo */
#define USBTMC_SUB_CLASS_SUPPORT    0x00

/* 4. Requests */
/* 4.2 Class-Specific Requests - bRequest values */
#define INITIATE_ABORT_BULK_OUT     0x01
#define CHECK_ABORT_BULK_OUT_STATUS 0x02
#define INITIATE_ABORT_BULK_IN      0x03
#define CHECK_ABORT_BULK_IN_STATUS  0x04
#define INITIATE_CLEAR              0x05
#define CHECK_CLEAR_STATUS          0x06
#define GET_CAPABILITIES            0x07
/* 8 - 63 reserved */
#define INDICATOR_PULSE             0x40    /* Optional */

/* 4.3 USB488 subclass specific requests */
#define READ_STATUS_BYTE        0x80        /* Required. 128 - Returns the IEEE 488 Status Byte */
#define REN_CONTROL             0xA0        /* Optional. 160 - Mechanism to enable or disable local controls on a device */
#define GO_TO_LOCAL             0xA1        /* Optional. 161 - Mechanism to enable local controls on a device */
#define LOCAL_LOCKOUT           0xA2        /* Optional. 162 - Mechanism to disable local controls on a device */

/* Table 16 -- USBTMC_status values */
typedef enum USBTMC_status
{
    STATUS_SUCCESS = 0x01,
    STATUS_PENDING = 0x02,
    STATUS_FAILED = 0x80,
    STATUS_TRANSFER_NOT_IN_PROGRESS = 0x81,
    STATUS_SPLIT_NOT_IN_PROGRESS = 0x82,
    STATUS_SPLIT_IN_PROGRESS = 0x83,
} USBTMC_status_t;

/* USB Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType */
    0x00,                  /* 2  bcdUSB version */
    0x02,                  /* 3  bcdUSB version */
    VENDOR_SPECIFIC_CLASS, /* 4  bDeviceClass - Specified by interface */
    VENDOR_SPECIFIC_SUBCLASS, /* 5  bDeviceSubClass  - Specified by interface */
    VENDOR_SPECIFIC_PROTOCOL, /* 6  bDeviceProtocol  - Specified by interface */
    0x40,                  /* 7  bMaxPacketSize for EP0 - max = 64*/
    (VENDOR_ID & 0xFF),    /* 8  idVendor */
    (VENDOR_ID >> 8),      /* 9  idVendor */
    (PRODUCT_ID & 0xFF),   /* 10 idProduct */
    (PRODUCT_ID >> 8),     /* 11 idProduct */
    (BCD_DEVICE & 0xFF),   /* 12 bcdDevice */
    (BCD_DEVICE >> 8),     /* 13 bcdDevice */
    MANUFACTURER_STR_INDEX, /* 14 iManufacturer - index of string*/
    PRODUCT_STR_INDEX,     /* 15 iProduct  - index of string*/
    0x05,                  /* 16 iSerialNumber  - index of string*/
    0x01                   /* 17 bNumConfigurations */
};

/* USB Configuration Descriptor */
static unsigned char cfgDesc[] = {
    /* */
    0x09,                 /* 0  bLength */
    USB_DESCTYPE_CONFIGURATION, /* 1  bDescriptortype = configuration*/
    0x20, 0x00,           /* 2  wTotalLength of all descriptors */
    0x01,                 /* 4  bNumInterfaces */
    0x01,                 /* 5  bConfigurationValue */
    0x00,                 /* 6  iConfiguration - index of string*/
    0x80,                 /* 7  bmAttributes - Self powered*/
    0x64,                 /* 8  bMaxPower - 200mA */

    /* */
    0x09,                 /* 0  bLength */
    USB_DESCTYPE_INTERFACE,/* 1  bDescriptorType */
    0x00,                 /* 2  bInterfacecNumber */
    0x00,                 /* 3  bAlternateSetting */
    0x02,                 /* 4: bNumEndpoints */
    0xFE,                 /* 5: bInterfaceClass */
    0x03,                 /* 6: bInterfaceSubClass */
    USBTMC_SUB_CLASS_SUPPORT, /* 7: bInterfaceProtocol*/
    0x03,                 /* 8  iInterface */

    /* */
    0x07,                 /* 0  bLength */
    USB_DESCTYPE_ENDPOINT,/* 1  bDescriptorType */
    0x01,                 /* 2  bEndpointAddress - EP2, OUT*/
    XUD_EPTYPE_BUL,       /* 3  bmAttributes */
    0x00,                 /* 4  wMaxPacketSize - Low */
    0x02,                 /* 5  wMaxPacketSize - High */
    0x01,                 /* 6  bInterval */

    /* */
    0x07,                 /* 0  bLength */
    USB_DESCTYPE_ENDPOINT,/* 1  bDescriptorType */
    0x81,                 /* 2  bEndpointAddress - EP1, IN*/
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
    "XMOS TestMeasuement device",         // iProduct
    "USBTMC",                     // iInterface
    "Config",           // iConfiguration string
    "XD0701MQFZkDt_"
  };
}

XUD_Result_t ControlInterfaceClassRequests(XUD_ep ep_out, XUD_ep ep_in, USB_SetupPacket_t sp)
{
    XUD_Result_t result = XUD_RES_ERR;

    static struct dev_capabilities {
        unsigned char USBTMC_status;
        unsigned char reserved_1;
        unsigned char bcdUSBTMC[2];
        unsigned char USBTMC_Int_Capabilities;
        unsigned char USBTMC_Dev_Capabilities;
        unsigned char reserved_2[6];
        unsigned char reserved_3[12];
    } dev_capabilities;

    switch(sp.bRequest)
    {
        case INITIATE_CLEAR:
            /* Add reuest specific functionality (4.2.1.6) here */
            return result;
            break;

        case CHECK_CLEAR_STATUS:
            /* Add reuest specific functionality (4.2.1.7) here */
            return result;
            break;

        case GET_CAPABILITIES:
            dev_capabilities.USBTMC_status = 0x01; //SUCCESS
            dev_capabilities.bcdUSBTMC[0] = 0x00;
            dev_capabilities.bcdUSBTMC[1] = 0x02;
            dev_capabilities.USBTMC_Int_Capabilities = 0x00;
            dev_capabilities.USBTMC_Dev_Capabilities = 0x00;

            /* Send the response buffer to the host */
            if ((result = XUD_DoGetRequest(ep_out, ep_in, (dev_capabilities, char[]), sizeof(dev_capabilities), sp.wLength)) != XUD_RES_OKAY)
            {
                return result;
            }

            return result;
            break;

        case INDICATOR_PULSE:
            /* Add reuest specific functionality (4.2.1.9) here */
            return result;
            break;

      default:
            break;
    }

    return XUD_RES_ERR;
}

XUD_Result_t ControlEndpointClassRequests(XUD_ep ep_out, XUD_ep ep_in, USB_SetupPacket_t sp)
{
    USBTMC_status_t result = STATUS_FAILED;

    switch(sp.bRequest)
    {
        case INITIATE_ABORT_BULK_OUT:
            /* Parse request specific setup packet and return EP0 response packet (4.2.1.2) */
            return result;
            break;

        case CHECK_ABORT_BULK_OUT_STATUS:
            /* Add reuest specific functionality (4.2.1.3) here */
            return result;
            break;

        case INITIATE_ABORT_BULK_IN:
            /* Add reuest specific functionality (4.2.1.4) here */
            return result;
            break;

        case CHECK_ABORT_BULK_IN_STATUS:
            /* Add reuest specific functionality (4.2.1.5) here */
            return result;
            break;

      default:
            break;
    }

    return XUD_RES_ERR;
}

/* Endpoint 0 Task */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in)
{
    USB_SetupPacket_t sp;
    XUD_BusSpeed_t usbBusSpeed;
    unsigned bmRequestType;

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

            if ((bmRequestType == USB_BMREQ_H2D_STANDARD_DEV) &&
                (sp.bRequest == USB_CLEAR_FEATURE))
            {
              // Host has set device address, value contained in sp.wValue
            }

            switch(bmRequestType)
            {
                /* Direction: Device-to-host and Host-to-device
                 * Type: Class
                 * Recipient: Interface
                 */
                case USB_BMREQ_H2D_CLASS_INT:
                case USB_BMREQ_D2H_CLASS_INT:

                    /* Check for USBTMC interface number (Sec 4.2.1.8) */
                    if(sp.wIndex == 0)
                    {
                        /* Returns  XUD_RES_OKAY if handled,
                         *          XUD_RES_ERR if not handled,
                         *          XUD_RES_RST for bus reset */
                        result = ControlInterfaceClassRequests(ep0_out, ep0_in, sp);
                    }
                    break;

                    /* Direction: Device-to-host and Host-to-device
                     * Type: Class
                     * Recipient: Endpoint
                     */
                    case USB_BMREQ_H2D_CLASS_EP:
                    case USB_BMREQ_D2H_CLASS_EP:

                        /* Check for USBTMC interface number (Sec 4.2.1.8) */
                        if(sp.wIndex == 0)
                        {
                            /* Returns  XUD_RES_OKAY if handled,
                             *          XUD_RES_ERR if not handled,
                             *          XUD_RES_RST for bus reset */
                            result = ControlEndpointClassRequests(ep0_out, ep0_in, sp);
                        }
                        break;
            }
        } //if(result == XUD_RES_OKAY)

        /* If we haven't handled the request about then do standard enumeration requests */
        if(result == XUD_RES_ERR )
        {
            /* Returns  XUD_RES_OKAY if handled okay,
             * XUD_RES_ERR if request was not handled (i.e. STALLed),
             * XUD_RES_RST if USB Reset */
            result = USB_StandardRequests(ep0_out, ep0_in, devDesc,
                    sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
                    null, 0, null, 0,
                    stringDescriptors, sizeof(stringDescriptors)/sizeof(stringDescriptors[0]),
                    sp, usbBusSpeed);
        }

        /* USB bus reset detected, reset EP and get new bus speed */
        if(result == XUD_RES_RST)
        {
            usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
        }
    }
}







