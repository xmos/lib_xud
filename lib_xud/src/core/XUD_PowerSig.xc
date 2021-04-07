// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** @file       XUD_PowerSig.xc
  * @brief      Functions for USB power signaling
  * @author     Ross Owen, XMOS Limited
  **/

#include <xs1.h>
#include <print.h>

#include "xud.h"
#include "XUD_Support.h"
#include "XUD_UIFM_Functions.h"
#include "XUD_USB_Defines.h"
#include "XUD_UIFM_Defines.h"

#ifdef ARCH_X200
#include "xs1_to_glx.h"
#include "xs2_su_registers.h"
#endif

#ifdef ARCH_S
#include "xs1_su_registers.h"
#endif

#if defined(ARCH_S) || defined(ARCH_X200)
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
#if defined(ARCH_S) || defined(ARCH_X200)
extern in buffered port:32 p_usb_rxd;
#define reg_read_port null
#define reg_write_port null
#else
extern out port reg_write_port;
extern port p_usb_rxd;
#endif
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
       case flag0_port when pinseq(0) :> void:             // Inverted!
           SE0_timer :> SE0_start_time;
           select
           {
           case flag0_port when pinseq(1) :> void:         // Inverted!
               break;

           case SE0_timer when timerafter(SE0_start_time + STATE_START_TO) :> int:
               return  0;
               break;
           }
           break;
       }
   }
   __builtin_trap();
   return -1;
}

/** XUD_DoSuspend
  * @brief  Function called when device is suspended. This should include any clock down code etc.
  * @return True if reset detected during resume */
int XUD_Suspend(XUD_PwrConfig pwrConfig)
{
    unsigned tmp;
    timer t;
    unsigned time;

    /* Suspend can be handled in multiple ways:
    - Poll flags registers for resume/reset
    - Suspend phy and poll line status in test status reg for resume/reset
    - Power down zevious and use the suspend controller to wake zevious up
    */
#if defined(ARCH_L) && defined(GLX_SUSPHY)
#ifdef GLX_PWRDWN
    unsigned devAddr;
    unsigned before;
    /* Power suspend phy, power down zevious and used suspend controller to wake up */

    /* NOTE CURRENTLY XEV DOES NOT GET TURNED OFF, WE JUST ARE USING SUSPEND CONTROLLER TO
     * VERIFY FUNCTIONALITY */

    /* Wait for suspend J to make its way through filter */
    read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG, before);

    while(1)
    {
        unsigned  x;
        read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_TESTSTATUS_REG, x);
        x >>= 9;
        x &= 0x3;
        if(x == 1)
        {
             break;
        }
    }

    /* Save device address to Glx scratch*/
    {
        char wData[] = {0};
        read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG, devAddr);
        wData[0] = (char) devAddr;

        write_periph_reg_8(USB_TILE_REF, XS1_GLX_PERIPH_SCTH_ID, 0x0, 1, wData);
    }

    /* Suspend Phy etc
     * SEOFILTBASE sets a bit in a counter for anti-glitch (i.e 2 looks for change in 0b10)
     * This is a simple counter with check from wrap in this bit, so worst case could be x2 off
     * Counter runs at 32kHz by (31.25uS period). So setting 2 is about 63-125uS
     */
    write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG,
                                    (1 << XS1_UIFM_PHY_CONTROL_AUTORESUME) |
                                    (0x2 << XS1_UIFM_PHY_CONTROL_SE0FILTVAL_BASE)
                                    | (1 << XS1_UIFM_PHY_CONTROL_FORCESUSPEND)
                                    );

    /* Mark scratch reg */
    {
        char x[] = {1};
        write_periph_reg_8(USB_TILE_REF, XS1_GLX_PERIPH_SCTH_ID, 0xff, 1, x);
    }

    /* Finally power down Xevious,  keep sysclk running, keep USB enabled. */
    write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_PWR_ID, XS1_GLX_PWR_MISC_CTRL_ADRS,
                    (1 << XS1_GLX_PWR_SLEEP_INIT_BASE)               /* Sleep */
                     | (1 << XS1_GLX_PWR_SLEEP_CLK_SEL_BASE)         /* Default clock */
                     | (0x3 << XS1_GLX_PWR_USB_PD_EN_BASE ) );       /* Enable usb power up/down */

     /* Normally XCore will now be off and will reboot on resume/reset
      * However, all supplies enabled to test suspend controller so we'll poll resume reason reg.. */

    while(1)
    {
        unsigned wakeReason = 0;

        read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG, wakeReason);

        if(wakeReason & (1<<XS1_UIFM_PHY_CONTROL_RESUMEK))
        {
            /* Unsuspend phy */
            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG,0);

            /* Wait for usb clock */
            p_usb_clk when pinseq(1) :> int _;
            p_usb_clk when pinseq(0) :> int _;
            p_usb_clk when pinseq(1) :> int _;
            p_usb_clk when pinseq(0) :> int _;

            /* Func control reg will be default of 0x4 here term: 0 xcvSel: 0, opmode: 0b01 (non-driving) */
            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG,
                (1<<XS1_UIFM_FUNC_CONTROL_XCVRSELECT) |
                (1<<XS1_UIFM_FUNC_CONTROL_TERMSELECT));

            /* Set IFM to decoding linestate.. IFM regs reset when phy suspended */
            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_IFM_CONTROL_REG,
                (1<<XS1_UIFM_IFM_CONTROL_DECODELINESTATE) |
                (1<< XS1_UIFM_IFM_CONTROL_SOFISTOKEN));

            XUD_UIFM_PwrSigFlags();

            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG, devAddr);

            /* Wait for end of resume */
            while(1)
            {
                /* Wait for se0 */
                flag2_port when pinseq(1) :> void;

                if(g_curSpeed == XUD_SPEED_HS)
                {
                    /* Back to high-speed */
                    write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG, 0);
                }
                return 0;
            }
        }
        else if(wakeReason & (1<<XS1_UIFM_PHY_CONTROL_RESUMESE0))
        {
            /* RESET! -  Unsuspend phy */
            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG, 0);

            /* Wait for usb clock */
            p_usb_clk when pinseq(1) :> int _;
            p_usb_clk when pinseq(0) :> int _;
            p_usb_clk when pinseq(1) :> int _;
            p_usb_clk when pinseq(0) :> int _;

            /* Set IFM to decoding linestate.. IFM regs reset when phy suspended */
            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_IFM_CONTROL_REG,
                (1<<XS1_UIFM_IFM_CONTROL_DECODELINESTATE) |
                (1<< XS1_UIFM_IFM_CONTROL_SOFISTOKEN));

            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG, 0);

            //XUD_UIFM_PwrSigFlags();

            {
                unsigned time;
                t :> time;
                t when timerafter(time+250000) :> void;
            }
            return 1;
        }

#else /* GLX_PWRDWN */
    unsigned rdata = 0;

    /* TODO Wait for suspend (j) to come through filter */
    while(1)
    {
        unsigned  x;
        read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_TESTSTATUS_REG, x);
        x >>= 9;
        x &= 0x3;
        if(x == 1)
        {
            break;
        }
    }

    while(1)
    {
        read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_TESTSTATUS_REG, rdata);
        rdata >>= 9;
        rdata &= 0x3;

        if(rdata == 2)
        {
            /* Resume */

            /* Un-suspend phy */
            write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG, 0);

            /* Wait for usb clock */
            set_thread_fast_mode_on();
            p_usb_clk when pinseq(1) :> int _;
            p_usb_clk when pinseq(0) :> int _;
            p_usb_clk when pinseq(1) :> int _;
            p_usb_clk when pinseq(0) :> int _;
            set_thread_fast_mode_off();
            if(g_curSpeed == XUD_SPEED_HS)
            {
                /* Back to high-speed */
                write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG, 0);
            }

            /* Wait for end of resume */
            while(1)
            {
                read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_TESTSTATUS_REG, rdata);
                rdata >>= 9;
                rdata &= 0x3;

                if(rdata == 0)
                {
                    /* SE0 */
                    return 0;
                }
                else if(rdata == 1)
                {
                    /* Glitch */
                    break;
                }
            }
        }
        else if(rdata == 0)
        {
#if 0
            /* Reset */
            while(1)
            {
                int count = 0;
                read_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_TESTSTATUS_REG, rdata);
                rdata >>= 9;
                rdata &= 0x3;

                if(rdata != 0)
                {
                    /* Se0 gone away...*/
                    break;
                }
                else
                {
                    count++;
                    if(count>0)
                    {
#endif
                        /* Un-suspend phy */
                        write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG, 0);
                        return 1;
#if 0
                    }
                }
#endif
            }
        }
    }
#endif


#elif defined ARCH_S || defined ARCH_X200 /* "Normal" polling suspend for L or S series */
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
            case flag0_port when pinseq(0) :> void: // inverted port
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
#endif
}


