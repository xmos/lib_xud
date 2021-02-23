// Copyright (c) 2011-2020, XMOS Ltd, All rights reserved

/**
  * @file      XUD_Main.xc
  * @brief     XMOS USB Device (XUD) Layer
  * @author    Ross Owen
  **/
/* Error printing functions */
#ifdef XUD_DEBUG_VERSION
void XUD_Error(char errString[]);
void XUD_Error_hex(char errString[], int i_err);
#else
#define XUD_Error(a) /* */
#define XUD_Error_hex(a, b) /* */
#endif

#include <xs1.h>
#include <print.h>
#include <xclib.h>
#include <platform.h>

#include "xud.h"                 /* External user include file */
#include "XUD_USB_Defines.h"
#include "XUD_Support.h"

#include "XUD_DeviceAttach.h"
#include "XUD_PowerSig.h"
#include "XUD_HAL.h"

#if (USB_MAX_NUM_EP_IN != 16)
#error USB_MAX_NUM_EP_IN must be 16!
#endif
#if (USB_MAX_NUM_EP_OUT != 16)
#error USB_MAX_NUM_EP_OUT must be 16!
#endif

void XUD_UserSuspend();
void XUD_UserResume();
void XUD_PhyReset_User();

#include "xta_pragmas.h"

#define HS_TX_HANDSHAKE_TIMEOUT (167)
#define FS_TX_HANDSHAKE_TIMEOUT (5000)

/* Global vars for current and desired USB speed */
unsigned g_curSpeed;
unsigned g_desSpeed;
unsigned g_txHandshakeTimeout;

in port flag0_port = PORT_USB_FLAG0; /* For XS3: Mission: RXE, XS2 is configurable and set to RXE in mission mode */
in port flag1_port = PORT_USB_FLAG1; /* For XS3: Mission: RXA, XS2 is configuratble and set to RXA in mission mode*/

/* XS2A has an additonal flag port. In Mission mode this is set to VALID_TOKEN */
#ifdef __XS2A__
in port flag2_port = PORT_USB_FLAG2;
#else
#define flag2_port null
#endif

in buffered port:32 p_usb_clk  = PORT_USB_CLK;
out buffered port:32 p_usb_txd = PORT_USB_TXD;
in  buffered port:32 p_usb_rxd = PORT_USB_RXD;
out port tx_readyout           = PORT_USB_TX_READYOUT;
in port tx_readyin             = PORT_USB_TX_READYIN;
in port rx_rdy                 = PORT_USB_RX_READY;

on USB_TILE: clock tx_usb_clk  = XS1_CLKBLK_2;
on USB_TILE: clock rx_usb_clk  = XS1_CLKBLK_3;

XUD_chan epChans[USB_MAX_NUM_EP];
XUD_chan epChans0[USB_MAX_NUM_EP];

/* TODO pack this to save mem
 * TODO size of this hardcoded in ResetRpStateByAddr_
 */
typedef struct XUD_ep_info
{
    unsigned int chan_array_ptr;       // 0
    unsigned int ep_xud_chanend;       // 1
    unsigned int ep_client_chanend;    // 2
    unsigned int scratch;              // 3 used for datalength in
    unsigned int pid;                  // 4 Expected out PID
    unsigned int epType;               // 5 Data
    unsigned int actualPid;            // 6 Actual OUT PID received for OUT, Length (words) for IN.
    unsigned int tailLength;           // 7 "tail" length for IN (bytes)
    unsigned int epAddress;            // 8 EP address assigned by XUD (Used for marking stall etc)
    unsigned int resetting;            // 9 Flag to indicate to EP a bus-reset occured.
} XUD_ep_info;

XUD_ep_info ep_info[USB_MAX_NUM_EP];

/* Tables storing if EP's are signed up to bus state updates */
int epStatFlagTableIn[USB_MAX_NUM_EP_IN];
int epStatFlagTableOut[USB_MAX_NUM_EP_OUT];

extern unsigned XUD_LLD_IoLoop(
                            in buffered port:32 rxd_port,
                            in port rxa_port,
                            out buffered port:32 txd_port,
                            in port rxe_port, in port ?valtok_port,
                            XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], XUD_chan epChans[],
                            int  epCount, chanend? c_sof) ;

unsigned handshakeTable_IN[USB_MAX_NUM_EP_IN];
unsigned handshakeTable_OUT[USB_MAX_NUM_EP_OUT];
unsigned sentReset=0;

unsigned crcmask = 0b11111111111;
unsigned chanArray;

#define RESET_TIME_us               5 // 5us
#define RESET_TIME                  (RESET_TIME_us * REF_CLK_FREQ)

#if (XUD_OPT_SOFTCRC5 == 1)
extern unsigned char crc5Table[2048];
extern unsigned char crc5Table_Addr[2048];

void XUD_SetCrcTableAddr(unsigned addr);
#endif

static int one = 1;

#pragma unsafe arrays
static void SendResetToEps(XUD_chan c[], XUD_chan epChans[], XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], int nOut, int nIn, int token)
{
    for(int i = 0; i < nOut; i++)
    {
        if(epTypeTableOut[i] != XUD_EPTYPE_DIS && epStatFlagTableOut[i])
        {
            /* Set EP resetting flag. EP uses this to check if it missed a reset before setting ready */
            ep_info[i].resetting = 1;

            /* Clear EP ready. Note. small race since EP might set ready after XUD sets resetting to 1
             * but this should be caught in time (EP gets CT) */
            epChans[i] = 0;
            XUD_Sup_outct(c[i], token);
        }
    }
    for(int i = 0; i < nIn; i++)
    {
        if(epTypeTableIn[i] != XUD_EPTYPE_DIS && epStatFlagTableIn[i])
        {
            ep_info[i + USB_MAX_NUM_EP_OUT].resetting = 1;
            epChans[i + USB_MAX_NUM_EP_OUT] = 0;
            XUD_Sup_outct(c[i + USB_MAX_NUM_EP_OUT], token);
        }
    }
}

static void SendSpeed(XUD_chan c[], XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], int nOut, int nIn, int speed)
{
    for(int i = 0; i < nOut; i++)
    {
        if(epTypeTableOut[i] != XUD_EPTYPE_DIS && epStatFlagTableOut[i])
        {
            XUD_Sup_outuint(c[i], speed);
        }
    }
    for(int i = 0; i < nIn; i++)
    {
        if(epTypeTableIn[i] != XUD_EPTYPE_DIS && epStatFlagTableIn[i])
        {
            XUD_Sup_outuint(c[i + USB_MAX_NUM_EP_OUT], speed);
        }
    }

}

// Main XUD loop
static int XUD_Manager_loop(XUD_chan epChans0[], XUD_chan epChans[],  chanend ?c_sof, XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], int noEpOut, int noEpIn, XUD_PwrConfig pwrConfig)
{
    int reset = 1;            /* Flag for if device is returning from a reset */
    
    /* Make sure ports are on and reset port states */
    set_port_use_on(p_usb_clk);
    set_port_use_on(p_usb_txd);
    set_port_use_on(p_usb_rxd);
    set_port_use_on(flag0_port);
    set_port_use_on(flag1_port);
#if defined(__XS2A__)
    set_port_use_on(flag2_port);
#endif

#if defined(__XS3A__)
    #ifndef XUD_CORE_CLOCK
        #error XUD_CORE_CLOCK not defined (in MHz)
    #endif
    #if (XUD_CORE_CLOCK > 500)
        #define RX_RISE_DELAY 2
        #define RX_FALL_DELAY 5
        #define TX_RISE_DELAY 2
        #define TX_FALL_DELAY 3
    #elif (XUD_CORE_CLOCK > 400)
        #define RX_RISE_DELAY 5
        #define RX_FALL_DELAY 5
        #define TX_RISE_DELAY 2
        #define TX_FALL_DELAY 3
    #else /* 400 */
        #define RX_RISE_DELAY 3
        #define RX_FALL_DELAY 5
        #define TX_RISE_DELAY 3  
        #define TX_FALL_DELAY 3
    #endif
#else
    #define RX_RISE_DELAY 5
    #define RX_FALL_DELAY 5
    #define TX_RISE_DELAY 5
    #define TX_FALL_DELAY 1
#endif

    // Set up USB ports. Done in ASM as read port used in both directions initially.
    // Main difference from xevious is IFM not enabled.
    // GLX_UIFM_PortConfig (p_usb_clk, txd, rxd, flag0_port, flag1_port, flag2_port);
    // Xevious needed asm as non-standard usage (to avoid clogging 1-bit ports)
    // GLX uses 1bit ports so shouldn't be needed.
    // Handshaken ports need USB clock
    configure_clock_src(tx_usb_clk, p_usb_clk);
    configure_clock_src(rx_usb_clk, p_usb_clk);

    //this along with the following delays forces the clock
    //to the ports to be effectively controlled by the
    //previous usb clock edges
    set_port_inv(p_usb_clk);
    set_port_sample_delay(p_usb_clk);

#if defined(XUD_SIM_XSIM)
    set_clock_fall_delay(tx_usb_clk, TX_FALL_DELAY+5);
#else
    //This delay controls the capture of rdy
    set_clock_rise_delay(tx_usb_clk, TX_RISE_DELAY);

    //this delay controls the launch of data.
    set_clock_fall_delay(tx_usb_clk, TX_FALL_DELAY);

    //this delay th capture of the rdyIn and data.
    set_clock_rise_delay(rx_usb_clk, RX_RISE_DELAY);
    set_clock_fall_delay(rx_usb_clk, RX_FALL_DELAY);
#endif

#ifdef __XS3A__
    set_pad_delay(flag1_port, 3);
#else
	set_pad_delay(flag1_port, 2);
#endif
        
    start_clock(tx_usb_clk);
  	start_clock(rx_usb_clk);

 	configure_out_port_handshake(p_usb_txd, tx_readyin, tx_readyout, tx_usb_clk, 0);
  	configure_in_port_strobed_slave(p_usb_rxd, rx_rdy, rx_usb_clk);

    /* Clock RxA port from USB clock - helps fall event */
    configure_in_port(flag1_port, rx_usb_clk);

    unsigned noExit = 1;

    while(noExit)
    {
        unsigned settings[] = {0};
    
        /* Enable USB funcitonality in the device */
        XUD_HAL_EnableUsb(pwrConfig);
        
        while(1)
        {
            {
                /* Wait for VBUS before enabling pull-up. The USB Spec (page 150) allows 100ms
                 * between vbus valid and signalling attach */
                if(pwrConfig == XUD_PWR_SELF)
                {
                    while(1)
                    {
                        unsigned x, time;
                        timer t;
#if defined(__XS2A__)
                        read_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_OTG_FLAGS_NUM, x);
                        if(x&(1<<XS1_UIFM_OTG_FLAGS_SESSVLDB_SHIFT))
#else
                        #warning XS3 wait for VBUS not implemented
#endif
                        {
                            break;
                        }
                        t :> time;
                        time += (200 * REF_CLK_FREQ); // 200us poll
                        t when timerafter(time):> void;
                    }
                }
                
                /* Go into full speed mode: XcvrSelect and Term Select (and suspend) high */
                XUD_HAL_EnterMode_PeripheralFullSpeed();

#if defined(XUD_SIM_XSIM) || defined(XUD_BYPASS_CONNECT) 
                reset = 1;
#else

                /* Setup flags for power signalling - i.e. J/K/SE0 line state*/
                XUD_HAL_Mode_PowerSig();
                
                if (one)
                {
                    reset = XUD_Init();
                    one = 0;
                }
                else
                {
                    timer t; unsigned time;
                    t :> time;
                    t when timerafter(time + 20000) :> int _;// T_WTRSTHS: 100-875us

                    /* Sample line state and check for reset (or suspend) */
                    XUD_LineState_t ls = XUD_HAL_GetLineState();
                    if(ls == XUD_LINESTATE_SE0)
                        reset == 1;
                    else
                        reset = 0;
                }
                /* Inspect for suspend or reset */
                if(!reset)
                {
                    /* Run user suspend code */
                    XUD_UserSuspend();

                    /* Run suspend code, returns 1 if reset from suspend, 0 for resume, -1 for invalid vbus */
                    reset = XUD_Suspend(pwrConfig);

                    if((pwrConfig == XUD_PWR_SELF) && (reset==-1))
                    {
                        /* Lost VBUS */
                        continue;
                    }

                    /* Run user resume code */
                    XUD_UserResume();
                }
#endif
                /* Test if coming back from reset or suspend */
                if(reset == 1)
                {

                    if(!sentReset)
                    {
                        SendResetToEps(epChans0, epChans, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, USB_RESET_TOKEN);
                        sentReset = 1;
                    }
                    
                    /* Reset the OUT ep structures */
                    for(int i = 0; i< noEpOut; i++)
                    {
#ifdef __XS3A__
                        ep_info[i].pid = USB_PIDn_DATA0;
#else
                        ep_info[i].pid = USB_PID_DATA0;
#endif
                    }

                    /* Reset in the ep structures */
                    for(int i = 0; i< noEpIn; i++)
                    {
                        ep_info[USB_MAX_NUM_EP_OUT+i].pid = USB_PIDn_DATA0;
                    }

                    /* Set default device address - note, for normal operation this is 0, but can be other values for testing */
                    XUD_HAL_SetDeviceAddress(XUD_STARTUP_ADDRESS);

#ifdef XUD_BYPASS_RESET
    #if defined(XUD_TEST_SPEED_HS)
                        g_curSpeed = XUD_SPEED_HS;
                        g_txHandshakeTimeout = HS_TX_HANDSHAKE_TIMEOUT;
    #elif defined(XUD_TEST_SPEED_FS)
                        g_curSpeed = XUD_SPEED_FS;
                        g_txHandshakeTimeout = FS_TX_HANDSHAKE_TIMEOUT;
    #else 
                        #error XUD_TEST_SPEED_ must be defined if using XUD_BYPASS_RESET!
    #endif
#else
                    if(g_desSpeed == XUD_SPEED_HS)
                    {
                        unsigned tmp = 0;
                        tmp = XUD_DeviceAttachHS(pwrConfig);

                        if(tmp == -1)
                        {
                            XUD_UserSuspend();
                            continue;
                        }
                        else if (!tmp)
                        {
                            /* HS handshake fail, mark as running in FS */
                            g_curSpeed = XUD_SPEED_FS;
                            g_txHandshakeTimeout = FS_TX_HANDSHAKE_TIMEOUT;
                        }
                        else
                        {
                            g_curSpeed = XUD_SPEED_HS;
                            g_txHandshakeTimeout = HS_TX_HANDSHAKE_TIMEOUT;
                        }
                    }
                    else
                    {
                        g_curSpeed = XUD_SPEED_FS;
                        g_txHandshakeTimeout = FS_TX_HANDSHAKE_TIMEOUT;
                    }
#endif

                    /* Send speed to EPs */
                    SendSpeed(epChans0, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, g_curSpeed);
                    sentReset=0;
                }
            }

            XUD_HAL_Mode_DataTransfer();

            set_thread_fast_mode_on();
            
            /* Run main IO loop */
            /* flag0: Rx Error
               flag1: Rx Active
               flag2: Null / Valid Token  */
            noExit = XUD_LLD_IoLoop(p_usb_rxd, flag1_port, p_usb_txd, flag0_port, flag2_port, epTypeTableOut, epTypeTableIn, epChans, noEpOut, c_sof);
            
            set_thread_fast_mode_off();
  	   
            if(!noExit)
                break;
        }
    }

    /* TODO stop clock blocks */

    /* Turn ports off */
    set_port_use_off(p_usb_txd);
    set_port_use_off(p_usb_rxd);
    set_port_use_off(flag0_port);
    set_port_use_off(flag1_port);
#ifdef __XS2A__
    set_port_use_off(flag2_port);
#endif
    set_port_use_off(p_usb_clk);
    return 0;
}

void _userTrapHandleRegister(void);

#pragma unsafe arrays
static void drain(chanend chans[], int n, int op, XUD_EpType epTypeTable[]) {
    for(int i = 0; i < n; i++) {
        if(epTypeTable[i] != XUD_EPTYPE_DIS) {
            switch(op) {
            case 0:
                outct(chans[i], XS1_CT_END);
                outuint(chans[i], XUD_SPEED_KILL);
                break;
            case 1:
                outct(chans[i], XS1_CT_END);
                while (!testct(chans[i]))
                    inuchar(chans[i]);
                chkct(chans[i], XS1_CT_END);
                break;
            }
        }
    }
}


#pragma unsafe arrays
int XUD_Main(chanend c_ep_out[], int noEpOut,
                chanend c_ep_in[], int noEpIn,
                chanend ?c_sof,
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[],
                XUD_BusSpeed_t speed, XUD_PwrConfig pwrConfig)
{
    /* Arrays for channels... */
    /* TODO use two arrays? */

    g_desSpeed = speed;

    for (int i=0; i < USB_MAX_NUM_EP;i++)
    {
        epChans[i] = 0;
    }

    for(int i = 0; i < USB_MAX_NUM_EP_OUT; i++)
    {
        handshakeTable_OUT[i] = USB_PIDn_NAK;
        ep_info[i].epAddress = i;
        ep_info[i].resetting = 0;
    }

    for(int i = 0; i < USB_MAX_NUM_EP_IN; i++)
    {
        handshakeTable_IN[i] = USB_PIDn_NAK;
        ep_info[USB_MAX_NUM_EP_OUT+i].epAddress = (i | 0x80);
        ep_info[USB_MAX_NUM_EP_OUT+i].resetting = 0;
    }

    /* Populate arrays of channels and status flag tabes */
    for(int i = 0; i < noEpOut; i++)
    {
      if(epTypeTableOut[i] != XUD_EPTYPE_DIS)
      {
        unsigned x;
        epChans0[i] = XUD_Sup_GetResourceId(c_ep_out[i]);

        asm("ldaw %0, %1[%2]":"=r"(x):"r"(epChans),"r"(i));
        ep_info[i].chan_array_ptr = x;

        asm("mov %0, %1":"=r"(x):"r"(c_ep_out[i]));
        ep_info[i].ep_xud_chanend = x;

        asm("getd %0, res[%1]":"=r"(x):"r"(c_ep_out[i]));
        ep_info[i].ep_client_chanend = x;

        asm("ldaw %0, %1[%2]":"=r"(x):"r"(ep_info),"r"(i*sizeof(XUD_ep_info)/sizeof(unsigned)));
        outuint(c_ep_out[i], x);

        epStatFlagTableOut[i] = epTypeTableOut[i] & XUD_STATUS_ENABLE;
        epTypeTableOut[i] = epTypeTableOut[i] & 0x7FFFFFFF;

        ep_info[i].epType = epTypeTableOut[i];

#ifdef __XS3A__
        ep_info[i].pid = USB_PIDn_DATA0;
#else
        ep_info[i].pid = USB_PID_DATA0;
#endif
      }
    }

    for(int i = 0; i< noEpIn; i++)
    {
      if(epTypeTableIn[i] != XUD_EPTYPE_DIS)
      {
        int x;
        epChans0[i+USB_MAX_NUM_EP_OUT] = XUD_Sup_GetResourceId(c_ep_in[i]);

        asm("ldaw %0, %1[%2]":"=r"(x):"r"(epChans),"r"(USB_MAX_NUM_EP_OUT+i));
        ep_info[USB_MAX_NUM_EP_OUT+i].chan_array_ptr = x;

        asm("mov %0, %1":"=r"(x):"r"(c_ep_in[i]));
        ep_info[USB_MAX_NUM_EP_OUT+i].ep_xud_chanend = x;

        asm("getd %0, res[%1]":"=r"(x):"r"(c_ep_in[i]));
        ep_info[USB_MAX_NUM_EP_OUT+i].ep_client_chanend = x;

        asm("ldaw %0, %1[%2]":"=r"(x):"r"(ep_info),"r"((USB_MAX_NUM_EP_OUT+i)*sizeof(XUD_ep_info)/sizeof(unsigned)));

        outuint(c_ep_in[i], x);

        ep_info[USB_MAX_NUM_EP_OUT+i].pid = USB_PIDn_DATA0;

        epStatFlagTableIn[i] = epTypeTableIn[i] & XUD_STATUS_ENABLE;
        epTypeTableIn[i] = epTypeTableIn[i] & 0x7FFFFFFF;

        ep_info[USB_MAX_NUM_EP_OUT+i].epType = epTypeTableIn[i];
      }
    }

    /* EpTypeTable Checks.  Note, currently this is not too crucial since we only really care if the EP is ISO or not */

    /* Check for control on IN/OUT 0 */
    if(epTypeTableOut[0] != XUD_EPTYPE_CTL || epTypeTableIn[0] != XUD_EPTYPE_CTL)
    {
        XUD_Error("XUD_Manager: Ep 0 must be control for IN and OUT");
    }

#if 0
    /* Check that if the required channel has a destination if the EP is marked as in use */
    for( int i = 0; i < noEpOut + noEpIn; i++ )
    {
        if( XUD_Sup_getd( epChans[i] )  == 0 && epTypeTableOut[i] != XUD_EPTYPE_DIS )
            XUD_Error_hex("XUD_Manager: OUT Ep marked as in use but chanend has no dest: ", i);
    }

    for( int i = 0; i < noEpOut + noEpIn; i++ )
    {
        if( XUD_Sup_getd( epChans[i + XUD_EP_COUNT ] )  == 0 && epTypeTableIn[i] != XUD_EPTYPE_DIS )
            XUD_Error_hex("XUD_Manager: IN Ep marked as in use but chanend has no dest: ", i);
    }
#endif

    /* Run the main XUD loop */
    XUD_Manager_loop(epChans0, epChans, c_sof, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, pwrConfig);

    // Need to close, drain, and check - three stages.
    for(int i = 0; i < 2; i++)
    {
        drain(c_ep_out, noEpOut, i, epTypeTableOut);  // On all inputs
        drain(c_ep_in, noEpIn, i, epTypeTableIn);     // On all output
    }

    return 0;
}


/* Various messages for error cases */
void ERR_BadToken()
{
#ifdef XUD_DEBUG_VERSION
  printstrln("BAD TOKEN RECEVED");
#endif
}

void ERR_BadCrc(unsigned a, unsigned b)
{
  while(1);
}

void ERR_SetupBuffFull()
{
#ifdef XUD_DEBUG_VERSION
  printstrln("SETUP BUFFER FULL");
#endif
}

void ERR_UnsupportedToken(unsigned x)
{
#ifdef XUD_DEBUG_VERSION
  printstr("UNSUPPORTED TOKEN: ");
  printhexln(x);
#endif
}

void ERR_BadTxHandshake(unsigned x)
{
#ifdef XUD_DEBUG_VERSION
  printstr("BAD TX HANDSHAKE: ");
  printhexln(x);
#endif
}

void ERR_GotSplit()
{
#ifdef XUD_DEBUG_VERSION
  printstrln("ERR: Got a split");
#endif
}

void ERR_TxHandshakeTimeout()
{
#ifdef XUD_DEBUG_VERSION
  printstrln("WARNING: TX HANDSHAKE TIMEOUT");
  while(1);
#endif
}

void ERR_OutDataTimeout()
{
#ifdef XUD_DEBUG_VERSION
  printstrln("ERR: Out data timeout");
#endif
}

void ERR_EndIn4()
{
#ifdef XUD_DEBUG_VERSION
  printstrln("ERR: Endin4");
  while(1);

#endif
}

void ERR_EndIn5(int x)
{
#ifdef XUD_DEBUG_VERSION
  printhex(x);
  printstrln(" ERR: Endin5");
  while(1);
#endif
}

void ResetDetected(int x)
{
#ifdef XUD_DEBUG_VERSION
    printint(x);
    printstr(" rrrreeeset\n");
#endif
}

void SuspendDetected()
{
#ifdef XUD_DEBUG_VERSION
    printstr("Suspend!\n");
#endif
}
