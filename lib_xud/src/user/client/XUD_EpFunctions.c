// Copyright 2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "xud.h"
#include "XUD_USB_Defines.h"

extern XUD_ep_info ep_info[USB_MAX_NUM_EP];

void XUD_SetStallByAddr(int epNum)
{
    if(epNum & 0x80)
    {
        epNum &= 0x7f;
        epNum += 16;
    }
   
    XUD_ep_info *ep = &ep_info[epNum];

    unsigned *epReadyEntry = (unsigned *)ep->array_ptr;
    
    if(*epReadyEntry != 0)
    {
        /* Mark EP as not ready (and save that it was ready at Halting */
        ep->saved_array_ptr = *epReadyEntry;
        *epReadyEntry = 0;
    }
    ep->halted = USB_PIDn_STALL;
}

void XUD_ClearStallByAddr(int epNum)
{
    unsigned handshake = USB_PIDn_NAK;
  
    /* Reset data PID */
    XUD_ResetEpStateByAddr(epNum);

    if(epNum & 0x80)
    {
        epNum &= 0x7f;
        epNum += 16;
        handshake = 0;
    }
    
    XUD_ep_info *ep = &ep_info[epNum];

    /* Re-mark as ready if was ready before halting */
    if(ep->saved_array_ptr != 0)
    {
        unsigned *epReadyEntry = (unsigned *)ep->array_ptr;
        *epReadyEntry = ep->saved_array_ptr;
        ep->saved_array_ptr = 0;
    }

    /* Mark EP as un-halted */
    ep->halted = handshake;
}


XUD_Result_t XUD_SetBuffer(XUD_ep e, unsigned char buffer[], unsigned datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    unsigned isReset;
    unsigned tmp;
    
    while(1)
    {
        /* Check if we missed a reset */
        if(ep->resetting)
        {
            return XUD_RES_RST;
        }

        /* If EP is marked as halted do not mark as ready.. */
        if(ep->halted == USB_PIDn_STALL)
        {
            continue;
        } 

        int lengthWords = datalength >> 2;
        unsigned lengthTail = (datalength << 3) & 0x1f; // zext(5)?

        if((lengthTail == 0) && (lengthWords != 0))
        {
            lengthWords -= 1;
            lengthTail = 32;
        }

        /* Store end of buffer address in EP structure */
        ep->buffer = (unsigned) &buffer[0] + (lengthWords * 4);

        /* XUD uses negative index */
        lengthWords *= -1;
        ep->actualPid = lengthWords; /* Re-used of actualPid entry - TODO rename */
        ep->tailLength = lengthTail;

        unsigned * array_ptr = (unsigned *)ep->array_ptr;
        *array_ptr = (unsigned) ep;
        
        /* Wait for XUD response */
        asm volatile("testct %0, res[%1]" : "=r"(isReset) : "r"(ep->client_chanend));

        if(isReset)
        {
            return XUD_RES_RST;
        }

        /* Data sent okay */
        asm volatile("in %0, res[%1]" : "=r"(tmp) : "r"(ep->client_chanend));

        /* Don't do any PID toggling for Iso EP's */
        if(ep->epType != XUD_EPTYPE_ISO)
        {
            ep->pid ^= 0x88; 
        }
        
        return XUD_RES_OKAY;
    }
}

XUD_Result_t XUD_GetBuffer(XUD_ep e, unsigned char buffer[], unsigned *datalength)
{

    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    unsigned isReset;
    unsigned length;
    unsigned lengthTail;
    
    while(1)
    {
        /* Check if we missed a reset */
        if(ep->resetting)
        {
            return XUD_RES_RST;
        }

        /* If EP is marked as halted do not mark as ready.. */
        if(ep->halted == USB_PIDn_STALL)
        {
            continue;
        } 

        /* Store buffer address in EP structure */
        ep->buffer = (unsigned) &buffer[0];

        unsigned * array_ptr = (unsigned *)ep->array_ptr;
        *array_ptr = (unsigned) ep;
        
        /* Wait for XUD response */
        asm volatile("testct %0, res[%1]" : "=r"(isReset) : "r"(ep->client_chanend));

        if(isReset)
        {
            return XUD_RES_RST;
        }

        /* Input packet length (words) */
        asm volatile("in %0, res[%1]" : "=r"(length) : "r"(ep->client_chanend));
       
        /* Input tail length (bytes) */ 
        asm volatile("int %0, res[%1]" : "=r"(lengthTail) : "r"(ep->client_chanend));

        /* Bits to bytes */
        lengthTail >>= 3;

        /* Words to bytes */
        length <<= 2;

        /* -2 length correction for CRC */
        *datalength = length + lengthTail - 2;

        /* Load received PID */
        unsigned receivedPid = ep->actualPid;
       
        /* Check received PID vs expected PID */
        if(receivedPid != ep->pid) 
        {
            continue;
        }

        // ISO = 0
        if(ep->epType != XUD_EPTYPE_ISO)
        {
#ifdef __XS2A__
            ep->pid ^= 0x8;
#else
            ep->pid ^= 0x88; 
#endif
        }
        
        return XUD_RES_OKAY;
    }
}

XUD_Result_t XUD_SetBuffer_EpMax(XUD_ep ep_in, unsigned char buffer[], unsigned datalength, unsigned epMax)
{
    int i = 0;
    XUD_Result_t result;

    /* Note: We could encompass this in the SetData function */
    if (datalength <= epMax)
    {
        /* Datalength is less than the maximum per transaction of the EP, so just send */
        result = XUD_SetBuffer(ep_in, buffer, datalength);
        return result;
    }
    else
    {
        /* Send first packet out and reset PID */
        if((result = XUD_SetBuffer(ep_in, buffer, epMax)) != XUD_RES_OKAY)
        {
            return result;
        }
        
        i += epMax;
        datalength -= epMax;

        while (1)
	    {
            unsigned char *bufferPtr = &buffer[i]; 

            if (datalength > epMax)
	        {
                /* PID Automatically toggled */
                if ((result = XUD_SetBuffer(ep_in, bufferPtr, epMax)) != XUD_RES_OKAY)
                    return result;

                datalength -= epMax;
                i += epMax;
	        }
	        else
	        {
                /* PID automatically toggled */
                if ((result = XUD_SetBuffer(ep_in, bufferPtr, datalength)) != XUD_RES_OKAY)
                    return result;

	            break; //out of while loop
	        }
	    }
    }

    return XUD_RES_OKAY;
}

