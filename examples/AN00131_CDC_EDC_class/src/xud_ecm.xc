// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <stdio.h>
#include <string.h>
#include "packet_buffer.h"
#include "queue.h"
#include "xud_device.h"
#include "xud_ecm.h"
#include "ethernet.h"


/* USB CDC device product defines */
#define BCD_DEVICE  0x0100
#define VENDOR_ID   0x20B1
#define PRODUCT_ID  0x0402

/* USB Sub class and protocol codes */
#define USB_CDC_ECM_SUBCLASS        0x06

/* CDC interface descriptor type */
#define USB_DESCTYPE_CS_INTERFACE   0x24
#define USB_DESCTYPE_CS_ENDPOINT    0x25

/* Endpoint Addresses for CDC device */
#define CDC_NOTIFICATION_EP_NUM     1  /* (0x81) */
#define CDC_DATA_RX_EP_NUM          1  /* (0x01) */
#define CDC_DATA_TX_EP_NUM          2  /* (0x82) */

/* Data endpoint packet size */
#define MAX_EP_SIZE     512

/* CDC ECM Class requests Section 6.2 in CDC ECM spec */
#define SET_ETHERNET_MULTICAST_FILTERS                  0x40
#define SET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER    0x41
#define GET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER    0x42
#define SET_ETHERNET_PACKET_FILTER                      0x43
#define GET_ETHERNET_STATISTIC                          0x44
/* 45h-4Fh RESERVED (future use) */

/* CDC ECM Class notification codes - Section 6.3 in CDC ECM spec */
#define NETWORK_CONNECTION      0x00
#define RESPONSE_AVAILABLE      0x01
#define CONNECTION_SPEED_CHANGE 0x2A


/* Definition of Descriptors */
/* USB Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType - Device*/
    0x00,                  /* 2  bcdUSB version */
    0x02,                  /* 3  bcdUSB version */
    USB_CLASS_COMMUNICATIONS,/* 4  bDeviceClass - USB CDC Class */
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

  0x09,                       /* 0  bLength */
  USB_DESCTYPE_CONFIGURATION, /* 1  bDescriptortype - Configuration*/
  0x47,00,                    /* 2  wTotalLength */
  0x02,                       /* 4  bNumInterfaces */
  0x01,                       /* 5  bConfigurationValue */
  0x04,                       /* 6  iConfiguration - index of string */
  0x80,                       /* 7  bmAttributes - Bus powered */
  0xC8,                       /* 8  bMaxPower - 400mA */

  /* CDC Communication interface */
  0x09,                       /* 0  bLength */
  USB_DESCTYPE_INTERFACE,     /* 1  bDescriptorType - Interface */
  0x00,                       /* 2  bInterfaceNumber - Interface 0 */
  0x00,                       /* 3  bAlternateSetting */
  0x01,                       /* 4  bNumEndpoints */
  USB_CLASS_COMMUNICATIONS,   /* 5  bInterfaceClass */
  USB_CDC_ECM_SUBCLASS,       /* 6  bInterfaceSubClass - Ethernet Control Model */
  0x00,                       /* 7  bInterfaceProtocol - No specific protocol */
  0x00,                       /* 8  iInterface - No string descriptor */

  /* Header Functional descriptor */
  0x05,                      /* 0  bLength */
  USB_DESCTYPE_CS_INTERFACE, /* 1  bDescriptortype, CS_INTERFACE */
  0x00,                      /* 2  bDescriptorsubtype, HEADER */
  0x10, 0x01,                /* 3  bcdCDC */

  /* Union Functional descriptor */
  0x05,                     /* 0  bLength */
  USB_DESCTYPE_CS_INTERFACE,/* 1  bDescriptortype, CS_INTERFACE */
  0x06,                     /* 2  bDescriptorsubtype, UNION */
  0x00,                     /* 3  bControlInterface - Interface 0 */
  0x01,                     /* 4  bSubordinateInterface0 - Interface 1 */

  /* Ethernet Networking Functional descriptor */
  0x0D,                     /* 0 bLength - 13 bytes */
  USB_DESCTYPE_CS_INTERFACE,/* 1 bDescriptortype, CS_INTERFACE */
  0x0F,                     /* 2 bDescriptorsubtype, ETHERNET NETWORKING */
  0x03,                     /* 3 iMACAddress, Index of MAC address string */
  0x00,0x00,0x00,0x00,      /* 4 bmEthernetStatistics - Handles None */
  0xEA,05,                  /* 8 wMaxSegmentSize - 1514 bytes */
  0x00,0x00,                /* 10 wNumberMCFilters - No multicast filters */
  0x00,                     /* 12 bNumberPowerFilters - No wake-up feature */

  /* Notification Endpoint descriptor */
  0x07,                         /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,        /* 1  bDescriptorType */
  (CDC_NOTIFICATION_EP_NUM | 0x80),/* 2  bEndpointAddress - IN endpoint*/
  0x03,                         /* 3  bmAttributes - Interrupt type */
  0x40,                         /* 4  wMaxPacketSize - Low */
  0x00,                         /* 5  wMaxPacketSize - High */
  0xFF,                         /* 6  bInterval */

  /* CDC Data interface */
  0x09,                     /* 0  bLength */
  USB_DESCTYPE_INTERFACE,   /* 1  bDescriptorType */
  0x01,                     /* 2  bInterfacecNumber */
  0x00,                     /* 3  bAlternateSetting */
  0x02,                     /* 4  bNumEndpoints */
  USB_CLASS_CDC_DATA,       /* 5  bInterfaceClass */
  0x00,                     /* 6  bInterfaceSubClass */
  0x00,                     /* 7  bInterfaceProtocol*/
  0x00,                     /* 8  iInterface - No string descriptor*/

  /* Data OUT Endpoint descriptor */
  0x07,                     /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,    /* 1  bDescriptorType */
  CDC_DATA_RX_EP_NUM,       /* 2  bEndpointAddress - OUT endpoint */
  0x02,                     /* 3  bmAttributes - Bulk type */
  0x00,                     /* 4  wMaxPacketSize - Low */
  0x02,                     /* 5  wMaxPacketSize - High */
  0x00,                     /* 6  bInterval */

  /* Data IN Endpoint descriptor */
  0x07,                     /* 0  bLength */
  USB_DESCTYPE_ENDPOINT,    /* 1  bDescriptorType */
  (CDC_DATA_TX_EP_NUM | 0x80),/* 2  bEndpointAddress - IN endpoint */
  0x02,                     /* 3  bmAttributes - Bulk type */
  0x00,                     /* 4  wMaxPacketSize - Low byte */
  0x02,                     /* 5  wMaxPacketSize - High byte */
  0x01                      /* 6  bInterval */
};

unsafe{
  /* String table - unsafe as accessed via shared memory */
  static char * unsafe stringDescriptors[]=
  {
    "\x09\x04",             /* Language ID string (US English) */
    "XMOS",                 /* iManufacturer */
    "XMOS USB CDC Ethernet Device",/* iProduct */
    "002297000000",         /* iMACAddress */
    "Config",               /* iConfiguration string */
  };
}

#define MAC_ID_INDEX 3

/* Queues for handling Ethernet frame buffers */
Queue_t toHostQ;
Queue_t toDevQ;

/* CDC Class-specific requests handler function */
XUD_Result_t ControlInterfaceClassRequests(XUD_ep ep_out, XUD_ep ep_in, USB_SetupPacket_t sp)
{
    XUD_Result_t result = XUD_RES_ERR;

#if defined (DEBUG) && (DEBUG == 1)
    printhexln(sp.bRequest);
#endif

    switch(sp.bRequest)
    {
        case SET_ETHERNET_MULTICAST_FILTERS:
            /* Not supported now */

            /*if((result = XUD_GetBuffer(ep_out, (buffer, unsigned char[]), 0)) != XUD_RES_OKAY)
            {
                return result;
            }

            result = XUD_DoSetRequestStatus(ep_in);*/

            return result;
            break;

        case SET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER:
            /* Not supported now */

            /*if((result = XUD_GetBuffer(ep_out, (buffer, unsigned char[]), length)) != XUD_RES_OKAY)
            {
                return result;
            }

            result = XUD_DoSetRequestStatus(ep_in);*/
            return result;
            break;

        case GET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER:
            /* Not supported now */

            /* return XUD_DoGetRequest(ep_out, ep_in, (buffer, unsigned char[]), 0, sp.wLength);
            */
            return result;
            break;

        case SET_ETHERNET_PACKET_FILTER:
            /* TODO: Handle this required command */

            return XUD_DoSetRequestStatus(ep_in);

            break;

        case GET_ETHERNET_STATISTIC:
            /* Not supported now */

            /* return XUD_DoGetRequest(ep_out, ep_in, (buffer, unsigned char[]), 0, sp.wLength); */

            break;

        default:
            // Error case
            printhexln(sp.bRequest);
            break;
    }
    return XUD_RES_ERR;
}

/* Endpoint 0 handling both std USB requests and CDC class specific requests */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in)
{
    USB_SetupPacket_t sp;

    unsigned bmRequestType;
    XUD_BusSpeed_t usbBusSpeed;

    XUD_ep ep0_out = XUD_InitEp(chan_ep0_out);
    XUD_ep ep0_in = XUD_InitEp(chan_ep0_in);

    /* Get MAC ID from a global variable */
    getMacAddressString(stringDescriptors[MAC_ID_INDEX]);

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
                 * Recipient: Interface
                 */
                case USB_BMREQ_H2D_CLASS_INT:
                case USB_BMREQ_D2H_CLASS_INT:

                    /* Inspect for CDC Communications Class interface num */
                    if(sp.wIndex == 0)
                    {
                        /* Returns  XUD_RES_OKAY if handled,
                         *          XUD_RES_ERR if not handled,
                         *          XUD_RES_RST for bus reset */
                        result = ControlInterfaceClassRequests(ep0_out, ep0_in, sp);
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

/* Function to handle all endpoints of the CDC class excluding control endpoint0 */
void CdcEcmEndpointsHandler(chanend c_epint_in, chanend c_epbulk_out, chanend c_epbulk_in, SERVER_INTERFACE(usb_cdc_ecm_if, cdc_ecm))
{
    int inBufId = 0, outBufId = 0;          // used to identify buffer read/write by device
    int inIndex = 0, outLen = 0;
    int hostWaiting = 1, devWaiting = 0;  // Used for flow control with IN and OUT endpoints respectively
    unsigned length;
    XUD_Result_t result;

    /* Initialize all endpoints */
    XUD_ep epint_in = XUD_InitEp(c_epint_in);
    XUD_ep epbulk_out = XUD_InitEp(c_epbulk_out);
    XUD_ep epbulk_in = XUD_InitEp(c_epbulk_in);

    /* XUD will NAK if the endpoint is not ready to communicate with XUD */

    /* TODO: Interrupt endpoint to report network state (if required) */

    /* Just to keep compiler happy */
    epint_in = epint_in;

    /* Initialize the Queues and Buffers */
    qInit(toHostQ);
    qInit(toDevQ);
    packetBufferInit();

    /* Get a free buffer to set OUT endpoint ready for receiving data */
    outBufId = packetBufferAlloc();
    outLen = 0;
    XUD_SetReady_Out(epbulk_out, (packetBuffer[outBufId], unsigned char[])); // Re-interpret int buffer to char buffer

    while(1)
    {
      select
      {
        case XUD_GetData_Select(c_epbulk_out, epbulk_out, length, result):

           if(result == XUD_RES_OKAY)
           {
               /* Received some data */
               if(length < MAX_EP_SIZE) {
                   /* USB Short packet or Zero length packet is received */
                   outLen += length;
                   /* Ethernet packet is received completely */
                   qPut(toDevQ, outBufId, outLen);

                   if(qIsFull(toDevQ)) {
                       devWaiting = 1;
                   } else {
                       outBufId = packetBufferAlloc();
                       outLen = 0;
                       XUD_SetReady_Out(epbulk_out, (packetBuffer[outBufId], unsigned char[]));
                   }

               } else {
                   /* USB Full packet */
                   outLen += MAX_EP_SIZE;
                   XUD_SetReady_Out(epbulk_out, (packetBuffer[outBufId], unsigned char[])+outLen);
               }

           } else {
               XUD_SetReady_Out(epbulk_out, (packetBuffer[outBufId], unsigned char[])+outLen);
           }
           break;

        case XUD_SetData_Select(c_epbulk_in, epbulk_in, result):

            /* USB Packet sent successfully when result is XUD_RES_OKAY */
            int index = qPeek(toHostQ);
            int bytesSent = toHostQ.data[index].from - inIndex;
            inIndex = toHostQ.data[index].from;
            int bytesToSend = toHostQ.data[index].len - toHostQ.data[index].from;

            if(bytesToSend) {
                if (bytesToSend > MAX_EP_SIZE) {
                    /* Still Large packet, split the transfer */
                    bytesToSend = MAX_EP_SIZE;
                }
                XUD_SetReady_In(epbulk_in, (packetBuffer[inBufId], unsigned char[])+inIndex, bytesToSend);
                toHostQ.data[index].from += bytesToSend;

            } else if (bytesSent == MAX_EP_SIZE){
                /* Send a Zero Length Packet to indicate completion of transfer */
                XUD_SetReady_In(epbulk_in, (packetBuffer[inBufId], unsigned char[]), 0);
                inIndex += bytesSent;
            } else {
                /* Ethernet frame transfer is over */
                packetBufferFree(toHostQ.data[index].packet);
                /* Remove packet out of queue */
                qGet(toHostQ);

                /* Check if other packet is waiting to be sent to host */
                if(!qIsEmpty(toHostQ)) {
                    index = qPeek(toHostQ);
                    inBufId = toHostQ.data[index].packet;
                    inIndex = toHostQ.data[index].from;
                    bytesToSend = toHostQ.data[index].len;

                    if(bytesToSend > MAX_EP_SIZE) {
                        bytesToSend = MAX_EP_SIZE;
                    }
                    XUD_SetReady_In(epbulk_in, (packetBuffer[inBufId], unsigned char[])+inIndex, bytesToSend);
                    toHostQ.data[index].from += bytesToSend;
                } else {
                    /* No packets are available to send */
                    hostWaiting = 1;
                }
            }
            break;

        /* Case handlers for CDC ECM interface functions */
        case (!qIsEmpty(toDevQ)) => cdc_ecm.read_frame(unsigned char frame_buf[], REFERENCE_PARAM(unsigned, frame_len)):

            /* A packet waiting in queue to be handled */
            int index = qPeek(toDevQ);
            int packetNum = toDevQ.data[index].packet;
            int offset = toDevQ.data[index].from;
            frame_len = toDevQ.data[index].len;

            /* Copy the whole Ethernet frame */
            memcpy(frame_buf, (packetBuffer[packetNum], unsigned char[])+offset, frame_len);
            packetBufferFree(packetNum);
            qGet(toDevQ);

            /* Make a buffer ready for OUT endpoint */
            if(devWaiting) {
                outBufId = packetBufferAlloc();
                XUD_SetReady_Out(epbulk_out, (packetBuffer[outBufId], unsigned char[]));
                devWaiting = 0;
            }
            break;

        case (!qIsFull(toHostQ)) => cdc_ecm.send_frame(unsigned char frame_buf[], REFERENCE_PARAM(unsigned, frame_len)):

            /* Get a free buffer to write the frame */
            int buf_id = packetBufferAlloc();
            memcpy((packetBuffer[buf_id],unsigned char[]), frame_buf, frame_len);
            qPut(toHostQ, buf_id, frame_len);

            /* Send the packet if host is waiting */
            if(hostWaiting) {
                int index = qPeek(toHostQ);
                inBufId = toHostQ.data[index].packet;
                inIndex = toHostQ.data[index].from;
                int bytesToSend = toHostQ.data[index].len;

                hostWaiting = 0;

                if(bytesToSend > MAX_EP_SIZE ){
                    /* Large packet, split the transfers */
                    bytesToSend = MAX_EP_SIZE;
                }
                XUD_SetReady_In(epbulk_in, (packetBuffer[inBufId], unsigned char[])+inIndex, bytesToSend);
                toHostQ.data[index].from += bytesToSend;
            }
            break;

        case cdc_ecm.is_frame_available() -> int val:
            val = !qIsEmpty(toDevQ);
            break;
      }
    }
}
