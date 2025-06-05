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
    if(ep->epType != XUD_EPTYPE_ISO)
    {
        ep->pid = pid;
    }
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

__attribute__((always_inline)) static XUD_Result_t XUD_GetBuffer_Finish(chanend c, XUD_ep e, unsigned *datalength)
{   // NOCOVER
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    unsigned length;
    unsigned lengthTail;
    unsigned busUpdate;
    unsigned recv_length;


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

    unsigned frame;
    asm volatile("int %0, res[%1]" : "=r"(frame) : "r"(c));

    /* Bits to bytes */
    lengthTail >>= 3;

    /* Words to bytes */
    length <<= 2;

    /* -2 length correction for CRC */
    recv_length = length + lengthTail - 2;

#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    unsigned ep_marked_ready = 0;
    if(!ep->out_err_flag && ep->actualPid == USB_PIDn_MDATA)
    {
        // We expect more data
        ep->buffer += recv_length;
        /* Mark EP as ready */
        unsigned * array_ptr = (unsigned *)ep->array_ptr;
        *array_ptr = (unsigned) ep;
        ep_marked_ready = 1;
    }
    unsigned got_sof = (ep->saved_frame != frame) ? 1 : 0;
    ep->saved_frame = frame;
#endif

#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME == 1)
    /* Load received PID */
    unsigned receivedPid = ep->actualPid;

    /* Check received PID vs expected PID */
    if(receivedPid != ep->pid)
    {
        *datalength = 0; /* Extra safety measure */
        XUD_Result_t res = XUD_GetBuffer_Start(ep, ep->buffer);
        if(res == XUD_RES_UPDATE) return res;
        return XUD_RES_ERR;
    }
    else
    {
        *datalength = recv_length;
    }
#endif

    /* ISO == 0 */
    if(ep->epType != XUD_EPTYPE_ISO)
    {
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
        /* Load received PID */
        unsigned receivedPid = ep->actualPid;

        /* Check received PID vs expected PID */
        if(receivedPid != ep->pid)
        {
            *datalength = 0; /* Extra safety measure */
            XUD_Result_t res = XUD_GetBuffer_Start(ep, ep->buffer);
            if(res == XUD_RES_UPDATE) return res;
            return XUD_RES_ERR;
        }
        else
        {
            *datalength = recv_length;
        }
#endif
#ifdef __XS2A__
        ep->pid ^= 0x8;
#else
        ep->pid ^= 0x88;
#endif
    }
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    else
    {
        /// Limitation: We only support a max of 2 transactions per OUT transfer. ep->current_transaction can only be 0 or 1
        unsigned current_transaction = ep->current_transaction;
        unsigned error = ep->out_err_flag; // If we're already in error from last transaction
        if(current_transaction == 0)
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
            if(ep_marked_ready)
            {
                // Can't undo having marked EP as ready, so set ep in error (ep->out_err_flag = 1) and handle at the finish of next packet.
                // NOTE, this assumes that we have an extra ep->max_len worth of memory in the buffer
                ep->out_err_flag = 1;
                return XUD_RES_WAIT;
            }
            else // For everything else, i.e whether we've detected an error this transaction or handling an error from the previous transaction,
                 //we roll back the buffer ptr, mark next transaction as index 0 and hope to eventually sync with a SOF
            {
                // Ignore everything recvd so far in this microframe
                // and mark EP ready with the original buffer start address
                ep->buffer = ep->save_buffer;
                /* Mark EP as ready */
                unsigned * array_ptr = (unsigned *)ep->array_ptr;
                *array_ptr = (unsigned) ep;
                ep->out_err_flag = 0;
                ep->remained = 0;
                ep->current_transaction = 0;
                return XUD_RES_WAIT;
            }
        }
        else if(ep_marked_ready) // No error and ep marked ready for receiving the next transaction in this microframe
        {
            ep->remained += recv_length;
            ep->current_transaction = 1; // We only support 2 transactions per microframe so USB_PIDn_MDATA can only be transaction 0, so setting next transaction to 1
            return XUD_RES_WAIT;
        }
        else // Not error and not marked ready. We must have received a complete transfer so return
        {
            // Received the full transfer. Notify client by setting *datalength to the
            // received transfer length
            *datalength = recv_length + ep->remained;
        }
    }
    #endif
    return XUD_RES_OKAY;

}  // NOCOVER

XUD_Result_t XUD_DoSetRequestStatus(XUD_ep ep_in)
{
    unsigned char tmp[8];

    /* Send 0 length packet */
    return XUD_SetBuffer(ep_in, tmp, 0);
}

/// Initialise fields in the XUD_ep_info structure before marking EP ready for a new OUT transfer
__attribute__((always_inline)) static void XUD_initialise_OUT_transfer(XUD_ep_info * ep, unsigned char buffer[])
{
    ep->current_transaction = 0;
    ep->remained = 0;
    ep->save_buffer = (unsigned)buffer;
}

XUD_Result_t XUD_GetBuffer(XUD_ep e, unsigned char buffer[], unsigned *datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    XUD_initialise_OUT_transfer(ep, buffer);
#endif
    XUD_Result_t result = XUD_GetBuffer_Start(ep, buffer);

    if(result == XUD_RES_UPDATE)
    {
        return result;
    }

    while(1)
    {
        result = XUD_GetBuffer_Finish(ep->client_chanend, e, datalength);

        /* If error (e.g. bad PID seq) try again */
        // return on okay and reset
        if((result == XUD_RES_OKAY) || (result == XUD_RES_UPDATE))
        {
            return result;
        }
    }
}

int XUD_SetReady_Out(XUD_ep e, unsigned char buffer[])
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    XUD_initialise_OUT_transfer(ep, buffer);
#endif
    return XUD_GetBuffer_Start(ep, buffer);
}

void XUD_GetData_Select(chanend c, XUD_ep e, unsigned *datalength, XUD_Result_t *result)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;

    *result = XUD_GetBuffer_Finish(ep->client_chanend, e, datalength);
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

    unsigned send_len;
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    if(datalength > ep->max_len)
    {
        send_len = ep->max_len;
        ep->remained = datalength - send_len;
    }
    else
    {
        send_len = datalength;
        ep->remained =  0;
    }
#else
    send_len = datalength;
#endif

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

#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    unsigned current_transaction = ep->current_transaction;
    if(ep->epType == XUD_EPTYPE_ISO)
    {
        if(ep->num_transactions  == 2)
        {
            if(current_transaction == 0)
            {
                ep->pid = USB_PIDn_DATA1;
            }
            else if(current_transaction == 1)
            {
                ep->pid = USB_PIDn_DATA0;
            }
        }
        else // ep->num_transactions == 1
        {
            ep->pid = USB_PIDn_DATA0;
        }
    }
#endif

    unsigned * array_ptr = (unsigned *)ep->array_ptr;
    *array_ptr = (unsigned) ep;

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
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    else
    {
        unsigned got_sof = (ep->saved_frame != frame) ? 1 : 0; // Between this finish and the last, was there a SOF received.
        unsigned save_saved_frame = ep->saved_frame;
        ep->saved_frame = frame;

        // Check if the finished transaction is correct wrt SOF information
        if(ep->current_transaction == 0)
        {
            if(!got_sof) // We expect to have received a SOF. Continue remaining in current_transaction=0 and retry from the start of this transfer
            {
                XUD_SetBuffer_Start(e, ep->save_buffer, ep->save_length);
                return XUD_RES_WAIT;
            }
            else if(ep->remained)
            {
                // Transfer not yet complete. Mark EP ready for next transection
                ep->current_transaction = 1;
                XUD_SetBuffer_Start(e, ep->buffer+4, ep->remained); // TODO +4 to compensate for lengthTail. See XUD_SetBuffer_Start
                return XUD_RES_WAIT;
            }
        }
        else // current_transaction = 1
        {
            if(got_sof) // we dont expect to have received a sof
            {
                // This is error. Notify client, who is then expected to issue a new transfer
                return XUD_RES_ERR;
            }
        }
    }
#endif

    return XUD_RES_OKAY;
}   // NOCOVER

/// Initialise fields in the XUD_ep_info structure before marking EP ready for a new IN transfer
__attribute__((always_inline)) static void XUD_initialise_IN_transfer(XUD_ep_info * ep, unsigned char buffer[], unsigned datalength)
{
    unsigned N = 0;
    unsigned full_len = datalength;

    while(full_len != 0){
        unsigned len = (full_len >= ep->max_len) ? ep->max_len : full_len;
        full_len -= len;
        N++;
    }
    ep->current_transaction = 0;
    ep->save_buffer = (unsigned)buffer;
    ep->save_length = (unsigned)datalength;
    ep->num_transactions = N;
}

XUD_Result_t XUD_SetBuffer(XUD_ep e, unsigned char buffer[], unsigned datalength)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    XUD_initialise_IN_transfer(ep, buffer, datalength);
#endif
    XUD_Result_t result = XUD_SetBuffer_Start(e, buffer, datalength);

    if(result == XUD_RES_UPDATE)
    {
        return result;
    }

    while(1)
    {
        result = XUD_SetBuffer_Finish(ep->client_chanend, e);
        if (result != XUD_RES_WAIT)
        {
            return result;
        }
    }
}

XUD_Result_t XUD_SetReady_In(XUD_ep e, unsigned char buffer[], int len)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    XUD_initialise_IN_transfer(ep, buffer, len);
#endif
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

// legacy

XUD_Result_t XUD_SetReady_OutPtr(XUD_ep e, unsigned addr)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    XUD_initialise_OUT_transfer(ep, addr);
#endif
    return XUD_GetBuffer_Start(ep, (unsigned char *)addr);
}

XUD_Result_t XUD_SetReady_InPtr(XUD_ep e, unsigned addr, int len)
{
    volatile XUD_ep_info * ep = (XUD_ep_info*) e;
#if (XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME > 1)
    XUD_initialise_IN_transfer(ep, addr, len);
#endif
    return XUD_SetBuffer_Start(ep, (unsigned char *) addr, len);
}
