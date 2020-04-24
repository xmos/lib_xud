// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved
#if !defined(XUD_BYPASS_RESET) && !defined(XUD_SIM_XSIM)
#include <xs1.h>
#include <print.h>
#include <platform.h>
#include "XUD_USB_Defines.h"
#include "XUD_TimingDefines.h"
#include "XUD_Support.h"
#include "xud.h"

#include "XUD_HAL.h"

#ifdef __XS2A__
#include "xs1_to_glx.h"
#include "xs2_su_registers.h"
#endif

#ifdef __XS2A__
#include "XUD_USBTile_Support.h"
extern unsigned get_tile_id(tileref ref);
extern tileref USB_TILE_REF;
#endif

extern in  port flag0_port;
extern in  port flag1_port;
extern in  port flag2_port;
extern out buffered port:32 p_usb_txd;

#define TUCHEND_DELAY_us   1500 // 1.5ms
#define TUCHEND_DELAY      (TUCHEND_DELAY_us * REF_CLK_FREQ)
#define INVALID_DELAY_us   2500 // 2.5ms
#define INVALID_DELAY      (INVALID_DELAY_us * REF_CLK_FREQ)

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
   int chirpCount;

   chirpCount = 0;

   clearbuf(p_usb_txd);
   
   // On detecting the SE0:
   // De-assert XCVRSelect and set opmode=2
   // DEBUG - write to ulpi reg 0x54. This is:
   // opmode = 0b10, termsel = 1, xcvrsel = 0b00;
#if defined(__XS3A__)
   XUD_HAL_EnterMode_PeripheralChirp();
#elif defined(__XS2A__)
   write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0b1010);
#endif

   //t :> start_time;
   //t when timerafter(start_time+50):> void;

   /* Added a bit of a delay before chirp to match an example HS device */
   //t :> start_time;
   //t when timerafter(start_time+10000):> void;

   // output k-chirp for required time
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
#if defined(__XS3A__)
            
            XUD_HAL_EnterMode_PeripheralFullSpeed();
#elif defined(__XS2A__)
           write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM,
                             XS1_SU_PER_UIFM_FUNC_CONTROL_NUM,
                             (1<<XS1_SU_UIFM_FUNC_CONTROL_XCVRSELECT_SHIFT)
                              | (1<<XS1_SU_UIFM_FUNC_CONTROL_TERMSELECT_SHIFT));
#else
           XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x7);
#endif

           //wait for SE0 end
           while(1)
            {
               /* TODO Use a timer to save some juice...*/
#ifdef __XS3A__
                while(1)
                {
                    unsigned dp, dm;
                    flag0_port :> dm;
                    flag1_port :> dp;
                        
                    if(dp || dm)
                        return 0;
                }
#else
               flag2_port :> tmp;

               if(!tmp) 
               {
                   return 0;                /* SE0 gone, return 0 to indicate FULL SPEED */
               }
#endif

               if(pwrConfig == XUD_PWR_SELF) {
                   unsigned x;
#if defined(__XS2A__)
                   read_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM,
                                    XS1_SU_PER_UIFM_OTG_FLAGS_NUM, x);
                   if(!(x&(1<<XS1_SU_UIFM_OTG_FLAGS_SESSVLDB_SHIFT))) {
                       write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM,
                                         XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 4);
                       return -1;             // VBUS gone, handshake fails completely.
                   }
#endif
               }
           }
           break;

       case detecting_k => flag1_port when pinseq(1):> void @ tx:          // K Chirp
           flag1_port @ tx + T_FILT :> tmp;
           if (tmp) {
               detecting_k = 0;
           }
           break;

       case !detecting_k => flag0_port when pinseq(1) :> void @ tx:     // J Chirp
           flag0_port @ tx + T_FILT :> tmp;
           if (tmp == 0) {                                              // inverted!
               chirpCount ++;                                              // Seen an extra K-J pair
               detecting_k = 1;
               if (chirpCount == 3) {                                      // On 3 we have seen a HS

                   // Three pairs of KJ received... de-assert TermSelect...
                   // (and opmode = 0, suspendm = 1)
#ifdef __XS3A__
                    XUD_HAL_EnterMode_PeripheralHighSpeed();
#elif defined(__XS2A__)
                   write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM,
                                     XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0b0000);
#endif

#ifdef __XS3A__
#warning TODO for XS3
#else
                   //wait for SE0 (TODO consume other chirps?)
                   flag2_port when pinseq(1) :> tmp;
#endif 
                   
                   return 1;                                               // Return 1 for HS

               }
           }
           break;
       }
   }
}
#endif
