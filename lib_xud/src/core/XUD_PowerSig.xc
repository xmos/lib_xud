// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved
/** @file       XUD_PowerSig.xc
  * @brief      Functions for USB power signaling
  * @author     Ross Owen, XMOS Limited
  **/

#ifndef XUD_SIM_XSIM

#include <xs1.h>

#include "xud.h"
#include "XUD_Support.h"
#include "XUD_USB_Defines.h"
#include "XUD_HAL.h"

#define T_WTRSTFS_us        26 // 26us
#ifndef T_WTRSTFS
#define T_WTRSTFS            (T_WTRSTFS_us * REF_CLK_FREQ)
#endif
#define STATE_START_TO_us 3000 // 3ms
#define STATE_START_TO       (STATE_START_TO_us * REF_CLK_FREQ)
#define DELAY_6ms_us      6000
#define DELAY_6ms            (DELAY_6ms_us * REF_CLK_FREQ)
#define T_FILTSE0          250

#ifndef SUSPEND_VBUS_POLL_TIMER_TICKS
#define SUSPEND_VBUS_POLL_TIMER_TICKS 500000
#endif

extern buffered in  port:32 p_usb_clk;
extern in  port reg_read_port;
extern in  port flag0_port;
extern in  port flag1_port;

extern in  port flag2_port;

extern out port p_usb_txd;
extern in buffered port:32 p_usb_rxd;

extern unsigned g_curSpeed;

int XUD_Init()
{
   timer SE0_timer;
   unsigned SE0_start_time = 0;

   /* Wait for host */
    while (1)
    {

#ifdef __XS3A__ 
    
        XUD_LineState_t currentLs = XUD_HAL_GetLineState();
        
        switch (currentLs)
        {

           case XUD_LINESTATE_SE0:

                unsigned timedOut = XUD_HAL_WaitForLineStateChange(currentLs, T_WTRSTFS);
    
                /* If no change in LS then return 1 for reset */
                if(timedOut) 
                    return 1; 

                /* Otherwise SE0 went away.. keep looking */
                break;

            case XUD_LINESTATE_J:
    
                 unsigned timedOut = XUD_HAL_WaitForLineStateChange(currentLs, STATE_START_TO);
    
                /* If no change in LS then return 0 for suspend */
                if(timedOut) 
                    return 0; 

                /* Otherwise J went away.. keep looking */
                break;

            default:
                /* Shouldn't expect to get here, but ignore anyway */
                break;
        }

#else
        select
        {
            /* SE0 State */
            case flag2_port when pinseq(1) :> void:
                SE0_timer :> SE0_start_time;
                select
                {
                    case flag2_port when pinseq(0) :> void:
                        break;

                    case SE0_timer when timerafter(SE0_start_time + T_WTRSTFS) :> int:
                        return 1;
                        break;
                 }
                break;

            /* J State */
            case flag0_port when pinseq(1) :> void:                 
                SE0_timer :> SE0_start_time;
                select
                {
                    case flag0_port when pinseq(0) :> void:         
                        break;

                    case SE0_timer when timerafter(SE0_start_time + STATE_START_TO) :> int:
                        return 0;
                        break;
                }
                break;
        }
#endif
    }

    __builtin_trap();
    return -1;
}


#ifndef __XS3A__
/** XUD_DoSuspend
  * @brief  Function called when device is suspended. This should include any clock down code etc.
  * @return True if reset detected during resume */
int XUD_Suspend(XUD_PwrConfig pwrConfig)
{
    unsigned tmp;
    timer t;
    unsigned time;

    unsigned rdata = 0;

    while (1)
    {
        t :> time;
    
        // linestate is K on flag0 (inverted), J on flag1, SE0 on flag2
        // note that if you look in device-attach function, high-speed chirps are opposite polarity
        // that is chirp K on flag1 and chirp J on flag0 (inverted)
        select
        {
            case (pwrConfig == XUD_PWR_SELF) => t when timerafter(time + SUSPEND_VBUS_POLL_TIMER_TICKS) :> void:
                read_periph_word(USB_TILE_REF,  XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_OTG_FLAGS_NUM, tmp);
                if (!(tmp & (1 << XS1_SU_UIFM_OTG_FLAGS_SESSVLDB_SHIFT)))
                {
                    // VBUS not valid
                    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM,  XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 4 /* OpMode 01 */);
                    return -1;
                }
                break;
    
            // SE0, that looks like a reset
            case flag2_port when pinseq(1) :> void:
                t :> time;
                select
                {
                    case flag2_port when pinseq(0) :> void:
                        // SE0 gone away, keep looping
                        break;
    
                    case t when timerafter(time + T_FILTSE0) :> void:
                        // consider 2.5ms a complete reset
                        t :> time;
                        t when timerafter(time + 250000) :> void;
                        return 1;
                }
                break;
    
            // K, start of resume
            case flag0_port when pinseq(1) :> void: 
                // TODO debounce?
                unsafe chanend c;
                asm("getr %0, 2" : "=r"(c)); // XS1_RES_TYPE_CHANEND=2 (no inline assembly immediate operands in xC)
    
                if (g_curSpeed == XUD_SPEED_HS)
                {
                    // start high-speed switch so it's completed as quickly as possible after end of resume is seen
                    unsafe {
                        write_periph_word_two_part_start((chanend)c, USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM,  XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0);
                    }
                }
    
                select
                {
                    // J, unexpected, return
                    case flag1_port when pinseq(1) :> void:
                        // we have to complete the high-speed switch now
                        // revert to full speed straight away - causes a blip on the bus
                        // Note, switching to HS then back to FS is not ideal
                        if (g_curSpeed == XUD_SPEED_HS)
                        {
                            unsafe {
                                write_periph_word_two_part_end((chanend)c, 0);
                            }
                        }
                        write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, (1 << XS1_SU_UIFM_FUNC_CONTROL_XCVRSELECT_SHIFT) | (1 << XS1_SU_UIFM_FUNC_CONTROL_TERMSELECT_SHIFT));
                        break;
    
                    // SE0, end of resume
                    case flag2_port when pinseq(1) :> void:
                        if (g_curSpeed == XUD_SPEED_HS)
                        {
                            // complete the high-speed switch
                            unsafe {
                                write_periph_word_two_part_end((chanend)c, 0);
                            }
                        }
                        break;
                }
    
                asm("freer res[%0]" :: "r"(c));
                return 0;
        }
    }
    __builtin_trap();
    return -1;
}

#else
int XUD_Suspend(XUD_PwrConfig pwrConfig)
{
    timer t;
    unsigned time;

    unsigned reset = 0;

    XUD_LineState_t currentLs = XUD_LINESTATE_J;
    
    while(1)
    {
        unsigned timedOut = XUD_HAL_WaitForLineStateChange(currentLs, 0);

        switch(currentLs)
        {
            /* Reset signalliung */
            case XUD_LINESTATE_SE0:

                timedOut = XUD_HAL_WaitForLineStateChange(currentLs, T_FILTSE0);

                if(timedOut)
                {
                    /* Consider 2.5ms a complete reset */
                    t :> time;
                    t when timerafter(time + 250000) :> void;

                    /* Return 1 for reset */
                    return 1;

                }

                /* If didnt timeout then keep looping...*/
                break;

            /* K, start of resume */
            case XUD_LINESTATE_K:

                /* TODO debounce? */
                XUD_HAL_WaitForLineStateChange(currentLs, 0);

                switch(currentLs)
                {
                    /* SE0, end of resume */
                    case XUD_LINESTATE_SE0:
                        if (g_curSpeed == XUD_SPEED_HS)
                        {
                            /* Move back into high-speed mode - Notes, writes to XS3A registers orders of magnitude faster than XS2A */
                            XUD_HAL_EnterMode_PeripheralHighSpeed();

                            /* Return 0 for resumed */
                            return 0;
                        }
                        break;

                    /* J, unexpected, return to suspend.. */
                    case XUD_LINESTATE_J:
                    default: 
                        break;
                }
                break;
                
            case XUD_LINESTATE_J:
            default:
                /* Do nothing */
                break;
        }
    }
}
#endif
#endif
