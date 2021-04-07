// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef _USB_STD_REQUESTS_H_
#define _USB_STD_REQUESTS_H_

#include <xccompat.h>
#include "XUD_USB_Defines.h"

/* 9.3 USB Device Requests: Table 9-2 Format of Setup Data */
/* bmRequestType: */
#define USB_BM_REQTYPE_DIRECTION_H2D    0           /* Host to device */
#define USB_BM_REQTYPE_DIRECTION_D2H    1           /* Device to host */

#define USB_BM_REQTYPE_TYPE_STANDARD    0x00
#define USB_BM_REQTYPE_TYPE_CLASS       0x01
#define USB_BM_REQTYPE_TYPE_VENDOR      0x02

#define USB_BM_REQTYPE_RECIP_DEV        0x00
#define USB_BM_REQTYPE_RECIP_INTER      0x01
#define USB_BM_REQTYPE_RECIP_EP         0x02
#define USB_BM_REQTYPE_RECIP_OTHER      0x03

#define USB_BMREQ_H2D_STANDARD_DEV      ((USB_BM_REQTYPE_DIRECTION_H2D << 7) | \
                                         (USB_BM_REQTYPE_TYPE_STANDARD << 5) | \
                                         (USB_BM_REQTYPE_RECIP_DEV))
#define USB_BMREQ_D2H_STANDARD_DEV      ((USB_BM_REQTYPE_DIRECTION_D2H << 7) | \
                                         (USB_BM_REQTYPE_TYPE_STANDARD << 5) | \
                                         (USB_BM_REQTYPE_RECIP_DEV))
#define USB_BMREQ_H2D_STANDARD_INT      ((USB_BM_REQTYPE_DIRECTION_H2D << 7) | \
                                         (USB_BM_REQTYPE_TYPE_STANDARD << 5) | \
                                         (USB_BM_REQTYPE_RECIP_INTER))
#define USB_BMREQ_D2H_STANDARD_INT      ((USB_BM_REQTYPE_DIRECTION_D2H << 7) | \
                                         (USB_BM_REQTYPE_TYPE_STANDARD << 5) | \
                                         (USB_BM_REQTYPE_RECIP_INTER))
#define USB_BMREQ_H2D_STANDARD_EP       ((USB_BM_REQTYPE_DIRECTION_H2D << 7) | \
                                         (USB_BM_REQTYPE_TYPE_STANDARD << 5) | \
                                         (USB_BM_REQTYPE_RECIP_EP))
#define USB_BMREQ_D2H_STANDARD_EP       ((USB_BM_REQTYPE_DIRECTION_D2H << 7) | \
                                         (USB_BM_REQTYPE_TYPE_STANDARD << 5) | \
                                         (USB_BM_REQTYPE_RECIP_EP))


#define USB_BMREQ_H2D_CLASS_INT         ((USB_BM_REQTYPE_DIRECTION_H2D << 7) | \
                                         (USB_BM_REQTYPE_TYPE_CLASS << 5)    | \
                                         (USB_BM_REQTYPE_RECIP_INTER))
#define USB_BMREQ_D2H_CLASS_INT         ((USB_BM_REQTYPE_DIRECTION_D2H << 7) | \
                                         (USB_BM_REQTYPE_TYPE_CLASS << 5)    | \
                                         (USB_BM_REQTYPE_RECIP_INTER))
#define USB_BMREQ_H2D_CLASS_EP          ((USB_BM_REQTYPE_DIRECTION_H2D << 7) | \
                                         (USB_BM_REQTYPE_TYPE_CLASS << 5)    | \
                                         (USB_BM_REQTYPE_RECIP_EP))
#define USB_BMREQ_D2H_CLASS_EP          ((USB_BM_REQTYPE_DIRECTION_D2H << 7) | \
                                         (USB_BM_REQTYPE_TYPE_CLASS << 5)    | \
                                         (USB_BM_REQTYPE_RECIP_EP))

#define USB_BMREQ_H2D_VENDOR_DEV          ((USB_BM_REQTYPE_DIRECTION_H2D << 7) | \
                                            (USB_BM_REQTYPE_TYPE_VENDOR << 5) | \
                                            (USB_BM_REQTYPE_RECIP_DEV))
#define USB_BMREQ_D2H_VENDOR_DEV	      ((USB_BM_REQTYPE_DIRECTION_D2H << 7) | \
                                            (USB_BM_REQTYPE_TYPE_VENDOR << 5) | \
                                            (USB_BM_REQTYPE_RECIP_DEV))

/* Table 9-4. Standard Request Codes */
/* bRequest */
#define USB_GET_STATUS                  0x00
#define USB_CLEAR_FEATURE               0x01
#define USB_SET_FEATURE                 0x03
#define USB_SET_ADDRESS                 0x05
#define USB_GET_DESCRIPTOR              0x06
#define USB_SET_DESCRIPTOR              0x07
#define USB_GET_CONFIGURATION           0x08
#define USB_SET_CONFIGURATION           0x09
#define USB_GET_INTERFACE               0x0A
#define USB_SET_INTERFACE               0x0B
#define USB_SYNCH_FRAME                 0x0C

/**
 * \var     typedef USB_BmRequestType_t
 * \brief   Defines the Recepient, Type and Direction of a USB request.
 */
typedef struct USB_BmRequestType
{
    unsigned char Recipient;        // [4..0]   Request directed to:
                                    //          0b00000: Device
                                    //          0b00001: Specific interface
                                    //          0b00010: Specific endpoint
                                    //          0b00011: Other element in device
    unsigned char Type;             // [6..5]   0b00: Standard request
                                    //          0b01: Class specific request
                                    //          0b10: Request by vendor specific driver
    unsigned char Direction;        // [7]      0 (Host->Dev)
                                    //          1 (Dev->Host)
} USB_BmRequestType_t;

/**
 * \var     typedef USB_SetupPacket_t
 * \brief   Typedef for setup packet structure */
typedef struct USB_SetupPacket
{
    USB_BmRequestType_t bmRequestType;    /* (1 byte) Specifies direction of dataflow,
                                             type of rquest and recipient */
    unsigned char bRequest;               /* Specifies the request */
    unsigned short wValue;                /* Host can use this to pass info to the
                                             device in its own way */
    unsigned short wIndex;                /* Typically used to pass index/offset such
                                             as interface or EP no */
    unsigned short wLength;               /* Number of data bytes in the data stage
                                             (for Host -> Device this this is exact
                                             count, for Dev->Host is a max. */
} USB_SetupPacket_t;

/**
 *  \brief Prints out passed ``USB_SetupPacket_t`` struct using debug IO
 */
void USB_PrintSetupPacket(USB_SetupPacket_t sp);

void USB_ComposeSetupBuffer(USB_SetupPacket_t sp, unsigned char buffer[]);

void USB_ParseSetupPacket(unsigned char b[], REFERENCE_PARAM(USB_SetupPacket_t, p));
#endif
