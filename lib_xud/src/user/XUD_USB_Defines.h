// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/**
 * @brief     Defines from the Universal Serial Bus Specification Revision 2.0
 **/

#ifndef _USB_DEFS_H_
#define _USB_DEFS_H_

/* Table 8-1. PID Types */
#define USB_PID_OUT                     0x1         /* Tokens */
#define USB_PID_IN                      0x9
#define USB_PID_SOF                     0x5
#define USB_PID_SETUP                   0xD
#define USB_PID_DATA0                   0x3         /* Data packet PID even */
#define USB_PID_DATA1                   0xB         /* Data packet PID odd */
#define USB_PID_DATA2                   0x7         /* Data packet PID high-speed, high bandwidth isoc transaction in a microframe */
#define USB_PID_MDATA                   0xF         /* Data packet PID high-speed and high bandwidth isoc transactions */
#define USB_PID_ACK                     0x2         /* Receiver accepts error-free data packet */
#define USB_PID_NAK                     0xA         /* Receiving device cannot accept data of transmitting device cannot send data */
#define USB_PID_STALL                   0xE         /* Endpoint is halted or a control pipe request is not supported */
#define USB_PID_PRE                     0xC
#define USB_PID_ERR                     0xC
#define USB_PID_SPLIT                   0x8
#define USB_PID_PING                    0x4         /* Hign-speed flow control probe for bulk/control endpoint */

/* PID with error check */
#define USB_PID_NEGATE(PID) ((PID) | (((~PID) & 0xf) << 4))
#define USB_PIDn_OUT                    0xe1
#define USB_PIDn_IN                     0x69
#define USB_PIDn_SOF                    0xa5
#define USB_PIDn_SETUP                  0x2d
#define USB_PIDn_DATA0                  0xc3
#define USB_PIDn_DATA1                  USB_PID_NEGATE(USB_PID_DATA1)
#define USB_PIDn_DATA2                  USB_PID_NEGATE(USB_PID_DATA2)
#define USB_PIDn_ACK                    0xd2
#define USB_PIDn_NAK                    0x5a
#define USB_PIDn_STALL                  0x1e

/* Table 9-6. Standard Feature Selectors (wValue) */
#define USB_DEVICE_REMOTE_WAKEUP        0x01        /* Recipient: Device */
#define USB_ENDPOINT_HALT               0x00        /* Recipient: Endpoint */
#define USB_TEST_MODE                   0x02        /* Recipient: Device */

#define USB_STANDARD_DEVICE_REQUEST     0x00
#define USB_STANDARD_INTERFACE_REQUEST  0x01
#define USB_STANDARD_ENDPOINT_REQUEST   0x02
#define USB_VENDOR_DEVICE_REQUEST       0x40
#define USB_VENDOR_ENDPOINT_REQUEST     0x42
#define USB_CLASS_INTERFACE_REQUEST     0x21
#define USB_CLASS_ENDPOINT_REQUEST      0x22

#define USB_WVAL_EP_HALT                0

// Low byte values:
//#define USB_WVALUE_GETDESC_STRING_LANGIDS   0x0
//#define USB_WVALUE_GETDESC_STRING_IPRODUCT  0x2

// Test selector defines for Test mode
#define USB_WINDEX_TEST_J               (0x1<<8)
#define USB_WINDEX_TEST_K               (0x2<<8)
#define USB_WINDEX_TEST_SE0_NAK         (0x3<<8)
#define USB_WINDEX_TEST_PACKET          (0x4<<8)
#define USB_WINDEX_TEST_FORCE_ENABLE    (0x5<<8)

#define USB_MAX_NUM_EP_OUT              (16)
#define USB_MAX_NUM_EP_IN               (16)
#define USB_MAX_NUM_EP                  (32)

#endif
