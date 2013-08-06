
#include <xs1.h>
#include <print.h>

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

/* States for state machine */
#define STATE_START 0
#define STATE_DETECTK 1
#define STATE_INC_K 2
#define STATE_DETECTJ 3
#define STATE_INC_J 4
#define STATE_VALID 5
#define STATE_INVALID 6
#define STATE_FILT_CHECK_K 7
#define STATE_FILT_CHECK_J 8

#define TUCHEND_DELAY_us   1500 // 1.5ms
#define TUCHEND_DELAY      (TUCHEND_DELAY_us * REF_CLK_FREQ)
#define INVALID_DELAY_us   2500 // 2.5ms
#define INVALID_DELAY      (INVALID_DELAY_us * REF_CLK_FREQ)

extern int resetCount;

/* Assumptions:
 * - In full speed mode
 * - No flags sticky */
int XUD_DeviceAttachHS(XUD_PwrConfig pwrConfig)
{
    unsigned tmp;
    timer t;
    unsigned time1, time2;
    int chirpCount = 0;
    unsigned state = STATE_START, nextState;
    int loop = 1;
    int complete = 1;
  

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

    // DEBUG: This sets IFM mode to DecodeLineState
    // Bit 5 of the CtRL reg (DONTUSE) has a serious effect on
    // driving the k-chirp, regardless of if we actually want to yet or not.
    //XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
        

    // Should out a K chirp - Signal HS device to host
    //XUD_Sup_Outpw8(p_usb_txd, 0);
    //p_usb_txd <: 0;

    // Wait for TUCHEND - TUCH
    //XUD_Sup_Delay(chirptime);

#ifdef ARCH_S
    /* Added a bit of a delay before chirp to match an example HS device */
    {
        unsigned time;
        t :> time; 
        t when timerafter(time+100000):> void;
    }


    // output k-chirp for required time
    for (int i = 0; i < 25000; i++)
        p_usb_txd <: 0x0;
    
#else
   for (int i = 0; i < 25000; i++)
        p_usb_txd <: 0;
#endif

   // XUD_Sup_Delay(30000);

    // Clear port buffers to remove k chirp
    clearbuf(p_usb_txd);

    //XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x04);
    // J, K, SE0 on flag ports 0, 1, 2 respectively
    // Wait for fs chirp k (i.e. HS chirp j)
    flag1_port when pinseq(0) :> tmp; // Wait for out k to go

#if 1
    while(loop)
    {
        switch(state)
        {
            case STATE_START:
                t :> time1;
                chirpCount = 0;
                nextState = STATE_DETECTK;
                    break;

            case STATE_DETECTK:
                t :> time2;

                if (time2 - time1 > INVALID_DELAY)
                {
                    nextState = STATE_INVALID;
                }
                
                flag1_port :> tmp;
                if (tmp)
                {
                    nextState = STATE_FILT_CHECK_K;
                }
                break;

            case STATE_FILT_CHECK_K:
                XUD_Sup_Delay(T_FILT);
                flag1_port :> tmp;
                if (tmp) 
                {
                    XUD_Sup_Delay(T_FILT);
                    nextState = STATE_INC_K;
                } 
                else 
                {
                    nextState = STATE_DETECTK;
                }
                break;

            case STATE_INC_K:
                flag2_port :> tmp;  // check for se0
                if(tmp) 
                {
#ifdef XUD_STATE_LOGGING
                    addDeviceState(STATE_K_INVALID);
#endif
                    nextState = STATE_INVALID;
                    //printint(2);
                } 
                else 
                {
#ifdef XUD_STATE_LOGGING
                    addDeviceState(STATE_K_VALID);
#endif
                    chirpCount++;
                    if (chirpCount == 6) 
                    {
                        nextState = STATE_VALID;
                    } 
                    else 
                    {
                        nextState = STATE_DETECTJ;
                    }
                }
                break;

            case STATE_DETECTJ:
                t :> time2;

                if (time2 - time1 > INVALID_DELAY)
                {
                    nextState = STATE_INVALID;
                    //printint(3);
                } 

                flag0_port :> tmp;
                if (tmp)
                    nextState = STATE_FILT_CHECK_J;
                break;

            case STATE_FILT_CHECK_J:
        
                XUD_Sup_Delay(T_FILT);
                flag0_port :> tmp;
                if (tmp) 
                {
                    XUD_Sup_Delay(T_FILT);
                    nextState = STATE_INC_J;
                } 
                else 
                {
                    nextState = STATE_DETECTJ;
                }
                break;

            case STATE_INC_J:
                flag2_port :> tmp;  // check for se0
                if(tmp) 
                {
#ifdef XUD_STATE_LOGGING
                    addDeviceState(STATE_J_INVALID);
#endif
                    nextState = STATE_INVALID;
                } 
                else 
                {
#ifdef XUD_STATE_LOGGING
                    addDeviceState(STATE_J_VALID);
#endif
                    chirpCount++;
                    if (chirpCount == 6) 
                    {
                        nextState = STATE_VALID;
                    } 
                    else 
                    {
                        nextState = STATE_DETECTK;
                    }
                }
                break;

            case STATE_INVALID:
                loop = 0;
                complete = 0;
                //return 0;
                //nextState = STATE_START;
                break;

            case STATE_VALID:
                loop = 0;
                break;
        }

    state = nextState;
  }

#endif


    if (complete)
    {

#ifdef ARCH_S
        write_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG, 0b0000); 
#else
        // Three pairs of KJ received... de-assert TermSelect... (and opmode = 0, suspendm = 1)
        XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x1);
#endif

        //wait for SE0 (TODO consume other chirps?)
        flag2_port when pinseq(1) :> tmp;

    }
    else
    {
#ifdef ARCH_S
        /* Go into full speed mode: XcvrSelect and Term Select (and suspend) high */
        write_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG,
                    (1<<XS1_UIFM_FUNC_CONTROL_XCVRSELECT) 
                    | (1<<XS1_UIFM_FUNC_CONTROL_TERMSELECT));
#endif
    }


    //wait for SE0 end 
    while(1)
    {
        unsigned x;

        /* TODO Use a timer to save some juice...*/
        flag2_port :> tmp;
        
        /* SE0 gone, break out of loop */
        if(!tmp)
            break;

#ifdef ARCH_S
        read_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID, XS1_SU_PER_UIFM_OTG_FLAGS_NUM, x);
        if(x&(1<<XS1_SU_UIFM_OTG_FLAGS_SESSVLDB_SHIFT))
#else
        x = XUD_UIFM_RegRead(reg_write_port, reg_read_port, UIFM_OTG_FLAGS_REG);
        if(x&(1<<UIFM_OTG_FLAGS_SESSVLD_SHIFT))
#endif
        {
            /* VBUS available */
        }
        else
        {
            /* VBUS GONE */
#ifdef ARCH_S
                write_glx_periph_word(get_tile_id(USB_TILE_REF), XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG, 4);
#else
                XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x81);
#endif
            return -1;
        }
    } 
    return complete;
}

