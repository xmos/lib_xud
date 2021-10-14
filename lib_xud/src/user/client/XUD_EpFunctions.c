#include "xud.h"
#include "XUD_USB_Defines.h"


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
        if(ep->epType)
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

