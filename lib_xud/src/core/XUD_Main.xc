// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved

/** XUD_Manager.xc
  * @brief     XMOS USB Device(XUD) Layer
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
#include "XUD_UIFM_Defines.h"
#include "XUD_USB_Defines.h"
#include "XUD_USBTile_Support.h"
#include "XUD_Support.h"
#include "XUD_UIFM_Functions.h"

#include "XUD_DeviceAttach.h"
#include "XUD_PowerSig.h"

#ifdef __XS1B__
#include "xs1_su_registers.h"
#endif

#ifdef __XS2A__
#include "xs1_to_glx.h"
#include "xs2_su_registers.h"
#endif

#ifdef __XS3A__
#include "XUD_HAL.h"
#include "xs3a_registers.h"
#endif

#if defined(ARCH_X200) || defined(ARCH_S)
#include "XUD_USBTile_Support.h"
//#include <xs1_su.h>
extern unsigned get_tile_id(tileref ref);
extern tileref USB_TILE_REF;
#endif

#if (USB_MAX_NUM_EP_IN != 16)
#error USB_MAX_NUM_EP_IN must be 16!
#endif

#if (USB_MAX_NUM_EP_OUT != 16)
#error USB_MAX_NUM_EP_OUT must be 16!
#endif

void XUD_UserSuspend();
void XUD_UserResume();
void XUD_PhyReset_User();

#if 0
#pragma xta command "config threads stdcore[0] 6"
#pragma xta command "add exclusion Pid_Out"
#pragma xta command "add exclusion Pid_Setup"
#pragma xta command "add exclusion Pid_Sof"
#pragma xta command "add exclusion Pid_Reserved"
#pragma xta command "add exclusion Pid_Ack"
#pragma xta command "add exclusion Pid_Data0"
#pragma xta command "add exclusion Pid_Ping"
#pragma xta command "add exclusion Pid_Nyet"
#pragma xta command "add exclusion Pid_Data2"
#pragma xta command "add exclusion Pid_Data1"
#pragma xta command "add exclusion Pid_Data0"
#pragma xta command "add exclusion Pid_Datam"
#pragma xta command "add exclusion Pid_Split"
#pragma xta command "add exclusion Pid_Stall"
#pragma xta command "add exclusion Pid_Pre"
#pragma xta command "add exclusion InvalidToken"
#pragma xta command "add exclusion InReady"

#pragma xta command "analyse path XUD_TokenRx_Pid XUD_TokenRx_Ep"
#pragma xta command "set required - 33 ns"
#endif


/* Rx to TX 16 clks required with SMSC phy (14 in spec).  SIE Decision Time */
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxNak"
#pragma xta command "set required - 233 ns"
#pragma xta command "add exclusion InNotReady"
#pragma xta command "remove exclusion InReady"


#pragma xta command "add exclusion XUD_IN_TxPid_Tail1"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail2"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail3"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS1"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS2"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS3"
#endif
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_Tail0"
#pragma xta command "set required - 266 ns"
#endif

#if 0
#pragma xta command "remove exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail0"
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_TailS0"
#pragma xta command "set required - 266 ns"

#pragma xta command "remove exclusion XUD_IN_TxPid_Tail1"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS0"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_Tail1"
#pragma xta command "set required - 266 ns"
#endif

#pragma xta command "remove exclusion XUD_IN_TxPid_TailS1"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail1"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_TailS1"
#pragma xta command "set required - 266 ns"
#endif

//#pragma xta command "remove exclusion ShortPacket"
//pragma xta command "add exclusion NormalPacket"
//#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_Short"
//#pragma xta command "set required - 233 ns"

/* TX TO RX */
/* Tx IN NAK to Token Rx */
#pragma xta command "remove exclusion InNotReady"
#pragma xta command "add exclusion InReady"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Pid XUD_IN_TxNak"
#pragma xta command "set required - 100 ns"
#endif

/* Tx OUT NAK to Token RX */
#if 0
#pragma xta command "analyse path XUD_OUT_TxNak XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"
#endif

/* Tx OUT ACK to Token Tx */
#if 0
#pragma xta command "analyse path XUD_OUT_TxAck XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"
#endif

/* Tx IN Data (so crc) to Rx Ack (Non ISO IN) */
#pragma xta command "add exclusion InNotReady"
#pragma xta command "remove exclusion InReady"
#if 0
#pragma xta command "add exclusion InISO"
#pragma xta command "add exclusion TxHandshakeTimeOut"
#endif

#pragma xta command "remove exclusion XUD_IN_TxPid_Tail0"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS1"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_Tail0 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

#pragma xta command "add exclusion XUD_IN_TxPid_Tail0"
#pragma xta command "remove exclusion XUD_IN_TxPid_Tail1"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_Tail1 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

#pragma xta command "add exclusion XUD_IN_TxPid_Tail1"
#pragma xta command "remove exclusion XUD_IN_TxPid_TailS0"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_TailS0 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

#pragma xta command "add exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "remove exclusion XUD_IN_TxPid_TailS1"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_TailS1 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

/* Tx IN Data (so crc) to Rx Token PID (ISO In) */
#pragma xta command "remove exclusion InISO"
#pragma xta command "add exclusion InNonISO"

#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_Tail0 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_Tail1 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_Tail2 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_Tail3 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS0 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS1 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS2 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS3 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"
#endif

/* RX TO RX */
/* Rx SOF to Rx SOF - This is a non-interesting case since timing will be ~125uS */

//#pragma xta command "remove exclusion Pid_Sof"
//#pragma xta command "add exclusion Pid_Out"
//#pragma xta command "add exclusion Pid_In"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_TokenRx_Pid"
#pragma xta command "set required - 50 ns"
#endif

/* Rx OUT Data end to Rx Token (ISO Out Data) */
//#pragma xta command "add exclusion OutTail0"
//#pragma xta command "add exclusion OutTail1"
//#pragma xta command "add exclusion OutTail2"
//#pragma xta command "add exclusion OutTail3"
//#pragma xta command "add exclusion OutTail4"
//#pragma xta command "add exclusion OutTail5"
//#pragma xta command "add exclusion ReportBadCrc"
//#pragma xta command "add exclusion DoOutHandShakeOut"
#if 0
#pragma xta command "analyse path XUD_OUT_RxTail XUD_TokenRx_Pid"
#pragma xta command "set required - 50 ns"
#endif


#endif
/* TX INTRA PACKET TIMING */
#if 0
#pragma xta command "analyse path XUD_IN_TxPid_Tail0 TxLoop0_Out"
#pragma xta command "set required - 83 ns"
#endif

/* Timeout differences due to using 60MHz vs 100MHz */
#if !defined(ARCH_S) && !defined(ARCH_X200)
#define HS_TX_HANDSHAKE_TIMEOUT 100
#define FS_TX_HANDSHAKE_TIMEOUT 3000
#else
#define HS_TX_HANDSHAKE_TIMEOUT (167)
#define FS_TX_HANDSHAKE_TIMEOUT (5000)
#endif

/* Global vars for current and desired USB speed */
unsigned g_curSpeed;
unsigned g_desSpeed;
unsigned g_txHandshakeTimeout;
unsigned g_prevPid=0xbadf00d;
unsigned int data_pid=0xbadf00d;

/* USB Port declarations - for Zevious with Galaxion */
//extern out port tx_readyout; // aka txvalid
//extern in port tx_readyin;
//extern out buffered port:32 p_usb_txd;
//extern in buffered port:32 p_usb_rxd;
//extern in port rx_rdy;
//extern in port flag0_port;
//extern in port flag1_port;
//#if !defined(__XS3A__)
//extern in port flag2_port;
//#else
//#define flag2_port null
//#endif
//extern in buffered port:32 p_usb_clk;
//extern clock tx_usb_clk;
//extern clock rx_usb_clk;

in port flag0_port = PORT_USB_FLAG0; /* For XS3: Mission: RXA */
in port flag1_port = PORT_USB_FLAG1; /* For XS3: Mission: RXE */

#if !defined (__XS3A__)
in port flag2_port = PORT_USB_FLAG2;
#else
#define flag2_port null
#endif

#if defined(ARCH_S) || defined(ARCH_X200) || defined(__XS3A__)
in buffered port:32 p_usb_clk     = PORT_USB_CLK;
out buffered port:32 p_usb_txd = PORT_USB_TXD;
in  buffered port:32 p_usb_rxd = PORT_USB_RXD;
out port tx_readyout           = PORT_USB_TX_READYOUT;
in port tx_readyin             = PORT_USB_TX_READYIN;
in port rx_rdy                 = PORT_USB_RX_READY;

on USB_TILE: clock tx_usb_clk  = XS1_CLKBLK_2;
on USB_TILE: clock rx_usb_clk  = XS1_CLKBLK_3;

#elif defined(ARCH_L) || defined(ARCH_G)

in port p_usb_clk       = PORT_USB_CLK;
out port reg_write_port = PORT_USB_REG_WRITE;
in  port reg_read_port  = PORT_USB_REG_READ;
out port p_usb_txd      = PORT_USB_TXD;
port p_usb_rxd          = PORT_USB_RXD;
in port p_usb_stp       = PORT_USB_STP_SUS;
#else
#error XUD_SERIES_SUPPORT not equal to XUD_U_SERIES, XUD_G_SERIES or XUD_L_SERIES
#endif

// TODO RM ME
#define reg_read_port null
#define reg_write_port null

#ifdef XUD_ISO_OUT_COUNTER
int xud_counter = 0;
#endif

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

/* Sets the UIFM flags into a mode suitable for power signalling */
void XUD_UIFM_PwrSigFlags()
{
#if defined(__XS2A__)
    write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_MASK_NUM, ((1<<XS1_UIFM_IFM_FLAGS_SE0_SHIFT)<<16)
        | ((1<<XS1_UIFM_IFM_FLAGS_K_SHIFT)<<8) | (1 << XS1_UIFM_IFM_FLAGS_J_SHIFT));
#elif defined(__XS1B__)
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_MASK_NUM, ((1<<XS1_SU_UIFM_IFM_FLAGS_SE0_SHIFT)<<16)
        | ((1<<XS1_SU_UIFM_IFM_FLAGS_K_SHIFT)<<8) | (1 << XS1_SU_UIFM_IFM_FLAGS_J_SHIFT));
#elif defined(__XS3A__)
    // TODO
#endif
}

/* Tables storing if EP's are signed up to bus state updates */
int epStatFlagTableIn[USB_MAX_NUM_EP_IN];
int epStatFlagTableOut[USB_MAX_NUM_EP_OUT];

extern unsigned XUD_LLD_IoLoop(
                            in buffered port:32 rxd_port,
                            in port rxa_port,
                            out buffered port:32 txd_port,
                            in port ?rxe_port, in port newtok_port,
                            in port ?read, out port ?write, int x,
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
unsigned char crc5Table_Addr[2048];

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
static int XUD_Manager_loop(XUD_chan epChans0[], XUD_chan epChans[],  chanend ?c_sof, XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], int noEpOut, int noEpIn, out port ?p_rst, unsigned rstMask, clock ?clk, XUD_PwrConfig pwrConfig)
{
    int reset = 1;            /* Flag for if device is returning from a reset */
    /* Make sure ports are on and reset port states */
    set_port_use_on(p_usb_clk);
    set_port_use_on(p_usb_txd);
    set_port_use_on(p_usb_rxd);
    set_port_use_on(flag0_port);
    set_port_use_on(flag1_port);
#if !defined(__XS3A__)
    set_port_use_on(flag2_port);
#endif

#if (XUD_OPT_SOFTCRC5)
    XUD_SetCrcTableAddr(XUD_STARTUP_ADDRESS);
#endif

#define TX_RISE_DELAY 5
#if defined(ARCH_S)
    #define TX_FALL_DELAY 2
#else
    #define TX_FALL_DELAY 1
#endif

#define RX_RISE_DELAY 5
#define RX_FALL_DELAY 5

    // Set up USB ports. Done in ASM as read port used in both directions initially.
    // Main difference from xevious is IFM not enabled.
    // GLX_UIFM_PortConfig (p_usb_clk, txd, rxd, flag0_port, flag1_port, flag2_port);
    // Xevious needed asm as non-standard usage (to avoid clogging 1-bit ports)
    // GLX uses 1bit ports so shouldn't be needed.
    // Handshaken ports need USB clock
    configure_clock_src (tx_usb_clk, p_usb_clk);
    configure_clock_src (rx_usb_clk, p_usb_clk);

    //this along with the following delays forces the clock
    //to the ports to be effectively controlled by the
    //previous usb clock edges
    set_port_inv(p_usb_clk);
    set_port_sample_delay(p_usb_clk);

#ifdef SIMULATION
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
   
#ifndef __XS3A__
    /* Invert valid token port */
  	set_port_inv(flag0_port);
#endif

#ifndef SIMULATION
	set_pad_delay(flag1_port, 2);
#else
	set_pad_delay(flag1_port, 4);
#endif
    
    start_clock(tx_usb_clk);
  	start_clock(rx_usb_clk);

 	configure_out_port_handshake(p_usb_txd, tx_readyin, tx_readyout, tx_usb_clk, 0);
  	configure_in_port_strobed_slave(p_usb_rxd, rx_rdy, rx_usb_clk);

    unsigned noExit = 1;

    while(noExit)
    {
#if !defined(ARCH_S) && !defined(__XS2A__) && !defined(__XS3A__)
        p_usb_rxd <: 0;         // Note, this is important else phy clocks in invalid data before UIFM is enabled causing
        clearbuf(p_usb_rxd);    // connection issues
#endif


        unsigned settings[] = {0};

    #if defined(__XS2A__) || defined(__XS3A__)
        /* For xCORE-200 enable USB port muxing before enabling phy etc */
        XUD_EnableUsbPortMux(); //setps(XS1_PS_XCORE_CTRL0, UIFM_MODE);
    #endif

#ifndef SIMULATION
        /* Enable the USB clock */
        write_sswitch_reg(get_tile_id(USB_TILE_REF), XS1_SU_CFG_RST_MISC_NUM, ( 1 << XS1_SU_CFG_USB_CLK_EN_SHIFT));

    #ifdef ARCH_S
        /* Now reset the phy */
        write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_PHY_CONTROL_NUM,    1); //(1<<XS1_UIFM_PHY_CONTROL_FORCERESET));
    #else
        write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_PHY_CONTROL_NUM,  0); //(0<<XS1_UIFM_PHY_CONTROL_FORCERESET));
    #endif
        /* Keep usb clock active, enter active mode */
        write_sswitch_reg(get_tile_id(USB_TILE_REF), XS1_SU_CFG_RST_MISC_NUM, (1 << XS1_SU_CFG_USB_CLK_EN_SHIFT) | (1<<XS1_SU_CFG_USB_EN_SHIFT)  );

        /* Clear OTG control reg - incase we were running as host previously.. */
        write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_OTG_CONTROL_NUM, 0);


#ifdef __XS3A__
        XUD_EnableUsbPortMux();

        unsigned d = 0;

        read_sswitch_reg(0, XS1_SSWITCH_USB_PHY_CFG2_NUM, d);
        d = XS1_USB_PHY_CFG2_PONRST_SET(d, 1);
        d = XS1_USB_PHY_CFG2_UTMI_RESET_SET(d, 0);
        write_sswitch_reg(0, XS1_SSWITCH_USB_PHY_CFG2_NUM, d); 

        read_sswitch_reg(0, XS1_SSWITCH_USB_PHY_CFG0_NUM, d);
        d = XS1_USB_PHY_CFG0_PLL_EN_SET(d,1);
        d = XS1_USB_PHY_CFG0_XTLSEL_SET(d, 0b101);
        write_sswitch_reg(0, XS1_SSWITCH_USB_PHY_CFG0_NUM, d); 
#endif

#endif // SIMILATION

        /* Wait for USB clock (typically 1ms after reset) */
        p_usb_clk when pinseq(1) :> int _;
        p_usb_clk when pinseq(0) :> int _;
        p_usb_clk when pinseq(1) :> int _;
        p_usb_clk when pinseq(0) :> int _;

#if defined (__XS3A__) && !defined(SIMULATION)   
        // TODO MOVE ME 
        XUD_HAL_EnterMode_PeripheralFullSpeed();
#endif

#if (defined(ARCH_L) && !defined(ARCH_X200) && !defined(ARCH_S)) || defined(ARCH_G)
        /* For L/G series we wait for clock from phy, then enable UIFM logic */
        // 3 u series, else 2
    #if defined (ARCH_S)
        XUD_UIFM_Enable(3); //setps(XS1_PS_XCORE_CTRL0, UIFM_MODE);
    #else
        XUD_UIFM_Enable(2); //setps(XS1_PS_XCORE_CTRL0, UIFM_MODE);
    #endif
#endif

#if defined(ARCH_X200)
#define XS1_UIFM_USB_PHY_EXT_CTRL_REG 0x50
#define XS1_UIFM_USB_PHY_EXT_CTRL_VBUSVLDEXT_MASK 0x4
        /* Remove requirement for VBUS in bus-powered mode */
        if(pwrConfig == XUD_PWR_BUS)
        {
             write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_UIFM_USB_PHY_EXT_CTRL_REG, XS1_UIFM_USB_PHY_EXT_CTRL_VBUSVLDEXTSEL_MASK | XS1_UIFM_USB_PHY_EXT_CTRL_VBUSVLDEXT_MASK);
        }

#define PHYTUNEREGVAL 0x0093B264
#define XS1_UIFM_USB_PHY_TUNE_REG 0x4c
        /* Phy Tuning parameters */
        /* OTG TUNE: 3b'100
         * TXFSLSTUNE: 4b'1001
         * TXVREFTUNE:4b'1001 -- +1.25% adjustment in HS DC voltage level
         * BIASTUNE: 1b'0
         * COMDISTUNE:3b'011 -- -1.5% adjustment from default (disconnect threshold adjustment)
         * SQRXTUNE:3b'010 -- +5% adjustment from default (Squelch Threshold)
         * TXRISETUNE: 1b'0
         * TXPREEMPHASISTUNE:1b'1 -- enabled (default is disabled)
         * TXHSXVTUNE: 2b'11
         */
        write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_UIFM_USB_PHY_TUNE_REG, PHYTUNEREGVAL);
#endif

#ifndef SIMULATION
    #if defined(ARCH_S) || defined(ARCH_X200)
        write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_CONTROL_NUM, (1<<XS1_SU_UIFM_IFM_CONTROL_DECODELINESTATE_SHIFT));
    #elif !defined(__XS3A__)
        XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, UIFM_CTRL_DECODE_LS);
    #endif
#endif
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
#if defined(ARCH_X200)
                        read_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_OTG_FLAGS_NUM, x);
                        if(x&(1<<XS1_UIFM_OTG_FLAGS_SESSVLDB_SHIFT))
#elif defined(ARCH_S) 
                        read_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_OTG_FLAGS_NUM, x);
                        if(x&(1<<XS1_SU_UIFM_OTG_FLAGS_SESSVLDB_SHIFT))
#elif ARCH_L
                        x = XUD_UIFM_RegRead(reg_write_port, reg_read_port, UIFM_OTG_FLAGS_REG);
                        if(x&(1<<UIFM_OTG_FLAGS_SESSVLD_SHIFT))
#endif
                        {
                            break;
                        }
                        t :> time;
                        time += (200 * REF_CLK_FREQ); // 200us poll
                        t when timerafter(time):> void;
                    }
                }
#ifndef SIMULATION
#if defined(__XS1B__) || defined(__XS2A__)
                /* Go into full speed mode: XcvrSelect and Term Select (and suspend) high */
                write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM,
                      (1<<XS1_SU_UIFM_FUNC_CONTROL_XCVRSELECT_SHIFT)
                    | (1<<XS1_SU_UIFM_FUNC_CONTROL_TERMSELECT_SHIFT));
#elif defined(__XS3A__)
            // TODO
            //XUD_HAL_EnterMode
#endif
#endif  /* SIMULATION */

#ifdef SIMULATION
                reset = 1;
#else
                /* Setup flags for power signalling - J/K/SE0 line state*/
                XUD_UIFM_PwrSigFlags();

                if (one)
                {
                    /* Set flags up for pwr signalling */
                    reset = XUD_Init();
                    one = 0;
                }
                else
                {
                    XUD_Sup_Delay(20000); // T_WTRSTHS: 100-875us

                    /* Sample line state and check for reset (or suspend) */
                    flag2_port :> reset; /* SE0 Line */
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
                if(reset==1)
                {

                    if(!sentReset)
                    {
                        SendResetToEps(epChans0, epChans, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, USB_RESET_TOKEN);
                        sentReset = 1;
                    }
#ifdef __XS3A__
                    XUD_SetCrcTableAddr(XUD_STARTUP_ADDRESS);
#endif
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

#ifndef SIMULATION
                    /* Set default device address */
    #if defined(__XS1B__) || defined(__XS2A__)
                    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_DEVICE_ADDRESS_NUM, 0);
    #elif defined(__XS3A__)
        // TODO
    #endif
#endif

#ifdef SIMULATION
                    if(g_desSpeed == XUD_SPEED_HS)
                    {
                        g_curSpeed = XUD_SPEED_HS;
                        g_txHandshakeTimeout = HS_TX_HANDSHAKE_TIMEOUT;
                    }
                    else
                    {
                        g_curSpeed = XUD_SPEED_FS;
                        g_txHandshakeTimeout = FS_TX_HANDSHAKE_TIMEOUT;
                    }
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


            /* Set UIFM to CHECK TOKENS mode and enable LINESTATE_DECODE
            NOTE: Need to do this every iteration since CHKTOK would break power signaling */
#ifndef SIMULATION
    #if defined(__XS1B__) || defined(__XS2A__)
            write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_CONTROL_NUM, (1<<XS1_SU_UIFM_IFM_CONTROL_DOTOKENS_SHIFT)
                | (1<< XS1_SU_UIFM_IFM_CONTROL_CHECKTOKENS_SHIFT)
                | (1<< XS1_SU_UIFM_IFM_CONTROL_DECODELINESTATE_SHIFT)
                | (1<< XS1_SU_UIFM_IFM_CONTROL_SOFISTOKEN_SHIFT));
    #endif
#endif

#ifndef SIMULATION
    #if defined(__XS1B__) || defined (__XS2A__)
            write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_MASK_NUM,
                ((1<<XS1_SU_UIFM_IFM_FLAGS_NEWTOKEN_SHIFT)
                | ((1<<XS1_SU_UIFM_IFM_FLAGS_RXACTIVE_SHIFT)<<8)
                | ((1<<XS1_SU_UIFM_IFM_FLAGS_RXERROR_SHIFT)<<16)));
    #elif defined(__XS3A__)
        // TODO 
    #endif
#endif

            //set_thread_fast_mode_on();

            /* Run main IO loop */
            /* TODO re-order flag ports such that this check is not required */
#if defined (__XS3A__)
            /* flag0: Rx Error
               flag1: Rx Active
               flag2: Null */
            noExit = XUD_LLD_IoLoop(p_usb_rxd, flag1_port, p_usb_txd, flag2_port,  flag0_port, reg_read_port, reg_write_port, 0, epTypeTableOut, epTypeTableIn, epChans, noEpOut, c_sof);
#else
            /* flag0: Valid token flag
               flag1: Rx Active
               flag2: Rx Error */
            noExit = XUD_LLD_IoLoop(p_usb_rxd, flag1_port, p_usb_txd, flag2_port,  flag0_port, reg_read_port, reg_write_port, 0, epTypeTableOut, epTypeTableIn, epChans, noEpOut, c_sof);
#endif
            set_thread_fast_mode_off();

            /* Put UIFM back to default state */
#if defined(ARCH_S) || defined(__XS2A__)
           // write_periph_word(USB_TILE_REF, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_IFM_CONTROL_REG,
                //(1<<XS1_UIFM_IFM_CONTROL_DOTOKENS) |
                //(1<< XS1_UIFM_IFM_CONTROL_CHECKTOKENS) |
             //   (1<< XS1_UIFM_IFM_CONTROL_DECODELINESTATE));
                 //(1<< XS1_UIFM_IFM_CONTROL_SOFISTOKEN));
#endif 
    
            if(!noExit)
                break;


        }

        /* Reset transceiver */
        if (!isnull(p_rst)) {
           p_rst <: 0;
        }

    }

    /* TODO stop clock blocks */

    /* Turn ports off */
    set_port_use_off(p_usb_txd);
    set_port_use_off(p_usb_rxd);
    set_port_use_off(flag0_port);
    set_port_use_off(flag1_port);
#if !defined(__XS3A__)
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
                break;
            case 1:
                while (!testct(chans[i]))
                    inuchar(chans[i]);
                break;
            case 2:
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
                out port ?p_rst, clock ?clk, unsigned rstMask, XUD_BusSpeed_t speed, XUD_PwrConfig pwrConfig)
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
     // ep_info[i].epAddress = i;

    }

    for(int i = 0; i< noEpIn; i++)
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

        //ep_info[USB_MAX_NUM_EP_OUT+i].epAddress = 0x80; // OR in the IN bit

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

#ifndef ARCH_S
    /* Clock reset port from reference clock (required as clkblk 0 running from USB clock) */
    if(!isnull(p_rst) && !isnull(clk))
    {
       set_port_clock(p_rst, clk);
    }

    if(!isnull(clk))
    {
       set_clock_on(clk);
       set_clock_ref(clk);
       start_clock(clk);
    }

   #endif

    /* Run the main XUD loop */
    XUD_Manager_loop(epChans0, epChans, c_sof, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, p_rst, rstMask, clk, pwrConfig);

    // Need to close, drain, and check - three stages.
    for(int i = 0; i < 3; i++)
    {
        drain(c_ep_out, noEpOut, i, epTypeTableOut);  // On all inputs
        drain(c_ep_in, noEpIn, i, epTypeTableIn);     // On all output
    }

    /* Don't hit */
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
