// Copyright 2011-2023 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include "xud.h"
#include "XUD_Support.h"
#include "XUD_USB_Defines.h"
#include "XUD_HAL.h"

#define T_WTRSTFS_us        26 // 26us
#ifndef T_WTRSTFS
#define T_WTRSTFS            (T_WTRSTFS_us * PLATFORM_REFERENCE_MHZ)
#endif
#define STATE_START_TO_us 3000 // 3ms
#define STATE_START_TO       (STATE_START_TO_us * PLATFORM_REFERENCE_MHZ)
#define DELAY_6ms_us      6000
#define DELAY_6ms            (DELAY_6ms_us * PLATFORM_REFERENCE_MHZ)
#define T_FILTSE0          250

#ifndef SUSPEND_VBUS_POLL_TIMER_TICKS
#define SUSPEND_VBUS_POLL_TIMER_TICKS (500000)
#endif

extern unsigned g_curSpeed;

int XUD_Init()
{
   /* Wait for host */
    while (1)
    {
        XUD_LineState_t currentLs = XUD_HAL_GetLineState();

        switch (currentLs)
        {
            /* SE0 State */
           case XUD_LINESTATE_SE0:

                unsigned timedOut = XUD_HAL_WaitForLineStateChange(currentLs, T_WTRSTFS);

                /* If no change in LS then return 1 for reset */
                if(timedOut)
                    return 1;

                /* Otherwise SE0 went away.. keep looking */
                break;

            /* J State */
            case XUD_LINESTATE_HS_K_FS_J:

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
    }

    __builtin_trap();
    return -1;
}

/** XUD_Suspend
  * @brief  Function called when device is suspended. This should include any clock down code etc.
  * @return non-zero if reset detected during resume */
int XUD_Suspend(XUD_PwrConfig pwrConfig)
{
    timer t;
    unsigned time;

    XUD_LineState_t currentLs = XUD_LINESTATE_HS_K_FS_J;

    while(1)
    {
        unsigned timeOutTime = 0;

        if(pwrConfig == XUD_PWR_SELF)
            timeOutTime = SUSPEND_VBUS_POLL_TIMER_TICKS;

        unsigned timedOut = XUD_HAL_WaitForLineStateChange(currentLs, timeOutTime);

        if(timedOut)
        {
            if(!XUD_HAL_GetVBusState())
            {
                /* VBUS not valid */
                XUD_HAL_EnterMode_TristateDrivers();
                return -1;
            }
            else
            {
                /* VBUS still valid, keep looking for LS change */
                continue;
            }
        }

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
            case XUD_LINESTATE_HS_J_FS_K:
#ifdef __XS2A__
                if (g_curSpeed == XUD_SPEED_HS)
                {
                    /* Special case for XS2A - start high-speed switch so it is completed as soon as possible after end of resume is seen */
                    XUD_HAL_EnterMode_PeripheralHighSpeed_Start();
                }
#endif
                while(1)
                {
                    XUD_HAL_WaitForLineStateChange(currentLs, 0);

                    switch(currentLs)
                    {
                        /* J, unexpected, return */
                        case XUD_LINESTATE_HS_K_FS_J:
#ifdef __XS2A__
                            /* For XS2 we have to complete the high-speed switch now, since we started it already..
                               we then revert to full speed straight away - causes a blip on the bus, non-ideal */
                            if (g_curSpeed == XUD_SPEED_HS)
                            {
                                unsafe
                                {
                                    XUD_HAL_EnterMode_PeripheralHighSpeed_Complete();
                                }
                            }

                            XUD_HAL_EnterMode_PeripheralFullSpeed();
#endif
                            return 0;

                         /* SE0, end of resume */
                        case XUD_LINESTATE_SE0:
                            if (g_curSpeed == XUD_SPEED_HS)
                            {
#ifdef __XS2A__
                                /* For XS2 we now have to complete the switch back to high-speed */
                                XUD_HAL_EnterMode_PeripheralHighSpeed_Complete();
#else
                                /* Move back into high-speed mode - Notes, writes to XS3A registers orders of magnitude faster than XS2A */
                                XUD_HAL_EnterMode_PeripheralHighSpeed();
#endif
                            }
                            /* Return 0 for resumed */
                            return 0;

                        default:
                            // Keep looping
                            break;
                    }
                }

            break;

            default:
                break;
        }
    }

    return 0; // unreachable
}

