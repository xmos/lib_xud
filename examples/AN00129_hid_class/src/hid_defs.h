// Copyright 2021-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/*
 * @brief Defines shared data for HID example threads.
 */
#ifndef HID_DEFS_H
#define HID_DEFS_H

/* Global report buffer */
#define HID_REPORT_BUFFER_SIZE 3
extern unsigned char g_reportBuffer[HID_REPORT_BUFFER_SIZE];

/* USB HID Device Product Defines */
#define BCD_DEVICE   0x1000
#define VENDOR_ID    0x20B1
#define PRODUCT_ID   0x1010

/* Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType */
    0x00,                  /* 2  bcdUSB */
    0x02,                  /* 3  bcdUSB */
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
    0x00,                  /* 16 iSerialNumber */
    0x01                   /* 17 bNumConfigurations */
};


/* Configuration Descriptor */
static unsigned char cfgDesc[] = {
    0x09,                 /* 0  bLength */
    0x02,                 /* 1  bDescriptortype */
    0x22, 0x00,           /* 2  wTotalLength */
    0x01,                 /* 4  bNumInterfaces */
    0x01,                 /* 5  bConfigurationValue */
    0x03,                 /* 6  iConfiguration */
    0x80,                 /* 7  bmAttributes */
    0xC8,                 /* 8  bMaxPower */

    0x09,                 /* 0  bLength */
    0x04,                 /* 1  bDescriptorType */
    0x00,                 /* 2  bInterfacecNumber */
    0x00,                 /* 3  bAlternateSetting */
    0x01,                 /* 4: bNumEndpoints */
    0x03,                 /* 5: bInterfaceClass */
    0x00,                 /* 6: bInterfaceSubClass */
    0x02,                 /* 7: bInterfaceProtocol*/
    0x00,                 /* 8  iInterface */

    0x09,                 /* 0  bLength. Note this is currently
                                replicated in hidDescriptor[] below */
    0x21,                 /* 1  bDescriptorType (HID) */
    0x11,                 /* 2  bcdHID */
    0x01,                 /* 3  bcdHID */
    0x00,                 /* 4  bCountryCode */
    0x01,                 /* 5  bNumDescriptors */
    0x22,                 /* 6  bDescriptorType[0] (Report) */
    0x32,                 /* 7  wDescriptorLength */
    0x00,                 /* 8  wDescriptorLength */

    0x07,                 /* 0  bLength */
    0x05,                 /* 1  bDescriptorType */
    0x81,                 /* 2  bEndpointAddress */
    0x03,                 /* 3  bmAttributes */
    0x40,                 /* 4  wMaxPacketSize */
    0x00,                 /* 5  wMaxPacketSize */
    0x0a                  /* 6  bInterval */
};

static unsigned char hidDescriptor[] =
{
    0x09,               /* 0  bLength */
    0x21,               /* 1  bDescriptorType (HID) */
    0x11,               /* 2  bcdHID */
    0x01,               /* 3  bcdHID */
    0x00,               /* 4  bCountryCode */
    0x01,               /* 5  bNumDescriptors */
    0x22,               /* 6  bDescriptorType[0] (Report) */
    0x32,               /* 7  wDescriptorLength */
    0x00,               /* 8  wDescriptorLength */
};

/* HID Report Descriptor */
static unsigned char hidReportDescriptor[] =
{
    0x05, 0x01,   /* Usage Page (Generic Desktop) */
    0x09, 0x02,   /* Usage (Mouse) */
    0xA1, 0x01,   /* Collection (Application) */
    0x09, 0x01,   /* Usage (Pointer) */
    0xA1, 0x00,   /* Collection (Physical) */
    0x05, 0x09,   /* Usage Page (Buttons) */
    0x19, 0x01,   /* Usage Minimum (01) */
    0x29, 0x03,   /* Usage Maximum (03) */
    0x15, 0x00,   /* Logical Minimum (0) */
    0x25, 0x01,   /* Logical Maximum (1) */
    0x95, 0x03,   /* Report Count (3) */
    0x75, 0x01,   /* Report Size (1) */
    0x81, 0x02,   /* Input (Data,Variable,Absolute); 3 button bits */
    0x95, 0x01,   /* Report Count (1) */
    0x75, 0x05,   /* Report Size (5) */
    0x81, 0x01,   /* Input(Constant); 5 bit padding */
    0x05, 0x01,   /* Usage Page (Generic Desktop) */
    0x09, 0x30,   /* Usage (X) */
    0x09, 0x31,   /* Usage (Y) */
    0x15, 0x81,   /* Logical Minimum (-127) */
    0x25, 0x7F,   /* Logical Maximum (127) */
    0x75, 0x08,   /* Report Size (8) */
    0x95, 0x02,   /* Report Count (2) */
    0x81, 0x06,   /* Input (Data,Variable,Relative); 2 position bytes (X & Y) */
    0xC0,         /* End Collection */
    0xC0          /* End Collection */
};

/* String table */
#ifdef __XC__
unsafe {
static char * unsafe stringDescriptors[]=
#else
static char * stringDescriptors[]=
#endif // __XC__
{
    "\x09\x04",             // Language ID string (US English)
    "XMOS",                 // iManufacturer
    "Example HID Mouse",    // iProduct
    "Config",               // iConfiguration
};
#ifdef __XC__
}
#endif // __XC__

#endif // HID_DEFS_H
