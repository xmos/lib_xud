// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <string.h>
#include "uvc_req.h"
#include "uvc_defs.h"

UVC_ProbeCommit_Ctrl_t dataProbeCommit;

/* Initializes Probe/Commit control parameters with defaul values */
void UVC_InitProbeCommitData()
{
    dataProbeCommit.bmHint = 0;
    dataProbeCommit.bFormatIndex = 0x01;
    dataProbeCommit.bFrameIndex = 0x01;
    dataProbeCommit.dwFrameInterval = FRAME_INTERVAL;
    dataProbeCommit.wKeyFrameRate = 0;
    dataProbeCommit.wPFrameRate = 0;
    dataProbeCommit.wCompQuality = 0;
    dataProbeCommit.wCompWindowSize = 0;
    dataProbeCommit.wDelay = 0;
    dataProbeCommit.dwMaxVideoFrameSize = MAX_FRAME_SIZE;
    dataProbeCommit.dwMaxPayloadTransferSize = PAYLOAD_SIZE;
    dataProbeCommit.dwClockFrequency = 100000000;
}


/* Video Class-specific requests handler function */
XUD_Result_t UVC_InterfaceClassRequests(XUD_ep ep_out, XUD_ep ep_in, USB_SetupPacket_t *sp)
{
    /* Word aligned buffer */
    unsigned int probe_buffer[16];
    unsigned int buffer[16];
    unsigned int length;
    XUD_Result_t result = XUD_RES_ERR;

#if defined (DEBUG) && (DEBUG == 1)
    printhexln(sp->bRequest);
#endif

    switch(sp->bRequest)
    {
        case SET_CUR:
            /* VideoStreaming Interface */
            if(sp->wIndex == 0x01)
            {
                switch((sp->wValue >> 8) & 0xFF)
                {
                    /* Negotiation of Video parameters */
                    case VS_COMMIT_CONTROL:
                    case VS_PROBE_CONTROL:
                        /* Get the parameters in Probe buffer */
                        if((result = XUD_GetBuffer(ep_out, (unsigned char *) probe_buffer, &length)) != XUD_RES_OKAY)
                        {
                            return result;
                        }
                        /* Set the given parameters */
                        if(length == sizeof(dataProbeCommit)) {
                            //memcpy(((unsigned char *) &dataProbeCommit)+2, ((unsigned char*)probe_buffer)+2, length-2);
                        }
                        break;
                }
            }
            else
            {
                if((result = XUD_GetBuffer(ep_out, (unsigned char *) buffer, &length)) != XUD_RES_OKAY)
                {
                    return result;
                }
            }

            result = XUD_DoSetRequestStatus(ep_in);
            return result;
            break;

        case GET_DEF:
        case GET_MIN:
        case GET_MAX:
        case GET_CUR:
            /* VideoControl Interface */
            if(sp->wIndex == 0x00)
            {
                /* Handle VideoControl interface requests here */
            }
            /* VideoStreaming Interface */
            else if(sp->wIndex == 0x01)
            {
                switch((sp->wValue >> 8) & 0xFF)
                {
                   case VS_PROBE_CONTROL:
                       if(sp->wLength <= sizeof(dataProbeCommit)) {
                           length = sp->wLength;
                           result = XUD_DoGetRequest(ep_out, ep_in, (unsigned char *) (&dataProbeCommit), length, sp->wLength);
                           return result;
                       }
                       break;

                   default:
                       // Unknown command
                       break;
                }
            }
            break;

        default:
            // Error case
            printhexln(sp->bRequest);
            return result;
            break;
    }
    return XUD_RES_ERR;
}

