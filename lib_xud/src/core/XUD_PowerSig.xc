// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved
/** @file       XUD_PowerSig.xc
  * @brief      Functions for USB power signaling
  * @author     Ross Owen, XMOS Limited
  **/

#ifndef XUD_SIM_XSIM

#include <xs1.h>
#include <print.h>

#include "xud.h"
#include "XUD_Support.h"
#include "XUD_UIFM_Functions.h"
#include "XUD_USB_Defines.h"
#include "XUD_HAL.h"


#ifdef __XS2A__
#include "xs1_to_glx.h"
#include "xs2_su_registers.h"
#include "XUD_USBTile_Support.h"
extern unsigned get_tile_id(tileref ref);
extern tileref USB_TILE_REF;
#endif


void XUD_UIFM_PwrSigFlags();

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

/* Reset USB transceiver for specified time */
void XUD_PhyReset(out port p_rst, int time, unsigned rstMask)
{
    unsigned x;

    x = peek(p_rst);
    x &= (~rstMask);
    p_rst <: x;

    XUD_Sup_Delay(time);

    x = peek(p_rst);
    x |= rstMask;
    p_rst <: x;
}

int XUD_Init()
{
   timer SE0_timer;
   unsigned SE0_start_time = 0;

#ifdef DO_TOKS
   /* Set default device address */
   XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_ADDRESS, 0x0);
#endif

   /* Wait for host */
    while (1)
    {

#ifdef __XS3A__ 
    
#warning XUD_Init() not properly implemented for XS3A
        XUD_LineState_t ls = XUD_HAL_GetLineState();
        
        if(ls == XUD_LINESTATE_SE0)
            return 1;
        else if(ls == XUD_LINESTATE_J)
            return 0;

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
#warning Suspend not implemented for XS3A
    while(1);
        // TODO
}

#endif
#endif
