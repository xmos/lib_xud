// Copyright 2011-2023 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#if !defined(XUD_BYPASS_RESET)
#include <xs1.h>
#include <platform.h>
#include "xud.h"
#include "XUD_USB_Defines.h"
#include "XUD_TimingDefines.h"
#include "XUD_HAL.h"

extern in  port flag0_port;
extern in  port flag1_port;
extern in  port flag2_port;
extern out buffered port:32 p_usb_txd;

#define TUCHEND_DELAY_us   (1500) // 1.5ms
#define TUCHEND_DELAY      (TUCHEND_DELAY_us * PLATFORM_REFERENCE_MHZ)

#ifndef INVALID_DELAY_us
#define INVALID_DELAY_us   (2500) // 2.5ms
#endif

#define INVALID_DELAY      (INVALID_DELAY_us * PLATFORM_REFERENCE_MHZ)

extern int resetCount;

/* Assumptions:
 * - In full speed mode
 * - No flags sticky
 * - Flag 0 port inverted
 */
int XUD_DeviceAttachHS(XUD_PwrConfig pwrConfig)
{
   unsigned tmp;
   timer t;
   int start_time;
   int detecting_k = 1;
   int tx;
   unsigned int chirpCount = 0;

   clearbuf(p_usb_txd);

   /* On detecting the SE0 move into chirp mode */
   XUD_HAL_EnterMode_PeripheralChirp();

   /* output k-chirp for required time */
#if defined(XUD_SIM_RTL) || (XUD_SIM_XSIM)
   for (int i = 0; i < 800; i++)
#else
   for (int i = 0; i < 16000; i++)    // 16000 words @ 480 MBit = 1.066 ms
#endif
    {
        p_usb_txd <: 0;
    }

   // J, K, SE0 on flag ports 0, 1, 2 respectively (on XS2)
   // XS3 has raw linestate on flag port 0 and 1
   // Wait for fs chirp k (i.e. HS chirp j)
#if defined(__XS2A__)
    flag1_port when pinseq(0) :> tmp; // Wait for out k to go
#endif

    t :> start_time;
    while(1)
    {
        select
        {
            case t when timerafter(start_time + INVALID_DELAY) :> void:

                /* Go into full speed mode: XcvrSelect and Term Select (and suspend) high */
                XUD_HAL_EnterMode_PeripheralFullSpeed();

                /* Wait for end of SE0 */
                while(1)
                {
                    /* TODO Use a timer to save some juice...*/
#if !defined(__XS2A__)
                    unsigned dp, dm;
                    flag0_port :> dm;
                    flag1_port :> dp;

                    if(dp || dm)
                    {
                        /* SE0 gone, return 0 to indicate FULL SPEED */
                        return 0;
                    }
#else
                    flag2_port :> tmp;

                    if(!tmp)
                    {
                        /* SE0 gone, return 0 to indicate FULL SPEED */
                        return 0;
                    }
#endif
                    if(pwrConfig == XUD_PWR_SELF)
                    {
                        if(!XUD_HAL_GetVBusState())
                        {
                            XUD_HAL_EnterMode_TristateDrivers();
                            return -1;             // VBUS gone, handshake fails completely.
                        }
                    }
                }
                break;

#if !defined(__XS2A__)
// Note, J and K definitions are reversed in XS3A
#define j_port flag1_port
#define k_port flag0_port
#else
#define k_port flag1_port
#define j_port flag0_port
#endif
            case detecting_k => k_port when pinseq(1):> void @ tx:       // K Chirp
                k_port @ tx + T_FILT_ticks :> tmp;
                if (tmp)
                {
                    detecting_k = 0;
                }
                break;

             case !detecting_k => j_port when pinseq(1) :> void @ tx:    // J Chirp
                j_port @ tx + T_FILT_ticks :> tmp;
                if (tmp == 1)
                {
                    chirpCount++;                                            // Seen an extra K-J pair
                    detecting_k = 1;

                    if (chirpCount == 3)
                    {
                        /* Three pairs of KJ received. Enter high-speed mode */
                        XUD_HAL_EnterMode_PeripheralHighSpeed();

                        // Wait for SE0 (TODO consume other chirps?)
#if !defined(__XS2A__)
                        // TODO ideally dont use a polling loop here
                        while (XUD_HAL_GetLineState() != XUD_LINESTATE_SE0);
#else
                        flag2_port when pinseq(1) :> tmp;
#endif

                        /* Return 1 to indicate successful HS handshake*/
                        return 1;

                    }
                }
                break;
        }
    }
    // Unreachable
    return -1;
}
#endif
