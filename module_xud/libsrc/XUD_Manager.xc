
/** XUD_Manager.xc
  * @brief     XMOS USB Device(XUD) Layer
  * @author    Ross Owen
  * @version   0.1
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

#include "xud.h"
#include "usb.h"
#include "XUD_UIFM_Defines.h"
#include "XUD_USB_Defines.h"

#include "XUD_Support.h"
#include "XUD_UIFM_Functions.h"

#include "XUD_DeviceAttach.h"
#include "XUD_PowerSig.h"

#ifdef ARCH_L
#elif  ARCH_G
#else
#error ARCH_L or ARCH_G must be defined
#endif

#ifdef GLX
#warning BUILDING FOR GLX SUPPORT
#include "xa1_registers.h"
#include "glx.h"
#endif

void XUD_UserSuspend();
void XUD_UserResume();

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

#if 0
#pragma xta command "analyse path XUD_TokenRx_Pid XUD_TokenRx_Ep"
#pragma xta command "set required - 33 ns"   
#endif


/* Rx to TX 16 clks required with SMSC phy (14 in spec).  SIE Decision Time */
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxNak"
#pragma xta command "set required - 233 ns"             
#endif
#pragma xta command "add exclusion InNotReady"
#pragma xta command "remove exclusion InReady"


#pragma xta command "add exclusion XUD_IN_TxPid_Tail1"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail2"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail3"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS1"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS2"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS3"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_Tail0"
#pragma xta command "set required - 266 ns"   
#endif

#pragma xta command "remove exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail0"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_TailS0"
#pragma xta command "set required - 266 ns"   
#endif

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

#pragma xta command "remove exclusion Pid_Sof"
#pragma xta command "add exclusion Pid_Out"
#pragma xta command "add exclusion Pid_In"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_TokenRx_Pid"
#pragma xta command "set required - 50 ns"
#endif

/* Rx OUT Data end to Rx Token (ISO Out Data) */
//#pragma xta command "add exclusion OutTail0"
#pragma xta command "add exclusion OutTail1"
#pragma xta command "add exclusion OutTail2"
#pragma xta command "add exclusion OutTail3"
#pragma xta command "add exclusion OutTail4"
#pragma xta command "add exclusion OutTail5"
#pragma xta command "add exclusion ReportBadCrc"
#pragma xta command "add exclusion DoOutHandShakeOut"
#if 0
#pragma xta command "analyse path XUD_OUT_RxTail XUD_TokenRx_Pid"
#pragma xta command "set required - 50 ns"
#endif


/* TX INTRA PACKET TIMING */
#if 0
#pragma xta command "analyse path XUD_IN_TxPid_Tail0 TxLoop0_Out"
#pragma xta command "set required - 83 ns"
#endif

#define HS_TX_HANDSHAKE_TIMEOUT 100
#define FS_TX_HANDSHAKE_TIMEOUT 3000

/* Global vars for current and desired USB speed */
unsigned g_curSpeed;
unsigned g_desSpeed;
unsigned g_txHandshakeTimeout; 
unsigned g_prevPid=0xbadf00d;
unsigned int data_pid=0xbadf00d;

#ifdef GLX
/* USB Port declarations - for Zevious with Galaxion */
out port tx_readyout = XS1_PORT_1K; // aka txvalid
in port tx_readyin = XS1_PORT_1H;
out buffered port:32 p_usb_txd = XS1_PORT_8A;
in buffered port:32 p_usb_rxd = XS1_PORT_8C;
in port rx_rdy = XS1_PORT_1M;
in port flag0_port = XS1_PORT_1N;
in port flag1_port = XS1_PORT_1O;
in port flag2_port = XS1_PORT_1P;
in port p_usb_clk = XS1_PORT_1J;
clock tx_usb_clk = XS1_CLKBLK_5;
clock rx_usb_clk = XS1_CLKBLK_4;
out port p_trig = XS1_PORT_1L;
#define reg_write_port null
#define reg_read_port null
#else
/* USB Port declarations */
extern in port  p_usb_clk       ;
extern out port reg_write_port  ;
extern in  port reg_read_port   ;
extern in  port flag0_port      ;
extern in  port flag1_port      ;
extern in  port flag2_port      ;
extern out port p_usb_txd       ;
extern port p_usb_rxd       ;
#endif

#ifdef XUD_ISO_OUT_COUNTER
int xud_counter = 0;
#endif

/* Sets the UIFM flags into a mode suitable for power signalling */
void XUD_UIFM_PwrSigFlags()
{
#ifdef GLX
    write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FLAGS_MASK_REG, ((1<<XS1_UIFM_IFM_FLAGS_SE0)<<16) 
        | ((1<<XS1_UIFM_IFM_FLAGS_K)<<8) | (1 << XS1_UIFM_IFM_FLAGS_J));
#else
    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_FLAG_MASK0, 0x8);  // flag0_port - J
    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_FLAG_MASK1, 0x10); // flag1_port - K
    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_FLAG_MASK2, 0x20); // flag2_port - SE0
#endif
}

/* Tables storing if EP's are signed up to bus state updates */
int epStatFlagTableIn[16];
int epStatFlagTableOut[16];

/* Used for terminating XUD loop */
int XUD_USB_Done = 0;

extern void SetupChannelVectorsOverride(XUD_chan chans[]);

extern void SetupChannelVectors(XUD_chan chans[], int countOut, int countIn);

extern int XUD_LLD_IoLoop(
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
                            in port ?read, out port ?write, int x,
                            XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], XUD_chan epChans[],
                            int  epCount, chanend? c_sof, chanend ?c_usb_testmode) ;

// Pid sequencing tables.. note currently only supports DATA0/DATA1 sequencing
/* TODO these should be init in loop over EP COUNT */
unsigned char ep_pid_sequence_table_OUT[] = {PID_DATA1, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0, PID_DATA0};

unsigned char ep_pid_sequence_table_IN_A[] = {PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1, PIDn_DATA1};
unsigned char ep_pid_sequence_table_IN_B[] = {PIDn_DATA0, PIDn_DATA0, PIDn_DATA1, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0, PIDn_DATA0};

unsigned handshakeTable_IN[16];
unsigned handshakeTable_OUT[16];

unsigned crcmask = 0b11111111111;
unsigned chanArray;
//int gotReset = 0;

#define STATE_START 0
#define STATE_START_SE0 1
#define STATE_START_J 2

#define RESET_TIME_us              5 // 5us
#define RESET_TIME                   (RESET_TIME_us * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))

#ifndef ARCH_L
extern unsigned char crc5Table[2048];
unsigned char crc5Table_Addr[2048];

void XUD_SetCrcTableAddr(unsigned addr); 
#endif

static int one = 1;

#pragma unsafe arrays
static void sendCt(XUD_chan c[], XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], int nOut, int nIn, int token) 
{
    for(int i = 0; i < nOut; i++) 
    {
        if(epTypeTableOut[i] != XUD_EPTYPE_DIS && epStatFlagTableOut[i]) 
        {
            XUD_Sup_outct(c[i], token);
        }
    }
    for(int i = 0; i < nIn; i++) 
    { 
        if(epTypeTableIn[i] != XUD_EPTYPE_DIS && epStatFlagTableIn[i]) 
        {
            XUD_Sup_outct(c[i + nOut], token);
        }
    }
    for(int i = 0; i < nOut; i++) 
    {
        if(epTypeTableOut[i] != XUD_EPTYPE_DIS && epStatFlagTableOut[i]) 
        {
            while(!XUD_Sup_testct(c[i])) 
            {
                XUD_Sup_int(c[i]);
            }
            XUD_Sup_inct(c[i]);       // TODO chkct
        }
    }
    for(int i = 0; i < nIn; i++) 
    { 
        if(epTypeTableIn[i] != XUD_EPTYPE_DIS && epStatFlagTableIn[i]) 
        {    
          int tok=-1;
          while (tok != XS1_CT_END) {
            while(!XUD_Sup_testct(c[i + nOut])) 
            {
                XUD_Sup_int(c[i + nOut]);
            }
            tok = XUD_Sup_inct(c[i + nOut]);       // TODO chkct
          }
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
            XUD_Sup_outuint(c[i + nOut], speed);
        }
    }

}

// Main XUD loop
static int XUD_Manager_loop(XUD_chan epChans0[], XUD_chan epChans[],  chanend ?c_sof, XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], int noEpOut, int noEpIn, out port p_rst, unsigned rstMask, clock clk, chanend ?c_usb_testmode)
{
    int reset = 1;            /* Flag for if device is returning from a reset */
    const int reset_time = RESET_TIME;

    XUD_USB_Done = 0;

    /* Enable fast mode on thread */
    set_thread_fast_mode_on();

    /* Setup channel event vectors */
    SetupChannelVectors(epChans0, noEpOut, noEpIn);

    /* Make sure ports are on and reset port states */
    set_port_use_on(p_usb_clk);
    set_port_clock(p_usb_clk, clk);
    set_port_use_on(p_usb_txd);
    set_port_use_on(p_usb_rxd);
    set_port_use_on(flag0_port);
    set_port_use_on(flag1_port);
    set_port_use_on(flag2_port);
#ifndef GLX
    set_port_use_on(reg_read_port);
    set_port_use_on(reg_write_port);
#endif

    //TODO use XUD_SetDevAddr 
#ifdef ARCH_G
    XUD_SetCrcTableAddr(0);
#endif

#ifdef GLX
    /* Setup link with Glx */
    glx_link_setup(MYID, GLXID);
//All these delays are for a xev running at 500MHz
//#ifdef SDF
#if 1
//8 is abs max, any larger and the rdy's will not be produced
//These setting cause the rdy to be sampled as soon as 
//possible then output the data if allowed on the next cycle
#define TX_RISE_DELAY 5
#define TX_FALL_DELAY 2
#define RX_RISE_DELAY 7
#define RX_FALL_DELAY 7
#else
#define TX_RISE_DELAY 1
#define TX_FALL_DELAY 0
#define RX_RISE_DELAY 5
#define RX_FALL_DELAY 5
#endif


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

  //this delay controls the capture of rdy
  set_clock_rise_delay(tx_usb_clk, TX_RISE_DELAY);

  //this delay controls the launch of data.
  set_clock_fall_delay(tx_usb_clk, TX_FALL_DELAY);
  
  //this delay th capture of the rdyIn and data. 
  set_clock_rise_delay(rx_usb_clk, RX_RISE_DELAY);
  set_clock_fall_delay(rx_usb_clk, RX_FALL_DELAY);
  //set_port_sample_delay(p_usb_rxd);
  //set_port_sample_delay(rx_rdy);

  start_clock(tx_usb_clk);
  start_clock(rx_usb_clk);
  configure_out_port_handshake(p_usb_txd, tx_readyin, tx_readyout, tx_usb_clk, 0);
  configure_in_port_strobed_slave(p_usb_rxd, rx_rdy, rx_usb_clk);
#endif

    while(!XUD_USB_Done)
    {
#ifdef GLX

        /* Enable the USB clock */
        write_sswitch_reg(GLXID, XS1_GLX_CFG_RST_MISC_ADRS, ( ( 1 << XS1_GLX_CFG_USB_CLK_EN_BASE ) ) );

        /* Now reset the phy */
        write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_PHY_CONTROL_REG, (1<<XS1_UIFM_PHY_CONTROL_FORCERESET));

        /* Keep usb clock active, enter active mode */
        write_sswitch_reg(GLXID, XS1_GLX_CFG_RST_MISC_ADRS, (1 << XS1_GLX_CFG_USB_CLK_EN_BASE) | (1<<XS1_GLX_CFG_USB_EN_BASE)  );
#else
        /* Reset transceiver */
        XUD_PhyReset(p_rst, reset_time*10, rstMask);
#endif

        /* Wait for USB clock (typically 1ms after reset) */
        p_usb_clk when pinseq(1) :> int _;
        p_usb_clk when pinseq(0) :> int _;
        p_usb_clk when pinseq(1) :> int _;
        p_usb_clk when pinseq(0) :> int _;

#ifndef GLX
        /* Configure ports and clock blocks for use with UIFM */
        XUD_UIFM_PortConfig(p_usb_clk, reg_write_port, reg_read_port, flag0_port, flag1_port, flag2_port, p_usb_txd, p_usb_rxd) ;

        /* Enable UIFM and wait for connect */
        XUD_UIFM_Enable(UIFM_MODE);
#endif
 
#ifdef GLX
        write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_IFM_CONTROL_REG, 
            (1<<XS1_UIFM_IFM_CONTROL_DECODELINESTATE));
#else        
        XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, UIFM_CTRL_DECODE_LS);
#endif
        while(1)
        {
            /* Go into full speed mode: XcvrSelect and Term Select (and suspend) high */
#ifdef GLX
            write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FUNC_CONTROL_REG,
                (1<<XS1_UIFM_FUNC_CONTROL_XCVRSELECT) 
                | (1<<XS1_UIFM_FUNC_CONTROL_TERMSELECT));
#else

            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x7);
#endif      
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
                XUD_Sup_Delay(30000); // 200-800us
                //XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_FLAGS, 0x0);

                /* Sample line state and check for reset (or suspend) */
                //flags = XUD_UIFM_RegRead(reg_write_port, reg_read_port, UIFM_REG_FLAGS);

                //reset = flags & 0x20;
                flag2_port :> reset;
            }

            

            /* Inspect for suspend or reset */
            if(!reset)
            {
                /* Run user suspend code */
                XUD_UserSuspend();

                /* Run suspend code, returns 1 if reset from suspend, else resume */
                reset = XUD_Suspend();
                
                /* Run user resume code */
                XUD_UserResume();
            }

            /* Test if coming back from reset or suspend */
            if(reset)
            {
                sendCt(epChans0, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, USB_RESET_TOKEN);
                
#ifdef ARCH_G
                XUD_SetCrcTableAddr(0);
#endif
                /* Check for exit */
                if (XUD_USB_Done) 
                {
                    break;
                }

                /* Initialise PID sequence tables etc */
                for (int i = 0; i < noEpIn; i++)
                {
                    ep_pid_sequence_table_IN_A[i] = PIDn_DATA1;
                    ep_pid_sequence_table_IN_B[i] = PIDn_DATA1;
                }

                /* Set default device address */
#ifdef GLX
                write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG, 0);
#else
                XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_ADDRESS, 0x0);
#endif
                
                if(g_desSpeed == XUD_SPEED_HS)
                {
                    if (!XUD_DeviceAttachHS())
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


                /* Send speed to EPs */
                SendSpeed(epChans0, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, g_curSpeed);

                SetupChannelVectorsOverride(epChans0);

            }

            /* Set UIFM to CHECK TOKENS mode and enable LINESTATE_DECODE
            NOTE: Need to do this every iteration since CHKTOK would break power signaling */
#ifdef ARCH_L
#ifdef GLX
            write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_IFM_CONTROL_REG, (1<<XS1_UIFM_IFM_CONTROL_DOTOKENS) 
                | (1<< XS1_UIFM_IFM_CONTROL_CHECKTOKENS) 
                | (1<< XS1_UIFM_IFM_CONTROL_DECODELINESTATE)
                | (1<< XS1_UIFM_IFM_CONTROL_SOFISTOKEN));

#else
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, UIFM_CTRL_CHKTOK | UIFM_CTRL_DECODE_LS);
            
            /* Allow SOF tokens through */
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_MISC, UIFM_MISC_SOFISTOKEN);
#endif /* GLX */
#else
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, UIFM_CTRL_DECODE_LS);
#endif /* ARCH_L */

#ifdef GLX
            write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_FLAGS_MASK_REG,
                ((1<<XS1_UIFM_IFM_FLAGS_NEWTOKEN) 
                | ((1<<XS1_UIFM_IFM_FLAGS_RXACTIVE)<<8)
                | ((1<<XS1_UIFM_IFM_FLAGS_RXERROR)<<16)));

#else
            /* Set flag0_port to NEW_TOKEN (bit 6 of ifm flags) */
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_FLAG_MASK0, 0x40);   // bit 6

            /* Set flag1_port to RX_ACTIVE (bit 1) */
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_FLAG_MASK1, 0x02);   // bit 1

            /* Set flag2_port to RX_ERROR (bit 0) */
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_FLAG_MASK2, 0x01);   // bit 0
#endif /* GLX */

            /* Run main IO loop
                flag0: Valid token flag
                flag1: Rx Active
                flag2: Rx Error */
            XUD_LLD_IoLoop(p_usb_rxd,  flag1_port, p_usb_txd, flag2_port,  flag0_port, reg_read_port,
                           reg_write_port, 0, epTypeTableOut, epTypeTableIn, epChans, noEpOut, c_sof, c_usb_testmode); 


            /* Put UIFM back to default state */
#ifdef ARCH_L
#ifdef GLX
            //TODO
#else
            /* Disable SOF passing */
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_MISC, 0);
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, UIFM_CTRL_DECODE_LS);
#endif
#endif

        }

        /* Reset transceiver */
        p_rst <: 0;

    }


#ifndef GLX
    XUD_UIFM_Enable(0);
#endif

    /* Turn ports off */
    set_port_use_off(p_usb_txd);
    set_port_use_off(p_usb_rxd);
    set_port_use_off(flag0_port);
    set_port_use_off(flag1_port);
    set_port_use_off(flag2_port);
#ifdef GLX
    #warning TODO switch off ports
#else
    set_port_use_off(reg_read_port);
    set_port_use_off(reg_write_port);
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


XUD_chan epChans[32];
XUD_chan epChans0[32];

typedef struct XUD_ep_info { 
  unsigned int chan_array_ptr;
  unsigned int ep_xud_chanend;
  unsigned int ep_client_chanend;
  unsigned int scratch;   // 3 used for datalength in
  unsigned int pid;      //4 
  unsigned int scratch2; // 5 Data 
  //unsigned int scratch3; // 5 Data (used for datalenght in)
} XUD_ep_info;


static XUD_ep_info ep_info[32];

//#pragma unsafe arrays
int XUD_Manager(chanend c_ep_out[], int noEpOut, 
                chanend c_ep_in[], int noEpIn,
                chanend ?c_sof,
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], 
                out port p_rst, clock clk, unsigned rstMask, unsigned speed, chanend ?c_usb_testmode)
{
    /* Arrays for channels... */
    /* TODO use two arrays? */

    g_desSpeed = speed;

    XUD_USB_Done = 0;

    for (int i=0; i < 32;i++)
      epChans[i] = 0;

    /* Populate arrays of channels and status flag tabes */
    for(int i = 0; i < noEpOut; i++)
    {
      int x;
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

      handshakeTable_OUT[i] = PIDn_NAK;
    }

    for(int i = 0; i< noEpIn; i++)
    {
        int x;
        epChans0[i+noEpOut] = XUD_Sup_GetResourceId(c_ep_in[i]);

        asm("ldaw %0, %1[%2]":"=r"(x):"r"(epChans),"r"(noEpOut+i));
        ep_info[noEpOut+i].chan_array_ptr = x;

        asm("mov %0, %1":"=r"(x):"r"(c_ep_in[i]));
        ep_info[noEpOut+i].ep_xud_chanend = x;      
      
	    asm("getd %0, res[%1]":"=r"(x):"r"(c_ep_in[i]));
        ep_info[noEpOut+i].ep_client_chanend = x;      
      
	    asm("ldaw %0, %1[%2]":"=r"(x):"r"(ep_info),"r"((noEpOut+i)*sizeof(XUD_ep_info)/sizeof(unsigned)));

        outuint(c_ep_in[i], x);

        ep_info[noEpOut+i].pid = PIDn_DATA1;
	   
        epStatFlagTableIn[i] = epTypeTableIn[i] & XUD_STATUS_ENABLE;
        epTypeTableIn[i] = epTypeTableIn[i] & 0x7FFFFFFF;

        handshakeTable_IN[i] = PIDn_NAK;
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

    /* Clock reset port from reference clock (required as clkblk 0 running from USB clock) */
    set_clock_on(clk);
    set_clock_ref(clk);
    set_port_clock(p_rst, clk);
    start_clock(clk);

    /* Run the main XUD loop */
    XUD_Manager_loop(epChans0, epChans, c_sof, epTypeTableOut, epTypeTableIn, noEpOut, noEpIn, p_rst, rstMask, clk, c_usb_testmode);

    // TODO --- Could do with a cleaner mechanism for this cleaning up all endpoints
    // If the global variable XUD_USB_Done is set the manager loop will exit and return us to main()
    // This is pretty nasty, required to clean up the endpoint channels so they can be free'd by the normal exit from main
    outuint(c_ep_out[0], -1);
    outuint(c_ep_out[0], -1);


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

void ERR_BadCrc()
{
#ifdef XUD_DEBUG_VERSION
  printstrln("BAD DATA CRC");
  while(1);
#endif
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
