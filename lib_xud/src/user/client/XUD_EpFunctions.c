// Copyright 2021-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "xud.h"
#include "XUD_USB_Defines.h"

extern XUD_ep_info ep_info[USB_MAX_NUM_EP];

void XUD_ResetEpStateByAddr(unsigned epAddr)
{
    unsigned pid = USB_PIDn_DATA0;
    
#if defined(__XS2A__)
    /* Check IN bit of address */
    if((epAddr & 0x80) == 0)
    {
        pid = USB_PID_DATA0;     
    }
#endif

    if(epAddr & 0x80)
    {
        epAddr &= 0x7F;
        epAddr += USB_MAX_NUM_EP_OUT;
    } 
    
    XUD_ep_info *ep = &ep_info[epAddr];
    ep->pid = pid;
}

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
        epNum &= 0x7F;
        epNum += USB_MAX_NUM_EP_OUT;
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

/* ignoreHalted should only be used for Setup data */
static inline XUD_Result_t XUD_GetBuffer_Start(volatile XUD_ep_info *ep, unsigned char buffer[], const int ignoreHalted)
{
    /* If EP is marked as halted do not mark as ready.. */
    do
    {
        /* Check if we missed a reset */
        if(ep->resetting)
        {
            return XUD_RES_RST;
        }
    }
    while((ep->halted == USB_PIDn_STALL) && !ignoreHalted);

    /* Store buffer address in EP structure */
    ep->buffer = (unsigned) &buffer[0];

    unsigned * array_ptr = (unsigned *)ep->array_ptr;
    *array_ptr = (unsigned) ep;

    return XUD_RES_OKAY;
}

XUD_Result_t XUD_GetBuffer_Finish(chanend c, XUD_ep e, unsigned *datalength)
{   // NOCOVER
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    
    unsigned length;
    unsigned lengthTail;
    unsigned isReset;

    /* Wait for XUD response */
    asm volatile("testct %0, res[%1]" : "=r"(isReset) : "r"(c));

    if(isReset)
    {
        return XUD_RES_RST;
    }
    
    /* Input packet length (words) */
    asm volatile("in %0, res[%1]" : "=r"(length) : "r"(c));
   
    /* Input tail length (bytes) */ 
    asm volatile("int %0, res[%1]" : "=r"(lengthTail) : "r"(c));

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
        *datalength = 0; /* Extra safety measure */
        return XUD_RES_ERR;
    }

    /* ISO == 0 */
    if(ep->epType != XUD_EPTYPE_ISO)
    {
#ifdef __XS2A__
        ep->pid ^= 0x8;
#else
        ep->pid ^= 0x88; 
#endif
    }
   
    return XUD_RES_OKAY;
}  // NOCOVER

XUD_Result_t XUD_GetBuffer(XUD_ep e, unsigned char buffer[], unsigned *datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
  
    while(1)
    { 
        XUD_Result_t result = XUD_GetBuffer_Start(ep, buffer, 0);

        if(result == XUD_RES_RST)
        {
            return XUD_RES_RST;
        }

        result = XUD_GetBuffer_Finish(ep->client_chanend, ep, datalength);
   
        /* If error (e.g. bad PID seq) try again */ 
        if(result != XUD_RES_ERR)
        {
            return result;
        }
    }
}

int XUD_SetReady_Out(XUD_ep e, unsigned char buffer[])
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    return XUD_GetBuffer_Start(ep, buffer, 0);
}

void XUD_GetData_Select(chanend c, XUD_ep e, unsigned *datalength, XUD_Result_t *result)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    
    *result = XUD_GetBuffer_Finish(ep->client_chanend, ep, datalength);
}

XUD_Result_t XUD_GetSetupData(XUD_ep e, unsigned char buffer[], unsigned *datalength)
{

    volatile XUD_ep_info *ep = (XUD_ep_info*) e;
    unsigned isReset;
    unsigned length;
    unsigned lengthTail;
    
    XUD_Result_t result = XUD_GetBuffer_Start(ep, buffer, 1);

    if(result == XUD_RES_RST)
    {
        return XUD_RES_RST;
    }

    /* Wait for XUD response */
    asm volatile("testct %0, res[%1]" : "=r"(isReset) : "r"(ep->client_chanend));

    if(isReset)
    {
        return XUD_RES_RST;
    }
    
    /* Input packet length (words) */
    asm volatile("in %0, res[%1]" : "=r"(length) : "r"(ep->client_chanend));
   
    /* Input tail length (bytes) */ 
    /* TODO Check CT vs T */
    asm volatile("inct %0, res[%1]" : "=r"(lengthTail) : "r"(ep->client_chanend));

    /* Reset PID toggling on receipt of SETUP (both IN and OUT) */
#ifdef __XS2A__
    ep->pid = USB_PID_DATA1;
#else
    ep->pid = USB_PIDn_DATA1;
#endif

    /* Reset IN EP PID */
    XUD_ep_info *ep_in = (XUD_ep_info*) ((unsigned)ep + (USB_MAX_NUM_EP_OUT * sizeof(XUD_ep_info)));
    ep_in->pid = USB_PIDn_DATA1;

    /* TODO check that this is the case */
    *datalength = 8;

    return XUD_RES_OKAY;
}

XUD_Result_t XUD_SetBuffer_Start(XUD_ep e, unsigned char buffer[], unsigned datalength)
{   // NOCOVER
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    while(1)
    {
        /* Check if we missed a reset */
        if(ep->resetting)
        {
            return XUD_RES_RST;
        }

        /* If EP is marked as halted do not mark as ready.. */
        if(ep->halted != USB_PIDn_STALL)
        {
            break;
        } 
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
    ep->actualPid = lengthWords; /* Re-use of actualPid entry - TODO rename */
    ep->tailLength = lengthTail;

    unsigned * array_ptr = (unsigned *)ep->array_ptr;
    *array_ptr = (unsigned) ep;

    return XUD_RES_OKAY;
}

XUD_Result_t XUD_SetBuffer_Finish(chanend c, XUD_ep e)
{   // NOCOVER
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    unsigned isReset;
    unsigned tmp;

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
}   // NOCOVER

XUD_Result_t XUD_SetBuffer(XUD_ep e, unsigned char buffer[], unsigned datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
   
    XUD_Result_t result = XUD_SetBuffer_Start(e, buffer, datalength);

    if(result == XUD_RES_RST)
    {
        return result;
    }

    return XUD_SetBuffer_Finish(ep->client_chanend, ep);
}

void XUD_SetData_Select(chanend c, XUD_ep e, XUD_Result_t *result)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    
    *result = XUD_SetBuffer_Finish(ep->client_chanend, e);
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
