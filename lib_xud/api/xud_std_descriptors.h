// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _USB_DESCRIPTORS_H_
#define _USB_DESCRIPTORS_H_

#if !defined (__ASSEMBLER__)
/* USB Class Codes (from usb.org) */
typedef enum
{
    USB_CLASS_USE_CLASS                 = 0x00,  /* Use class information in the interface descriptors */
    USB_CLASS_AUDIO                     = 0x01,
    USB_CLASS_COMMUNICATIONS            = 0x02,
    USB_CLASS_HID                       = 0x03,
    USB_CLASS_PHYSICAL                  = 0x05,
    USB_CLASS_IMAGE                     = 0x06,
    USB_CLASS_PRINTER                   = 0x07,
    USB_CLASS_MASS_STORAGE              = 0x08,
    USB_CLASS_HUB                       = 0x09,
    USB_CLASS_CDC_DATA                  = 0x0A,
    USB_CLASS_SMART_CARD                = 0x0B,
    USB_CLASS_RESERVED                  = 0x0C,
    USB_CLASS_CONTENT_SECURITY          = 0x0D,
    USB_CLASS_VIDEO                     = 0x0E,
    USB_CLASS_PERSONAL_HEALTHCARE       = 0x0F,
    USB_CLASS_AUDIO_VIDEO               = 0x10,
//...
    USB_CLASS_MAPPED_INDEX_END          = 17,
    USB_CLASS_VENDOR_SPECIFIC           = 0xFF
} USB_ClassCode_t;

#endif

/* USB Standard Descriptor types (Section 9.4, table 9-5) */
enum USB_DescriptorTypes_t
{
    USB_DESCTYPE_DEVICE                 = 0x01, /* Device descriptor */
    USB_DESCTYPE_CONFIGURATION          = 0x02, /* Configuration descriptor */
    USB_DESCTYPE_STRING                 = 0x03, /* String descriptor */
    USB_DESCTYPE_INTERFACE              = 0x04, /* Interface descriptor */
    USB_DESCTYPE_ENDPOINT               = 0x05, /* Endpoint descriptor */
    USB_DESCTYPE_DEVICE_QUALIFIER       = 0x06, /* Device qualifier descriptor */
    USB_DESCTYPE_OTHER_SPEED            = 0x07,
    USB_DESCTYPE_INTERFACE_POWER        = 0x08, /* Interface power descriptor */
    USB_DESCTYPE_OTG                    = 0x09,
    USB_DESCTYPE_DEBUG                  = 0x0A,
    USB_DESCTYPE_INTERFACE_ASSOCIATION  = 0x0B, /* Interface association descriptor */
};

#ifdef __STDC__

/* No current support for __attribute((packed)) in XC */

/* Generic USB Descriptor Header */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value. See \ref USB_DescriptorTypes_t or
                                         * a value given by the specific class */
} __attribute__((packed)) USB_Descriptor_Header_t;

/* USB Standard Device Descriptor (section 9.6.1, table 9-8) */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value in \ref USB_DescriptorTypes_t
                                         * or a value given by the specific class */
    unsigned short bcdUSB;              /* Supported USB version */
    unsigned char  bDeviceClass;        /* USB device class code */
    unsigned char  bDeviceSubClass;     /* USB device subclass code */
    unsigned char  bDeviceProtocol;     /* USB device protocol code */
    unsigned char  bMaxPacketSize0;     /* Maximum packet size for endpoint 0 (bytes) */
    unsigned short idVendor;            /* Vendor ID */
    unsigned short idProduct;           /* Product ID */
    unsigned short bcdDevice;           /* Device release number in binary-coded decimal */
    unsigned char  iManufacturer;       /* Index of string descriptor describing manufacturer */
    unsigned char  iProduct;            /* Index of string descriptor describing product */
    unsigned char  iSerialNumber;       /* Index of String descriptor describing the devices serial number */
    unsigned char  bNumConfigurations;  /* Total number of configurations supported by the device */
} __attribute__((packed)) USB_Descriptor_Device_t;

/* USB Interface Association Descriptor (See IAD Engineering Change Notice) */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value in \ref USB_DescriptorTypes_t
                                          or a value given by the specific class */
    unsigned char bFirstInterface;      /* Index of the first associated interface */
    unsigned char bInterfaceCount;      /* Total number of associated interfaces */
    unsigned char bFunctionClass;       /* Interface class ID */
    unsigned char bFunctionSubClass;    /* Interface subclass ID */
    unsigned char bFunctionProtocol;    /* Interface protocol ID */
    unsigned char iFunction;            /* Index of the string descriptor describing the
                                         * interface association */
} __attribute__((packed)) USB_Descriptor_Interface_Association_t;

/* USB Standard Interface Descriptor (section 9.6.1 table 9-12) */
typedef struct
{
    unsigned char bLength;             /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;     /* Type of the descriptor, either a value in \ref USB_DescriptorTypes_t
                                        * or a value given by the specific class */
    unsigned char bInterfaceNumber;    /* Index of the interface in the current config */
	unsigned char bAlternateSetting;   /* Alternate setting for this interface number. Multiple alternatives
                                        * are supported per interface (with different EP configs) */
    unsigned char bNumEndpoints;       /* Total endpoint count in this interface */
    unsigned char bInterfaceClass;     /* Interface class code */

    unsigned char bInterfaceSubClass;  /* Interface subclass code */
    unsigned char bInterfaceProtocol;  /* Interface protocol code */
    unsigned char iInterface;          /* Index of the string descriptor in the string table */
} __attribute__((packed)) USB_Descriptor_Interface_t;

/* USB Standard Configuration Descriptor (section 9.6.1 table 9-10) */
typedef struct
{
    unsigned char  bLength;             /* Size of the descriptor (bytes) */
    unsigned char  bDescriptorType;     /* Type of the descriptor, either a value in \ref USB_DescriptorTypes_t or a value
                                         * given by the specific class */
    unsigned short wTotalLength;        /* Size of the configuration descriptor header and all sub descriptors inside
                                         * the configuration */
    unsigned char  bNumInterfaces;      /* Total interface count in the configuration */
    unsigned char  bConfigurationValue; /* Value to use as an argument to the SetConfiguration() request to select this
                                         * configuration */
    unsigned char  iConfiguration;      /* Index of string descriptor describing this configuration */
    unsigned char  bmAttributes;        /* Configuration characteristics
                                         * D7: Reserved (set to one)
                                         * D6: Self-powered
                                         * D5: Remote Wakeup
                                         * D4...0: Reserved (reset to zero)
                                        */
    unsigned char  bMaxPower;           /* Maximum power consumption of the USB device from the bus in this specific
                                         * configuration when the device is fully operational. Expressed in 2 mA units
                                         * (i.e., 50 = 100 mA) */
} __attribute__((packed)) USB_Descriptor_Configuration_Header_t;

/* USB Standard Endpoint Descriptor (section 9.6.1 table 9-13) */
typedef struct
{
    unsigned char bLength;             /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;     /* Descriptor type, either a value. See \ref USB_DescriptorTypes_t or
                                        * a value given by the specific class */
    unsigned char  bEndpointAddress;   /* Address of the endpoint, includes a direction mask */
    unsigned char  bmAttributes;       /* Endpoint attributes, comprised of a mask of the endpoint type
                                        * See EP_TYPE_ ad EP_ADDR) */
    unsigned short wMaxPacketSize;     /* Maximum packet size (bytes) that the endpoint can receive */
    unsigned char  bInterval;          /* Polling interval in milliseconds for the endpoint.
                                        * Relevant to Isochronous and Interrupt endpoints only */
} __attribute__((packed)) USB_Descriptor_Endpoint_t;

/* USB Standard Endpoint Descriptor (Section 9.6.6, table 9-13) */
enum USB_Endpoint_TransType_t
{
    USB_ENDPOINT_TRANSTYPE_CTRL          = 0x0,
    USB_ENDPOINT_TRANSTYPE_ISO           = 0x1,
    USB_ENDPOINT_TRANSTYPE_BULK          = 0x2,
    USB_ENDPOINT_TRANSTYPE_INT           = 0x3
};
#define  USB_ENDPOINT_TRANSTYPE_SHIFT     (0)

enum USB_Endpoint_SyncType_t
{
    USB_ENDPOINT_SYNCTYPE_NONE          = 0x0,
    USB_ENDPOINT_SYNCTYPE_ASYNC         = 0x1,
    USB_ENDPOINT_SYNCTYPE_ADAPT         = 0x2,
    USB_ENDPOINT_SYNCTYPE_SYNC          = 0x3
};
#define  USB_ENDPOINT_SYNCTYPE_SHIFT     (2)

enum USB_Endpoint_UsageType_t
{
    USB_ENDPOINT_USAGETYPE_DATA          = 0x0,
    USB_ENDPOINT_USAGETYPE_FEEDBACK      = 0x1,
    USB_ENDPOINT_USAGETYPE_IMPLICIT      = 0x2,
    USB_ENDPOINT_USAGETYPE_RESERVED      = 0x3
};
#define  USB_ENDPOINT_USAGETYPE_SHIFT     (4)



/* USB String Descriptor (Section 9.6.7 table 9-15) */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value in \ref USB_DescriptorTypes_t
                                         * or a value given by the specific class */
    unsigned short bString[];           /* String data, (as unicode characters) - use array of chars instead of string.
                                         * In GCC prefix string with "L" */
} __attribute__((packed)) USB_Descriptor_String_t;
#endif
#endif
