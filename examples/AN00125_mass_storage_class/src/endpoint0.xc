// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/*
 * @brief Implements endpoint zero for an example Mass Storage class device.
 */

#include <xs1.h>
#include <string.h>
#include <xscope.h>

#include "xud_device.h"
#include "debug_print.h"
#include "print.h"

/* USB Device ID Defines */
#define BCD_DEVICE   0x0010
#define VENDOR_ID    0x20B1
#define PRODUCT_ID   0x10BA

/* USB Mass Storage Interface Subclass Definition */
#define USB_MASS_STORAGE_SUBCLASS   0x06    /* SCSI transparent command set */

/* USB Mass Storage interface protocol */
#define USB_MASS_STORAGE_PROTOCOL   0x50    /* USB Mass Storage Class Bulk-Only (BBB) Transport */

/* USB Mass Storage Request Code */
#define USB_MASS_STORAGE_RESET      0xFF    /* Bulk-Only Mass Storage Reset */
#define USB_MASS_STORAGE_GML        0xFE    /* Get Max LUN (GML) */

/* USB Device Descriptor */
static unsigned char devDesc[] =
{
  0x12,                       /* 0  bLength */
  USB_DESCTYPE_DEVICE,        /* 1  bdescriptorType */
  0x00,                       /* 2  bcdUSB version */
  0x02,                       /* 3  bcdUSB version */
  0x00,                       /* 4  bDeviceClass - Specified by interface */
  0x00,                       /* 5  bDeviceSubClass  - Specified by interface */
  0x00,                       /* 6  bDeviceProtocol  - Specified by interface */
  0x40,                       /* 7  bMaxPacketSize for EP0 - max = 64*/
  (VENDOR_ID & 0xFF),         /* 8  idVendor */
  (VENDOR_ID >> 8),           /* 9  idVendor */
  (PRODUCT_ID & 0xFF),        /* 10 idProduct */
  (PRODUCT_ID >> 8),          /* 11 idProduct */
  (BCD_DEVICE & 0xFF),        /* 12 bcdDevice */
  (BCD_DEVICE >> 8),          /* 13 bcdDevice */
  0x01,                       /* 14 iManufacturer - index of string */
  0x02,                       /* 15 iProduct  - index of string */
  0x03,                       /* 16 iSerialNumber  - index of string */
  0x01                        /* 17 bNumConfigurations */
};

/* USB Configuration Descriptor */
static unsigned char cfgDesc[] = {
  0x09,                       /* 0  bLength */
  USB_DESCTYPE_CONFIGURATION, /* 1  bDescriptortype = configuration */
  0x20, 0x00,                 /* 2  wTotalLength of all descriptors */
  0x01,                       /* 4  bNumInterfaces */
  0x01,                       /* 5  bConfigurationValue */
  0x00,                       /* 6  iConfiguration - index of string */
  0x80,                       /* 7  bmAttributes - Self powered */
  0x50,                       /* 8  bMaxPower - 160mA */

  /* USB Bulk-Only Data Interface Descriptor */
  0x09,                       /* 0  bLength */
  USB_DESCTYPE_INTERFACE,     /* 1  bDescriptorType */
  0x00,                       /* 2  bInterfacecNumber */
  0x00,                       /* 3  bAlternateSetting */
  0x02,                       /* 4: bNumEndpoints */
  USB_CLASS_MASS_STORAGE,     /* 5: bInterfaceClass */
  USB_MASS_STORAGE_SUBCLASS,  /* 6: bInterfaceSubClass */
  USB_MASS_STORAGE_PROTOCOL,  /* 7: bInterfaceProtocol */
  0x00,                       /* 8  iInterface */

  /* Bulk-In Endpoint Descriptor */
  0x07,                       /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,      /* 1  bDescriptorType */
  0x81,                       /* 2  bEndpointAddress - EP1, IN */
  XUD_EPTYPE_BUL,             /* 3  bmAttributes */
  0x00,                       /* 4  wMaxPacketSize - Low */
  0x02,                       /* 5  wMaxPacketSize - High */
  0x00,                       /* 6  bInterval */

  /* Bulk-Out Endpoint Descriptor */
  0x07,                       /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,      /* 1  bDescriptorType */
  0x01,                       /* 2  bEndpointAddress - EP1, OUT */
  XUD_EPTYPE_BUL,             /* 3  bmAttributes */
  0x00,                       /* 4  wMaxPacketSize - Low */
  0x02,                       /* 5  wMaxPacketSize - High */
  0x00,                       /* 6  bInterval */
};

unsafe{
  /* String table - unsafe as accessed via shared memory */
  static char * unsafe stringDescriptors[]=
  {
    "\x09\x04",             // Language ID string (US English)
    "XMOS",                 // iManufacturer
    "xMASSstorage",         // iProduct
    "XD070101ho4I4KwM",     // iSerial Number
  };
}

/* Mass Storage Class Requests */
int MassStorageEndpoint0Requests(XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t sp)
{
   unsigned char buffer[1] = {0};

   switch(sp.bRequest) {

      case USB_MASS_STORAGE_RESET:
          XUD_ResetEpStateByAddr(1);
          return XUD_RES_RST; // This request is used to reset the mass storage device
          break;

      case USB_MASS_STORAGE_GML:
         return XUD_DoGetRequest(ep0_out, ep0_in, buffer,  1, sp.wLength);
         break;

      default:
          debug_printf("MassStorageEndpoint0Requests @ default : 0x%x\n",sp.bRequest);
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
       bmRequestType = (sp.bmRequestType.Direction<<7) | (sp.bmRequestType.Type<<5) |
                       (sp.bmRequestType.Recipient);

       if ((bmRequestType == USB_BMREQ_H2D_STANDARD_DEV) && (sp.bRequest == USB_CLEAR_FEATURE)) {
         // Host has set device address, value contained in sp.wValue
       }

       /* Handle specific requests first */
       switch(bmRequestType) {
          /* Direction: Device-to-host and Host-to-device
           * Type: Class
           * Recipient: Interface
           */
          case USB_BMREQ_H2D_CLASS_INT:
          case USB_BMREQ_D2H_CLASS_INT:

            /* Inspect for mass storage interface num */
            if(sp.wIndex == 0) {
               /* Returns  XUD_RES_OKAY if handled,
                *          XUD_RES_ERR if not handled,
                *          XUD_RES_RST for bus reset */
               result = MassStorageEndpoint0Requests(ep0_out,ep0_in,sp);
            }
            break;
        }
     }

     /* If we haven't handled the request above then do standard enumeration requests */
     if(result == XUD_RES_ERR) {
        /* Returns  XUD_RES_OKAY if handled okay,
         *          XUD_RES_ERR if request was not handled (i.e. STALLed),
         *          XUD_RES_RST if USB Reset */
        result = USB_StandardRequests(ep0_out, ep0_in, devDesc,
                 sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
                 null, 0, null, 0,
                 stringDescriptors, sizeof(stringDescriptors)/sizeof(stringDescriptors[0]),
                 sp, usbBusSpeed);
     }

     /* USB bus reset detected, reset EP and get new bus speed */
     if(result == XUD_RES_RST) {
         usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
     }
  }
}






