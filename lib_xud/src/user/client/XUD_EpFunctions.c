// Copyright 2021-2025 XMOS LIMITED.
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

void XUD_SetStall(XUD_ep e)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    XUD_SetStallByAddr(ep->epAddress);
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

void XUD_ClearStall(XUD_ep e)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    XUD_ClearStallByAddr(ep->epAddress);
}

static inline XUD_Result_t XUD_GetBuffer_Start(volatile XUD_ep_info *ep, unsigned char buffer[])
{
    /* If EP is marked as halted do not mark as ready.. */
    do
    {
        /* Check if we missed a reset */
        if(ep->busUpdate)
        {
            return XUD_RES_UPDATE;
        }
    }
    while(ep->halted == USB_PIDn_STALL);

    /* Store buffer address in EP structure */
    ep->buffer = (unsigned) &buffer[0];

    /* Mark EP as ready */
    unsigned * array_ptr = (unsigned *)ep->array_ptr;
    *array_ptr = (unsigned) ep;

    return XUD_RES_OKAY;
}

XUD_Result_t XUD_GetBuffer_Finish(chanend c, XUD_ep e, unsigned *datalength)
{   // NOCOVER
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    unsigned length;
    unsigned lengthTail;
    unsigned busUpdate;

    /* Wait for XUD response */
    asm volatile("testct %0, res[%1]" : "=r"(busUpdate) : "r"(c));

    if(busUpdate)
    {
        return XUD_RES_UPDATE;
    }

    /* Input packet length (words) */
    asm volatile("in %0, res[%1]" : "=r"(length) : "r"(c));

    /* Input tail length (bytes) */
    asm volatile("int %0, res[%1]" : "=r"(lengthTail) : "r"(c));

    unsigned got_sof;
    if(ep->epType == XUD_EPTYPE_ISO) {
        unsigned frame;
        asm volatile("int %0, res[%1]" : "=r"(frame) : "r"(c));
        got_sof = (ep->saved_frame != frame) ? 1 : 0;
        ep->saved_frame = frame;

    }

    /* Bits to bytes */
    lengthTail >>= 3;

    /* Words to bytes */
    length <<= 2;

    /* -2 length correction for CRC */
    *datalength = length + lengthTail - 2;

#ifndef USB_HBW_EP
    /* Load received PID */
    unsigned receivedPid = ep->actualPid;

    /* Check received PID vs expected PID */
    if(receivedPid != ep->pid)
    {
        *datalength = 0; /* Extra safety measure */
        return XUD_RES_ERR;
    }
#endif

    /* ISO == 0 */
    if(ep->epType != XUD_EPTYPE_ISO)
    {
#ifdef USB_HBW_EP
    /* Load received PID */
    unsigned receivedPid = ep->actualPid;

    /* Check received PID vs expected PID */
    if(receivedPid != ep->pid)
    {
        *datalength = 0; /* Extra safety measure */
        return XUD_RES_ERR;
    }
#endif
#ifdef __XS2A__
        ep->pid ^= 0x8;
#else
        ep->pid ^= 0x88;
#endif
    }
#ifdef USB_HBW_EP
    else
    {
        unsigned tr = ep->tr;
        ep->remained += *datalength;
        if(ep->actualPid == USB_PIDn_MDATA)
        {
            ep->buffer += *datalength;

            /* Mark EP as ready */
            unsigned * array_ptr = (unsigned *)ep->array_ptr;
            *array_ptr = (unsigned) ep;
            //XUD_GetBuffer_Start(ep, ep->buffer);
            *datalength = 0;
            return XUD_RES_OKAY;
        }
        else
        {
            *datalength = ep->remained;
            ep->remained = 0;
            return XUD_RES_OKAY;
        }
    }
#endif

    return XUD_RES_OKAY;
}  // NOCOVER

XUD_Result_t XUD_GetBuffer_Finish_ISO(chanend c, XUD_ep e, unsigned *datalength)
{   // NOCOVER
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    unsigned length;
    unsigned lengthTail;
    unsigned recv_length;

    /* Input packet length (words) */
    asm volatile("in %0, res[%1]" : "=r"(length) : "r"(c));

    /* Input tail length (bytes) */
    asm volatile("int %0, res[%1]" : "=r"(lengthTail) : "r"(c));

    unsigned got_sof;
    unsigned frame;
    asm volatile("int %0, res[%1]" : "=r"(frame) : "r"(c));
    got_sof = (ep->saved_frame != frame) ? 1 : 0;
    ep->saved_frame = frame;

    /* Bits to bytes */
    lengthTail >>= 3;

    /* Words to bytes */
    length <<= 2;

    /* -2 length correction for CRC */
    recv_length = length + lengthTail - 2;

    /// Limitation: We only support a max of 2 transactions. tr = 0 and tr = 1
    unsigned error = 0;
    unsigned tr = ep->tr;
    if(tr == 0)
    {
        // 1st transaction can only be DATA0 or MDATA and it should see a sof
        if(!got_sof || (ep->actualPid == USB_PIDn_DATA1))
        {
            error = 1;
        }
    }
    else
    {
        // 2nd transaction can only be DATA1 and shouldn't see a sof
        if(got_sof || (ep->actualPid != USB_PIDn_DATA1))
        {
            error = 1;
        }
    }
    if(error)
    {
        // Ignore everything recvd so far in this microframe
        // and mark EP ready with the original buffer start address
        ep->remained = 0;
        ep->tr = 0;
        ep->buffer = ep->save_buffer;
        /* Mark EP as ready */
        unsigned * array_ptr = (unsigned *)ep->array_ptr;
        *array_ptr = (unsigned) ep;
        *datalength = 0;
    }
    else if(ep->actualPid == USB_PIDn_MDATA)
    {
        // We expect more data
        ep->buffer += recv_length;
        /* Mark EP as ready */
        unsigned * array_ptr = (unsigned *)ep->array_ptr;
        *array_ptr = (unsigned) ep;
        ep->remained += recv_length;
        ep->tr = 1;
        *datalength = 0;
    }
    else
    {
        // Received the full frame. Notify client by setting *datalength to the
        // received frame length
        *datalength = recv_length + ep->remained;
    }
    return XUD_RES_OKAY;

}  // NOCOVER

XUD_Result_t XUD_DoSetRequestStatus(XUD_ep ep_in)
{
    unsigned char tmp[8];

    /* Send 0 length packet */
    return XUD_SetBuffer(ep_in, tmp, 0);
}

static XUD_Result_t XUD_GetBuffer_one(XUD_ep e, unsigned char buffer[], unsigned *datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    while(1)
    {
        XUD_Result_t result = XUD_GetBuffer_Start(ep, buffer);

        if(result == XUD_RES_UPDATE)
        {
            return XUD_RES_UPDATE;
        }

        result = XUD_GetBuffer_Finish(ep->client_chanend, e, datalength);

        /* If error (e.g. bad PID seq) try again */
        if(result != XUD_RES_ERR)
        {
            return result;
        }
    }
}

XUD_Result_t XUD_GetBuffer(XUD_ep e, unsigned char buffer[], unsigned *datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    unsigned len = 0;
    *datalength = 0;

    do{
        XUD_Result_t res = XUD_GetBuffer_one(e, buffer, &len);
        if(res != XUD_RES_OKAY) return res;
        buffer = &buffer[len];
        *datalength += len;
    }while(ep->actualPid == USB_PIDn_MDATA);
    return XUD_RES_OKAY;
}

int XUD_SetReady_Out(XUD_ep e, unsigned char buffer[])
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    return XUD_GetBuffer_Start(ep, buffer);
}

void XUD_GetData_Select(chanend c, XUD_ep e, unsigned *datalength, XUD_Result_t *result)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    *result = XUD_GetBuffer_Finish_ISO(ep->client_chanend, e, datalength);
}

XUD_Result_t XUD_GetSetupBuffer(XUD_ep e, unsigned char buffer[], unsigned *datalength)
{
    volatile XUD_ep_info *ep = (XUD_ep_info*) e;
    unsigned busUpdate;
    unsigned length;
    unsigned lengthTail;

    /* Check if we missed a bus state update */
    if(ep->busUpdate)
    {
        return XUD_RES_UPDATE;
    }

    /* Store buffer address in EP structure */
    ep->buffer = (unsigned) &buffer[0];

    /* Mark EP as ready for SETUP data */
    unsigned * array_ptr_setup = (unsigned *)ep->array_ptr_setup;
    *array_ptr_setup = (unsigned) ep;

    /* Wait for XUD response */
    asm volatile("testct %0, res[%1]" : "=r"(busUpdate) : "r"(ep->client_chanend));

    if(busUpdate)
    {
        return XUD_RES_UPDATE;
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
        if(ep->busUpdate)
        {
            return XUD_RES_UPDATE;
        }

        /* If EP is marked as halted do not mark as ready.. */
        if(ep->halted != USB_PIDn_STALL)
        {
            break;
        }
    }
    unsigned send_len = (datalength > ep->max_len) ? ep->max_len : datalength;
    unsigned remained = datalength - send_len;

    int lengthWords = send_len >> 2;
    unsigned lengthTail = (send_len << 3) & 0x1f; // zext(5)?

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

#ifdef USB_HBW_EP
    if(ep->epType == XUD_EPTYPE_ISO)
    {
        unsigned N = ep->N_tr;
        unsigned tr = ep->tr;
        if(N == 3)
        {
            if(tr == 0) // current transfer
            {
                ep->pid = USB_PIDn_DATA2;
                ep->tr = 1; // next transfer
                ep->first_pid = USB_PIDn_DATA2;
            }
            else if(tr == 1)
            {
                ep->pid = USB_PIDn_DATA1;
                ep->tr = 2;
            }
            else if(tr == 2)
            {
                ep->pid = USB_PIDn_DATA0;
                ep->tr = 0;
            }
            else
            {
                return XUD_RES_ERR;
            }
        }
        else if(N == 2)
        {
            if(tr == 0)
            {
                ep->pid = USB_PIDn_DATA1;
                ep->tr = 1;
                ep->first_pid = USB_PIDn_DATA1;
            }
            else if(tr == 1)
            {
                ep->pid = USB_PIDn_DATA0;
                ep->tr = 0;
            }
            else
            {
                return XUD_RES_ERR;
            }
        }
        else if(N == 1)
        {
            ep->pid = USB_PIDn_DATA0;
            ep->tr = 0;
            ep->first_pid = USB_PIDn_DATA0;
        }
        else
        {
            return XUD_RES_ERR;
        }
    }
#endif

    return XUD_RES_OKAY;
}

XUD_Result_t XUD_SetBuffer_Finish(chanend c, XUD_ep e)
{   // NOCOVER
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    unsigned isReset;
    unsigned frame;

    /* Wait for XUD response */
    asm volatile("testct %0, res[%1]" : "=r"(isReset) : "r"(ep->client_chanend));

    if(isReset)
    {
        return XUD_RES_UPDATE;
    }

    /* Data sent okay */
    asm volatile("in %0, res[%1]" : "=r"(frame) : "r"(ep->client_chanend));

    /* Don't do any PID toggling for Iso EP's */
    if(ep->epType != XUD_EPTYPE_ISO)
    {
        ep->pid ^= 0x88;
    }
#ifdef USB_HBW_EP
    else
    {
        ep->got_sof = (ep->saved_frame != frame) ? 1 : 0; // Between this finish and the last, was there a SOF received.
        unsigned save_saved_frame = ep->saved_frame;
        ep->saved_frame = frame;

        // Check if what's completed was correct wrt got_sof
        if(ep->pid != ep->first_pid) // If not the first subpacket
        {
            if(ep->got_sof) // we dont expect to have received a sof
            {
                // This is error. Notify client, who is then expected to issue a new transfer
                return XUD_RES_ERR;
            }
            else if(ep->remained)
            {
                XUD_SetBuffer_Start(ep, ep->buffer+4, ep->remained); // TODO +4 to compensate for lengthTail. See XUD_SetBuffer_Start
                return XUD_RES_WAIT;
            }
        }
        else // first subpacket of the frame
        {
            if(!ep->got_sof) // We expect to have received a SOF
            {
                ep->tr = 0;
                XUD_SetBuffer_Start(ep, ep->save_buffer, ep->save_length); // TODO +4 to compensate for lengthTail. See XUD_SetBuffer_Start
                // TODO repeat the first subframe till we receive a SOF
                return XUD_RES_ERR;
            }
            else if(ep->remained)
            {
                XUD_SetBuffer_Start(ep, ep->buffer+4, ep->remained); // TODO +4 to compensate for lengthTail. See XUD_SetBuffer_Start
                return XUD_RES_WAIT;
            }
        }
    }
#endif

    return XUD_RES_OKAY;
}   // NOCOVER

static XUD_Result_t XUD_SetBuffer_one(XUD_ep e, unsigned char buffer[], unsigned datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    XUD_Result_t result = XUD_SetBuffer_Start(e, buffer, datalength);

    if(result == XUD_RES_UPDATE)
    {
        return result;
    }

    return XUD_SetBuffer_Finish(ep->client_chanend, e);
}

XUD_Result_t XUD_SetBuffer(XUD_ep e, unsigned char buffer[], unsigned datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    unsigned N = 0;
    unsigned full_len = datalength;

    while(full_len != 0){
        unsigned len = (full_len >= ep->max_len) ? ep->max_len : full_len;
        full_len -= len;
        N++;
    }
    ep->N_tr = N;

    // do error handling for when trying to send more data then allowed?

    do{
        unsigned send_len = (datalength >= ep->max_len) ? ep->max_len : datalength;
        datalength -= send_len;
        XUD_Result_t res = XUD_SetBuffer_one(e, buffer, send_len);
        if(res != XUD_RES_OKAY) return res;
        buffer = &buffer[send_len];
    }while(datalength != 0);
    return XUD_RES_OKAY;
}

XUD_Result_t XUD_SetReady_In(XUD_ep e, unsigned char buffer[], int len)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    return XUD_SetBuffer_Start(ep, buffer, len);
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
        result = XUD_SetBuffer_one(ep_in, buffer, datalength);
        return result;
    }
    else
    {
        /* Send first packet out and reset PID */
        if((result = XUD_SetBuffer_one(ep_in, buffer, epMax)) != XUD_RES_OKAY)
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
                if ((result = XUD_SetBuffer_one(ep_in, bufferPtr, epMax)) != XUD_RES_OKAY)
                    return result;

                datalength -= epMax;
                i += epMax;
            }
            else
            {
                /* PID automatically toggled */
                if ((result = XUD_SetBuffer_one(ep_in, bufferPtr, datalength)) != XUD_RES_OKAY)
                    return result;

                break; //out of while loop
            }
        }
    }

    return XUD_RES_OKAY;
}

// legacy

XUD_Result_t XUD_SetReady_OutPtr(XUD_ep e, unsigned addr)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    return XUD_GetBuffer_Start(ep, (unsigned char *)addr);
}

XUD_Result_t XUD_SetReady_InPtr(XUD_ep e, unsigned addr, int len)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
    return XUD_SetBuffer_Start(ep, (unsigned char *) addr, len);
}
