// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <print.h>

#include "xud.h"
#include "XUD_Support.h"


/* Location to store stack pointer (required for interupt handler) */
unsigned SavedSp;


#if 0

int XUD_LLD_IoLoop(
#ifdef GLX
                in buffered port:32 rxd_port,
#else
                in port rxd_port,
#endif
                in port rxa_port,
#ifdef GLX
                out buffered port:32 txd_port,
#else
                out port txd_port,
#endif
                in port rxe_port, in port flag0_port,
                in port, out port, int x,
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], XUD_chan epChans[], int  epCount, chanend ?sof, chanend ?c_usb_testmode) ;










int XUD_LLD_Io(
#ifdef GLX
                in buffered port:32 rxd_port,
#else
                in port rxd_port,
#endif
                in port rxa_port,
#ifdef GLX
                out buffered port:32 txd_port,
#else
                out port txd_port,
#endif
                in port rxe_port, in port flag0_port,
                int x, int y, int z,
               XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], XUD_chan epChans[], int epCount, in port ?reg_read_port, out port ?reg_write_port, chanend ?sof, chanend ?c_usb_testmode)
{

    /* Call main IO assembly loop */
	return  XUD_LLD_IoLoop(rxd_port, rxa_port,txd_port, rxe_port,  flag0_port, reg_read_port, reg_write_port,0, epTypeTableOut, epTypeTableIn, epChans, epCount, sof, c_usb_testmode) ;

}

#endif
