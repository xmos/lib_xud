// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "string.h"
#include "usb_video.h"

/* Definition of Descriptors */
/* USB Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType - Device*/
    0x00,                  /* 2  bcdUSB version */
    0x02,                  /* 3  bcdUSB version */
    0xEF,                  /* 4  bDeviceClass - USB Miscellaneous Class */
    0x02,                  /* 5  bDeviceSubClass  - Common Class */
    0x01,                  /* 6  bDeviceProtocol  - Interface Association Descriptor */
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

  0x09,                       /* 0  bLength */
  USB_DESCTYPE_CONFIGURATION, /* 1  bDescriptorType - Configuration*/
  0xAE,00,                    /* 2  wTotalLength */
  0x02,                       /* 4  bNumInterfaces */
  0x01,                       /* 5  bConfigurationValue */
  0x03,                       /* 6  iConfiguration - index of string */
  0x80,                       /* 7  bmAttributes - Bus powered */
  0xFA,                       /* 8  bMaxPower (in 2mA units) - 500mA */

  /* Interface Association Descriptor */
  0x08,                       /* 0 bLength */
  USB_DESCTYPE_INTERFACE_ASSOCIATION,  /* 1 bDescriptorType - Interface Association */
  0x00,                       /* 2 bFirstInterface - VideoControl i/f */
  0x02,                       /* 3 bInterfaceCount - 2 Interfaces */
  USB_CLASS_VIDEO,            /* 4 bFunctionClass - Video Class */
  USB_VIDEO_INTERFACE_COLLECTION,  /* 5 bFunctionSubClass - Video Interface Collection */
  0x00,                       /* 6 bFunctionProtocol - No protocol */
  0x02,                       /* 7 iFunction - index of string */

  /* Video Control (VC) Interface Descriptor */
  0x09,                       /* 0 bLength */
  USB_DESCTYPE_INTERFACE,     /* 1 bDescriptorType - Interface */
  0x00,                       /* 2 bInterfaceNumber - Interface 0 */
  0x00,                       /* 3 bAlternateSetting */
  0x01,                       /* 4 bNumEndpoints */
  USB_CLASS_VIDEO,            /* 5 bInterfaceClass - Video Class */
  USB_VIDEO_CONTROL,          /* 6 bInterfaceSubClass - VideoControl Interface */
  0x00,                       /* 7 bInterfaceProtocol - No protocol */
  0x02,                       /* 8 iInterface - Index of string (same as iFunction of IAD) */

  /* Class-specific VC Interface Header Descriptor */
  0x0D,                       /* 0 bLength */
  USB_DESCTYPE_CS_INTERFACE,  /* 1 bDescriptorType - Class-specific Interface */
  USB_VC_HEADER,              /* 2 bDescriptorSubType - HEADER */
  0x10, 0x01,                 /* 3 bcdUVC - Video class revision 1.1 */
  0x28, 0x00,                 /* 5 wTotalLength - till output terminal */
  WORD_CHARS(100000000),      /* 7 dwClockFrequency - 100MHz (Deprecated) */
  0x01,                       /* 11 bInCollection - One Streaming Interface */
  0x01,                       /* 12 baInterfaceNr - Number of the Streaming interface */

  /* Input Terminal (Camera) Descriptor - Represents the CCD sensor (Simulated here in this demo) */
  0x12,                       /* 0 bLength */
  USB_DESCTYPE_CS_INTERFACE,  /* 1 bDescriptorType - Class-specific Interface */
  USB_VC_INPUT_TERMINAL,      /* 2 bDescriptorSubType - INPUT TERMINAL */
  0x01,                       /* 3 bTerminalID */
  0x01, 0x02,                 /* 4 wTerminalType - ITT_CAMERA type (CCD Sensor) */
  0x00,                       /* 6 bAssocTerminal - No association */
  0x00,                       /* 7 iTerminal - Unused */
  0x00, 0x00,                 /* 8 wObjectiveFocalLengthMin - No optical zoom supported */
  0x00, 0x00,                 /* 10 wObjectiveFocalLengthMax - No optical zoom supported*/
  0x00, 0x00,                 /* 12 wOcularFocalLength - No optical zoom supported */
  0x03,                       /* 14 bControlSize - 3 bytes */
  0x00, 0x00, 0x00,           /* 15 bmControls - No controls are supported */

  /* Output Terminal Descriptor */
  0x09,                       /* 0 bLength */
  USB_DESCTYPE_CS_INTERFACE,  /* 1 bDescriptorType - Class-specific Interface */
  USB_VC_OUPUT_TERMINAL,      /* 2 bDescriptorSubType - OUTPUT TERMINAL  */
  0x02,                       /* 3 bTerminalID */
  0x01, 0x01,                 /* 4 wTerminalType - TT_STREAMING type */
  0x00,                       /* 6 bAssocTerminal - No association */
  0x01,                       /* 7 bSourceID - Source is Input terminal 1 */
  0x00,                       /* 8 iTerminal - Unused */

  /* Standard Interrupt Endpoint Descriptor */
  0x07,                       /* 0 bLength */
  USB_DESCTYPE_ENDPOINT,      /* 1 bDescriptorType */
  (VIDEO_STATUS_EP_NUM | 0x80), /* 2 bEndpointAddress - IN endpoint*/
  0x03,                       /* 3 bmAttributes - Interrupt transfer */
  0x40, 0x00,                 /* 4 wMaxPacketSize - 64 bytes */
  0x09,                       /* 6 bInterval - 2^(9-1) microframes = 32ms */

  /* Class-specific Interrupt Endpoint Descriptor */
  0x05,                       /* 0 bLength */
  USB_DESCTYPE_CS_ENDPOINT,   /* 1 bDescriptorType - Class-specific Endpoint */
  0x03,                       /* 2 bDescriptorSubType - Interrupt Endpoint */
  0x40, 0x00,                 /* 3 wMaxTransferSize - 64 bytes */

  /* Video Streaming Interface Descriptor */
  /* Zero-bandwidth Alternate Setting 0 */
  0x09,                       /* 0 bLength */
  USB_DESCTYPE_INTERFACE,     /* 1 bDescriptorType - Interface */
  0x01,                       /* 2 bInterfaceNumber - Interface 1 */
  0x00,                       /* 3 bAlternateSetting - 0 */
  0x00,                       /* 4 bNumEndpoints - No bandwidth used */
  USB_CLASS_VIDEO,            /* 5 bInterfaceClass - Video Class */
  USB_VIDEO_STREAMING,        /* 6 bInterfaceSubClass - VideoStreaming Interface */
  0x00,                       /* 7 bInterfaceProtocol - No protocol */
  0x00,                       /* 8 iInterface - Unused */

  /* Class-specific VS Interface Input Header Descriptor */
  0x0E,                       /* 0 bLength */
  USB_DESCTYPE_CS_INTERFACE,  /* 1 bDescriptorType - Class-specific Interface */
  USB_VS_INPUT_HEADER,        /* 2 bDescriptorSubType - INPUT HEADER */
  0x01,                       /* 3 bNumFormats - One format supported */
  0x47, 0x00,                 /* 4 wTotalLength - Size of class-specific VS descriptors */
  (VIDEO_DATA_EP_NUM | 0x80), /* 6 bEndpointAddress - Iso EP for video streaming */
  0x00,                       /* 7 bmInfo - No dynamic format change */
  0x02,                       /* 8 bTerminalLink - Denotes the Output Terminal */
  0x01,                       /* 9 bStillCaptureMethod - Method 1 supported */
  0x00,                       /* 10 bTriggerSupport - No Hardware Trigger */
  0x00,                       /* 11 bTriggerUsage */
  0x01,                       /* 12 bControlSize - 1 byte */
  0x00,                       /* 13 bmaControls - No Controls supported */

  /* Class-specific VS Format Descriptor */
  0x1B,                       /* 0 bLength */
  USB_DESCTYPE_CS_INTERFACE,  /* 1 bDescriptorType - Class-specific Interface */
  USB_VS_FORMAT_UNCOMPRESSED, /* 2 bDescriptorSubType - FORMAT UNCOMPRESSED */
  0x01,                       /* 3 bFormatIndex */
  0x01,                       /* 4 bNumFrameDescriptors - 1 Frame descriptor followed */
  0x59,0x55,0x59,0x32,
  0x00,0x00,0x10,0x00,
  0x80,0x00,0x00,0xAA,
  0x00,0x38,0x9B,0x71,        /* 5 guidFormat - YUY2 Video format */
  BITS_PER_PIXEL,             /* 21 bBitsPerPixel - 16 bits */
  0x01,                       /* 22 bDefaultFrameIndex */
  0x00,                       /* 23 bAspectRatioX */
  0x00,                       /* 24 bAspectRatioY */
  0x00,                       /* 25 bmInterlaceFlags - No interlaced mode */
  0x00,                       /* 26 bCopyProtect - No restrictions on duplication */

  /* Class-specific VS Frame Descriptor */
  0x1E,                       /* 0 bLength */
  USB_DESCTYPE_CS_INTERFACE,  /* 1 bDescriptorType - Class-specific Interface */
  USB_VS_FRAME_UNCOMPRESSED,  /* 2 bDescriptorSubType */
  0x01,                       /* 3 bFrameIndex */
  0x01,                       /* 4 bmCapabilities - Still image capture method 1 */
  SHORT_CHARS(WIDTH),         /* 5 wWidth - 480 pixels */
  SHORT_CHARS(HEIGHT),        /* 7 wHeight - 320 pixels */
  WORD_CHARS(MIN_BIT_RATE),   /* 9 dwMinBitRate */
  WORD_CHARS(MAX_BIT_RATE),   /* 13 dwMaxBitRate */
  WORD_CHARS(MAX_FRAME_SIZE), /* 17 dwMaxVideoFrameBufSize */
  WORD_CHARS(FRAME_INTERVAL), /* 21 dwDefaultFrameInterval (in 100ns units) */
  0x01,                       /* 25 bFrameIntervalType */
  WORD_CHARS(FRAME_INTERVAL), /* 26 dwFrameInterval (in 100ns units) */

  /* Video Streaming Interface Descriptor */
  /* Alternate Setting 1 */
  0x09,                       /* 0 bLength */
  USB_DESCTYPE_INTERFACE,     /* 1 bDescriptorType - Interface */
  0x01,                       /* 2 bInterfaceNumber - Interface 1 */
  0x01,                       /* 3 bAlternateSetting -  1 */
  0x01,                       /* 4 bNumEndpoints */
  USB_CLASS_VIDEO,            /* 5 bInterfaceClass - Video Class */
  USB_VIDEO_STREAMING,        /* 6 bInterfaceSubClass - VideoStreaming Interface */
  0x00,                       /* 7 bInterfaceProtocol - No protocol */
  0x00,                       /* 8 iInterface - Unused */

  /* Standard VS Isochronous Video Data Endpoint Descriptor */
  0x07,                       /* 0 bLength */
  USB_DESCTYPE_ENDPOINT,      /* 1 bDescriptorType */
  (VIDEO_DATA_EP_NUM | 0x80), /* 2 bEndpointAddress - IN Endpoint */
  0x05,                       /* 3 bmAttributes - Isochronous EP (Asynchronous) */
  0x00, 0x04,                 /* 4 wMaxPacketSize 1x 1024 bytes*/
  0x01,                       /* 6 bInterval */

};

unsafe{
  /* String table - unsafe as accessed via shared memory */
  static char * unsafe stringDescriptors[]=
  {
    "\x09\x04",             /* Language ID string (US English) */
    "XMOS",                 /* iManufacturer */
    "XMOS USB Video Device",/* iProduct */
    "Config",               /* iConfiguration string */
  };
}

/* Endpoint 0 handles both std USB requests and Video class-specific requests */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in)
{
    USB_SetupPacket_t sp;

    unsigned bmRequestType;
    XUD_BusSpeed_t usbBusSpeed;

    XUD_ep ep0_out = XUD_InitEp(chan_ep0_out);
    XUD_ep ep0_in = XUD_InitEp(chan_ep0_in);

    UVC_InitProbeCommitData();

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
               (sp.bRequest == USB_SET_ADDRESS))
           {
             // Host has set device address, value contained in sp.wValue
           }

           switch(bmRequestType)
           {
               /* Direction: Device-to-host and Host-to-device
                * Type: Class
                * Recipient: Interface / Endpoint
                */
               case USB_BMREQ_H2D_CLASS_INT:
               case USB_BMREQ_D2H_CLASS_INT:
               case USB_BMREQ_H2D_CLASS_EP:
               case USB_BMREQ_D2H_CLASS_EP:

                   /* Inspect for VideoControl Class interface number or
                    * VideoStreaming Class interface number or EP number;
                    * If an Entity is addressed, the High byte has to be checked
                    * for Entity ID */
                   if(sp.wIndex == 0 || sp.wIndex == 1 || sp.wIndex == (VIDEO_DATA_EP_NUM | 0x80))
                   {
                       /* Returns  XUD_RES_OKAY if handled,
                        *          XUD_RES_ERR if not handled,
                        *          XUD_RES_RST for bus reset */
                       result = UVC_InterfaceClassRequests(ep0_out, ep0_in, sp);
                   }
                   break;
           }
       } /* if ends */

       /* If we haven't handled the request about then do standard enumeration requests */
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

/* Buffer to hold Video data in YUYV format */
unsigned int gVideoBuffer[3][PAYLOAD_SIZE / 4];

/* Function to handle all endpoints of the Video class excluding control endpoint0 */
void VideoEndpointsHandler(chanend c_epint_in, chanend c_episo_in)
{
    XUD_Result_t result;
    int frame = 0x0C;
    int pts, tmrValue = 0;
    timer presentationTimer;

    int sofCounts = 0, frameCounts = 0;
    unsigned int index = 0;
    unsigned int i_index = 0;
    int split = (MAX_FRAME_SIZE / 6);
    int i_split = (MAX_FRAME_SIZE / 6);

    /* Initialize all endpoints */
    XUD_ep epint_in = XUD_InitEp(c_epint_in);
    XUD_ep episo_in = XUD_InitEp(c_episo_in);

    /* Just to keep compiler happy */
    epint_in = epint_in;
    /* XUD will NAK if the endpoint is not ready to communicate with XUD */

    /* Fill video buffers with different color data */
    for(int i = 0; i < (PAYLOAD_SIZE/4); i++) {
        /* Set RED color */
        gVideoBuffer[0][i] = 0x7010D010;
        /* Set GREEN color */
        gVideoBuffer[2][i] = 0x00000000;
        /* Set BLUE color */
        gVideoBuffer[1][i] = 0xDC206020;
    }

    while(1)
    {
        int expectedPixels =  MAX_FRAME_SIZE;
        presentationTimer :> pts;

        /* Fill the buffers with payload header */
        for(int i=0; i<3; i++)
        {
            /* Make the Payload header */
            (gVideoBuffer[i], unsigned char[])[0] = PAYLOAD_HEADER_LENGTH;
            (gVideoBuffer[i], unsigned char[])[1] = frame;
            /* Set dwPresentationTime */
            (gVideoBuffer[i], unsigned short[])[1] = pts;
            (gVideoBuffer[i], unsigned short[])[2] = pts>>16;
            /* Set scrSourceClock */
            (gVideoBuffer[i], unsigned short[])[3] = pts;
            (gVideoBuffer[i], unsigned short[])[4] = pts>>16;
            (gVideoBuffer[i], unsigned short[])[5] = (sofCounts>>3) & 2047;
        }

        /* Just to simulate the motion in the video frames */
        i_split = (i_split - ((WIDTH)*8));
        if(i_split <= 0) {
            i_split = MAX_FRAME_SIZE / 6;
            i_index = (i_index + 1) % 3;
        }
        presentationTimer :> tmrValue;

        /* Let the frames scroll */
        index = i_index;
        split = i_split;

        /* Transmits single frame */
        while(expectedPixels > 0)
        {
            if(expectedPixels < (PAYLOAD_SIZE - PAYLOAD_HEADER_LENGTH)) {
                /* Payload transfer */
                result = XUD_SetBuffer(episo_in, (gVideoBuffer[index], unsigned char[]), expectedPixels+PAYLOAD_HEADER_LENGTH);
            } else {
                /* Payload transfer */
                result = XUD_SetBuffer(episo_in, (gVideoBuffer[index], unsigned char[]), 1024);
            }
            /* Note down the SOF counts */
            sofCounts++;

            expectedPixels -= ((PAYLOAD_SIZE)- PAYLOAD_HEADER_LENGTH);

            if(expectedPixels <= (MAX_FRAME_SIZE - split)) {
                index = (index + 1) % 3;
                split += (MAX_FRAME_SIZE / 6);
            }
        }
        frame = frame ^ 1;  /* Toggle FID bit */
        frameCounts++;
    }
}
