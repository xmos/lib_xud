#include <xs1.h>
#include <print.h>
#include <platform.h>
#include "XUD_UIFM_Functions.h"
#include "XUD_UIFM_Defines.h"
#include "XUD_USB_Defines.h"
#include "XUD_Support.h"
#include "xud.h"

#ifdef ARCH_S
#include <xs1_su.h>
#include "xa1_registers.h"
#include "glx.h"
extern unsigned get_tile_id(tileref ref);
extern tileref USB_TILE_REF;
#endif

extern in  port flag0_port;
extern in  port flag1_port;
extern in  port flag2_port;
#ifdef ARCH_S
extern out buffered port:32 p_usb_txd;
#define reg_write_port null
#define reg_read_port null
#else
extern out port reg_write_port;
extern in  port reg_read_port;
extern out port p_usb_txd;
#endif

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
#ifndef ARCH_S
   clearbuf(reg_write_port);
#endif
   // On detecting the SE0:
   // De-assert XCVRSelect and set opmode=2
   // DEBUG - write to ulpi reg 0x54. This is:
   // opmode = 0b10, termsel = 1, xcvrsel = 0b00;

#ifdef ARCH_S
   write_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG, 0b1010);
#else
   XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x15);
#endif
   XUD_Sup_Delay(50);

//#ifdef ARCH_S
   /* Added a bit of a delay before chirp to match an example HS device */
   t :> start_time;
   t when timerafter(start_time+10000):> void;
//#endif
   // output k-chirp for required time

   for (int i = 0; i < 16000; i++) {   // 16000 words @ 480 MBit = 1.066 ms
       p_usb_txd <: 0;
   }

   //XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x04);
   // J, K, SE0 on flag ports 0, 1, 2 respectively
   // Wait for fs chirp k (i.e. HS chirp j)
   flag1_port when pinseq(0) :> tmp; // Wait for out k to go

   t :> start_time;
   while(1) {
       select {
       case t when timerafter(start_time + INVALID_DELAY) :> void:
           /* Go into full speed mode: XcvrSelect and Term Select (and suspend) high */
#ifdef ARCH_S
           write_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID,
                                 XS1_UIFM_FUNC_CONTROL_REG,
                                 (1<<XS1_UIFM_FUNC_CONTROL_XCVRSELECT)
                                 | (1<<XS1_UIFM_FUNC_CONTROL_TERMSELECT));
#else
           XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x7);
#endif

           //wait for SE0 end
           while(1) {
               /* TODO Use a timer to save some juice...*/
               flag2_port :> tmp;

               if(!tmp) {
                   return 0;                /* SE0 gone, return 0 to indicate FULL SPEED */
               }

               if(pwrConfig == XUD_PWR_SELF) {
                   unsigned x;
#ifdef ARCH_S
                   read_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID,
                                        XS1_SU_PER_UIFM_OTG_FLAGS_NUM, x);
                   if(!(x&(1<<XS1_SU_UIFM_OTG_FLAGS_SESSVLDB_SHIFT))) {
                       write_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID,
                                             XS1_UIFM_FUNC_CONTROL_REG, 4);
                       return -1;             // VBUS gone, handshake fails completely.
                   }
#elif ARCH_L
                   x = XUD_UIFM_RegRead(reg_write_port, reg_read_port, UIFM_OTG_FLAGS_REG);
                   if(!(x&(1<<UIFM_OTG_FLAGS_SESSVLD_SHIFT))) {
                       XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x9);
                       return -1;             // VBUS gone, handshake fails completely.
                   }
#else
#warning cannot poll for vbus on ARCH_G
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
       case !detecting_k => flag0_port when pinseq(0) :> void @ tx:     // J Chirp, inverted!
           flag0_port @ tx + T_FILT :> tmp;
           if (tmp == 0) {                                              // inverted!
               chirpCount ++;                                              // Seen an extra K-J pair
               detecting_k = 1;
               if (chirpCount == 3) {                                      // On 3 we have seen a HS

                   // Three pairs of KJ received... de-assert TermSelect...
                   // (and opmode = 0, suspendm = 1)
#ifdef ARCH_S
                   write_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID,
                                         XS1_UIFM_FUNC_CONTROL_REG, 0b0000);
#else
                   XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x1);
#endif
                   //wait for SE0 (TODO consume other chirps?)
                   flag2_port when pinseq(1) :> tmp;
                   return 1;                                               // Return 1 for HS
               }
           }
           break;
       }
   }
}

