// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef UVC_REQ_H_
#define UVC_REQ_H_

#include <xccompat.h>
#include "xud_device.h"

/* Video Class-specific requests definitions */

#ifdef __STDC__

/* Video Probe and Commit Controls (Table 4-47 , UVC 1.1) */
typedef struct
{
    unsigned short bmHint;
    unsigned char bFormatIndex;
    unsigned char bFrameIndex;
    unsigned int dwFrameInterval;
    unsigned short wKeyFrameRate;
    unsigned short wPFrameRate;
    unsigned short wCompQuality;
    unsigned short wCompWindowSize;
    unsigned short wDelay;
    unsigned int dwMaxVideoFrameSize;
    unsigned int dwMaxPayloadTransferSize;
    unsigned int dwClockFrequency;
    unsigned char bmFramingInfo;
    unsigned char bPreferedVersion;
    unsigned char bMinVersion;
    unsigned char bMaxVersion;
} __attribute__((packed)) UVC_ProbeCommit_Ctrl_t;

extern UVC_ProbeCommit_Ctrl_t dataProbeCommit;

#endif

void UVC_InitProbeCommitData();

XUD_Result_t UVC_InterfaceClassRequests(XUD_ep ep_out, XUD_ep ep_in, REFERENCE_PARAM(USB_SetupPacket_t,sp));


#endif /* UVC_REQ_H_ */
