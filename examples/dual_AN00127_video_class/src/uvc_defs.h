// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef UVC_DEFS_H_
#define UVC_DEFS_H_

/* USB Video device product defines */
#define BCD_DEVICE  0x0100
#define VENDOR_ID   0x20B1
#define PRODUCT_ID  0x1DE0

/* USB Sub class and Protocol codes */
#define USB_VIDEO_CONTROL               0x01
#define USB_VIDEO_STREAMING             0x02
#define USB_VIDEO_INTERFACE_COLLECTION  0x03

/* Descriptor types */
#define USB_DESCTYPE_CS_INTERFACE   0x24
#define USB_DESCTYPE_CS_ENDPOINT    0x25

/* USB Video Control Subtype Descriptors */
#define USB_VC_HEADER           0x01
#define USB_VC_INPUT_TERMINAL   0x02
#define USB_VC_OUPUT_TERMINAL   0x03
#define USB_VC_SELECTOR_UNIT    0x04
#define USB_VC_PROCESSING_UNIT  0x05

/* USB Video Streaming Subtype Descriptors */
#define USB_VS_INPUT_HEADER         0x01
#define USB_VS_OUPUT_HEADER         0x02
#define USB_VS_STILL_IMAGE_FRAME    0x03
#define USB_VS_FORMAT_UNCOMPRESSED  0x04
#define USB_VS_FRAME_UNCOMPRESSED   0x05
#define USB_VS_FORMAT_MJPEG         0x06
#define USB_VS_FRAME_MJPEG          0x07

/* USB Video resolution */
#define BITS_PER_PIXEL 16
#define WIDTH  480
#define HEIGHT 320

/* Frame rate */
#define FPS 30

#define MAX_FRAME_SIZE (WIDTH * HEIGHT * BITS_PER_PIXEL / 8)
#define MIN_BIT_RATE   (MAX_FRAME_SIZE * FPS * 8)
#define MAX_BIT_RATE   (MIN_BIT_RATE)
#define PAYLOAD_SIZE   (1 * 1024)

/* Interval defined in 100ns units */
#define FRAME_INTERVAL       (10000000/FPS)

/* To split numbers into Little Endian format */
#define WORD_CHARS(x)   (x&0xff), ((x>>8)&0xff), ((x>>16)&0xff), ((x>>24)&0xff)
#define SHORT_CHARS(x)  (x&0xff), ((x>>8)&0xff)

/* Endpoint Addresses for Video device */
#define VIDEO_STATUS_EP_NUM         1 /* (0x81) */
#define VIDEO_DATA_EP_NUM           2 /* (0x82) */

/* Video Class-specific Request codes */
#define SET_CUR     0x01
#define GET_CUR     0x81
#define GET_MIN     0x82
#define GET_MAX     0x83
#define GET_RES     0x84
#define GET_LEN     0x85
#define GET_INFO    0x86
#define GET_DEF     0x87

/* Video Streaming Interface Control selectors */
#define VS_PROBE_CONTROL        0x01
#define VS_COMMIT_CONTROL       0x02

/* Video Stream related */
#define PAYLOAD_HEADER_LENGTH 12

#endif /* UVC_DEFS_H_ */
