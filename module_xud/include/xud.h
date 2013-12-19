/*
 * \brief     User defines and functions for XMOS USB Device library
 */

#ifndef __xud_h__
#define __xud_h__

#include <xs1.h>
#include <platform.h>
#include <print.h>


#define XUD_U_SERIES 1
#define XUD_L_SERIES 2
#define XUD_G_SERIES 3

#ifdef __xud_conf_h_exists__
#include "xud_conf.h"
#endif

#include "xud_defines.h"

#if !defined(USB_TILE)
  #define USB_TILE tile[0]
#endif

#if defined(PORT_USB_CLK)

  /* Ports declared in the .xn file. Automatically detect device series */
  #if defined(PORT_USB_RX_READY)
    #if !defined(XUD_SERIES_SUPPORT)
      #define XUD_SERIES_SUPPORT XUD_U_SERIES
    #endif

    #if (XUD_SERIES_SUPPORT != XUD_U_SERIES)
      #error (XUD_SERIES_SUPPORT != XUD_U_SERIES) with PORT_USB_RX_READY defined
    #endif

  #else
    #if !defined(XUD_SERIES_SUPPORT)
      #define XUD_SERIES_SUPPORT XUD_L_SERIES
    #endif

    #if (XUD_SERIES_SUPPORT != XUD_L_SERIES) && (XUD_SERIES_SUPPORT != XUD_G_SERIES)
      #error (XUD_SERIES_SUPPORT != XUD_L_SERIES) when PORT_USB_RX_READY not defined
    #endif

  #endif

#else // PORT_USB_CLK

  #if !defined(XUD_SERIES_SUPPORT)
    // Default to U-Series if no series is defined
    #define XUD_SERIES_SUPPORT XUD_U_SERIES
  #endif

  /* Ports have not been defined in the .xn file */
  #define PORT_USB_FLAG0       on USB_TILE: XS1_PORT_1N
  #define PORT_USB_FLAG1       on USB_TILE: XS1_PORT_1O
  #define PORT_USB_FLAG2       on USB_TILE: XS1_PORT_1P

  #if (XUD_SERIES_SUPPORT == XUD_U_SERIES)
    #define PORT_USB_CLK         on USB_TILE: XS1_PORT_1J
    #define PORT_USB_TXD         on USB_TILE: XS1_PORT_8A
    #define PORT_USB_RXD         on USB_TILE: XS1_PORT_8C
    #define PORT_USB_TX_READYOUT on USB_TILE: XS1_PORT_1K
    #define PORT_USB_TX_READYIN  on USB_TILE: XS1_PORT_1H
    #define PORT_USB_RX_READY    on USB_TILE: XS1_PORT_1M
  #else
    #define PORT_USB_CLK         on USB_TILE: XS1_PORT_1H
    #define PORT_USB_REG_WRITE   on USB_TILE: XS1_PORT_8C
    #define PORT_USB_REG_READ    on USB_TILE: XS1_PORT_8D
    #define PORT_USB_TXD         on USB_TILE: XS1_PORT_8A
    #define PORT_USB_RXD         on USB_TILE: XS1_PORT_8B
  #endif

#endif // PORT_USB_CLK

/**
 * \var     typedef XUD_EpTransferType
 * \brief   Typedef for endpoint data transfer types.  Note: it is important that ISO is 0
 */
typedef enum XUD_EpTransferType
{
    XUD_EPTYPE_ISO = 0,          /**< Isoc */
    XUD_EPTYPE_INT,              /**< Interrupt */
    XUD_EPTYPE_BUL,              /**< Bulk */
    XUD_EPTYPE_CTL,              /**< Control */
    XUD_EPTYPE_DIS,              /**< Disabled */
} XUD_EpTransferType;

/**
 * \var     typedef XUD_EpType
 * \brief   Typedef for endpoint type
 */
typedef unsigned int XUD_EpType;

/**
 * \var     typedef XUD_ep
 * \brief   Typedef for endpoint identifiers
 */
typedef unsigned int XUD_ep;

/* Value to be or'ed in with EpTransferType to enable bus state notifications */
#define XUD_STATUS_ENABLE           0x80000000

typedef enum XUD_BusSpeed
{
    XUD_SPEED_FS = 1,
    XUD_SPEED_HS = 2
} XUD_BusSpeed;


typedef enum XUD_PwrConfig
{
    XUD_PWR_BUS,
    XUD_PWR_SELF
} XUD_PwrConfig;


/**********************************************************************************************
 * Below are prototypes for main assembly functions for data transfer to/from USB I/O thread
 * All other Get/Set functions defined here use these.  These are implemented in XUD_EpFuncs.S
 * Wrapper functions are provided for conveniance (implemented in XUD_EpFunctions.xc).
 */

/**
 *  \brief      Gets a data buffer from XUD
 *  \param      ep_out     The OUT endpoint identifier.
 *  \param      buffer     The buffer to store received data into.
 *  \return     Datalength (in bytes)
 */
inline int XUD_GetData(XUD_ep ep_out, unsigned char buffer[]);

/**
 *  \brief      Gets a setup data from XUD
 *  \param      ep_out     The OUT endpoint identifier.
 *  \param      ep_in      The IN endpoint identifier.
 *  \param      buffer     The buffer to store received data into.
 *  \return     Datalength (in bytes).
 *  TODO:       Use generic GetData from this
 */
int XUD_GetSetupData(XUD_ep ep_out, XUD_ep ep_in, unsigned char buffer[]);

/**
 *  \brief      Gives a data buffer to XUD from transmission to the host
 *  \param      ep_in      The IN endpoint identifier.
 *  \param      buffer     The packet buffer to send data from.
 *  \param      datalength The length of the packet to send (in bytes).
 *  \param      startIndex The start index of the packet in the buffer (typically 0).
 *  \param      pidToggle  No longer used
 *  \return                0 on non-error, -1 on bus-reset.
 */
int XUD_SetData(XUD_ep ep_in, unsigned char buffer[], unsigned datalength, unsigned startIndex, unsigned pidToggle);

/***********************************************************************************************/

/** This performs the low-level USB I/O operations. Note that this
 *  needs to run in a thread with at least 80 MIPS worst case execution
 *  speed.
 *
 *    \param  c_epOut   An array of channel ends, one channel end per
 *                      output endpoint (USB OUT transaction); this includes
 *                      a channel to obtain requests on Endpoint 0.
 *    \param  noEpOut    The number of output endpoints, should
 *                      be at least 1 (for Endpoint 0).
 *    \param  c_epIn    An array of channel ends, one channel end
 *                      per input endpoint (USB IN transaction); this
 *                      includes a channel to respond to
 *                      requests on Endpoint 0.
 *    \param  noEpIn    The number of input endpoints, should be
 *                      at least 1 (for Endpoint 0).
 *    \param  c_sof     A channel to receive SOF tokens on. This channel
 *                      must be connected to a process that
 *                      can receive a token once every 125 ms. If
 *                      tokens are not read, the USB layer will lock up.
 *                      If no SOF tokens are required ``null``
 *                      should be used as this channel.
 *
 *    \param  epTypeTableOut See ``epTypeTableIn``.
 *    \param  epTypeTableIn This and ``epTypeTableOut`` are two arrays
 *                            indicating the type of the endpoint.
 *                            Legal types include:
 *                           ``XUD_EPTYPE_CTL`` (Endpoint 0),
 *                           ``XUD_EPTYPE_BUL`` (Bulk endpoint),
 *                           ``XUD_EPTYPE_ISO`` (Isochronous endpoint),
 *                           ``XUD_EPTYPE_INT`` (Interrupt endpoint),
 *                           ``XUD_EPTYPE_DIS`` (Endpoint not used).
 *                            The first array contains the
 *                            endpoint types for each of the OUT
 *                            endpoints, the second array contains the
 *                            endpoint types for each of the IN
 *                            endpoints.
 *    \param  p_usb_rst The port to send reset signals to. Should be ``null`` for
 *                      U-Series.
 *    \param  clk       The clock block to use for the USB reset -
 *                      this should not be clock block 0. Should be ``null`` for U-Series.
 *    \param  rstMask   The mask to use when taking an external phy into/out of reset. The mask is
 *                      ORed into the port to disable reset, and unset when
 *                      deasserting reset. Use '-1' as a default mask if this
 *                      port is not shared.
 *    \param  desiredSpeed  This parameter specifies whether the
 *                          device must be full-speed (ie, USB-1.0) or
 *                          whether high-speed is acceptable if supported
 *                          by the host (ie, USB-2.0). Pass ``XUD_SPEED_HS``
 *                          if high-speed is allowed, and ``XUD_SPEED_FS``
 *                          if not. Low speed USB is not supported by XUD.
 *    \param  c_usb_testmode See :ref:`xud_usb_test_modes`
 *    \param  pwrConfig     Specifies whether the device is bus or self-powered. When self-powered the XUD will monitor the VBUS line for host disconnections. This is required for compliance reasons.
 *
 */
int XUD_Manager(chanend c_epOut[], int noEpOut,
                chanend c_epIn[], int noEpIn,
                chanend ?c_sof,
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[],
                out port ?p_usb_rst, clock ?clk, unsigned rstMask,
                XUD_BusSpeed desiredSpeed,
                chanend ?c_usb_testmode,
                XUD_PwrConfig pwrConfig);


/**
 * \brief  This function must be called by a thread that deals with an OUT endpoint.
 *         When the host sends data, the low-level driver will fill the buffer. It
 *         pauses until data is available.
 * \param  ep_out   The OUT endpoint identifier.
 * \param  buffer   The buffer to store data in. This is a buffer containing
 *                  characters. The buffer must be word aligned.
 * \return The number of bytes written to the buffer, for errors see :ref:`xud_status_reporting`.
 **/
int XUD_GetBuffer(XUD_ep ep_out, unsigned char buffer[]);


/**
 * \brief  Request setup data from usb buffer for a specific endpoint, pauses until data is available.
 * \param  ep_out   The OUT endpoint identifier.
 * \param  ep_in    The IN endpoint identifier.
 * \param  buffer   A char buffer passed by ref into which data is returned.
 * \return datalength in bytes (always 8)
 **/
int XUD_GetSetupBuffer(XUD_ep ep_out, XUD_ep ep_in, unsigned char buffer[]);


/**
 * \brief  This function must be called by a thread that deals with an IN endpoint.
 *         When the host asks for data, the low-level driver will transmit the buffer
 *         to the host.
 * \param  ep_in The endpoint identifier created by ``XUD_InitEp``.
 * \param  buffer The buffer of data to send out.
 * \param  datalength The number of bytes in the buffer.
 * \return  0 on success, for errors see :ref:`xud_status_reporting`.
 */
int XUD_SetBuffer(XUD_ep ep_in, unsigned char buffer[], unsigned datalength);


/* Same as above but takes a max packet size for the endpoint, breaks up data to transfers of no
 * greater than this.
 *
 * NOTE: This function reasonably assumes the max transfer size for an endpoint is word aligned
 **/

/**
 * \brief   Similar to XUD_SetBuffer but breaks up data transfers of into smaller packets.
 *          This function must be called by a thread that deals with an IN endpoint.
 *          When the host asks for data, the low-level driver will transmit the buffer
 *          to the host.
 * \param   ep_in        The IN endpoint identifier created by ``XUD_InitEp``.
 * \param   buffer       The buffer of data to send out.
 * \param   datalength   The number of bytes in the buffer.
 * \param   epMax        The maximum packet size in bytes.
 * \return  0 on success, for errors see :ref:`xud_status_reporting`.
 */
int XUD_SetBuffer_EpMax(XUD_ep ep_in, unsigned char buffer[], unsigned datalength, unsigned epMax);


/**
 * \brief  This function performs a combined ``XUD_SetBuffer`` and ``XUD_GetBuffer``.
 *         It transmits the buffer of the given length over the ``ep_in`` endpoint to
 *         answer an IN request, and then waits for a 0 length Status OUT transaction on ``ep_out``.
 *         This function is normally called to handle Get control requests to Endpoint 0.
 *
 * \param  ep_out The endpoint identifier that handles Endpoint 0 OUT data in the XUD manager.
 * \param  ep_in The endpoint identifier that handles Endpoint 0 IN data in the XUD manager.
 * \param  buffer The data to send in response to the IN transaction. Note that this data
 *         is chopped up in fragments of at most 64 bytes.
 * \param  length Length of data to be sent.
 * \param  requested  The length that the host requested, pass the value ``sp.wLength``.
 *
 * \return 0 on success, for errors see :ref:`xud_status_reporting`
 **/
int XUD_DoGetRequest(XUD_ep ep_out, XUD_ep ep_in,  unsigned char buffer[], unsigned length, unsigned requested);


/**
 * \brief  This function sends an empty packet back on the next IN request with
 *         PID1. It is normally used by Endpoint 0 to acknowledge success of a control transfer.
 * \param  ep_in The Endpoint 0 IN identifier to the XUD manager.
 *
 * \return 0 on success, for errors see :ref:`xud_status_reporting`
 **/
int XUD_DoSetRequestStatus(XUD_ep ep_in);


/**
 * \brief  This function must be called by Endpoint 0 once a ``setDeviceAddress``
 *         request is made by the host.
 * \param  addr New device address.
 * \warning Must be run on USB core
 */
void XUD_SetDevAddr(unsigned addr);


/**
 * \brief  This function will complete a reset on an endpoint. Can either pass
 *         one or two channel-ends in (the second channel-end can be set to ``null``).
 *         The return value should be inspected to find out what type of reset was
 *         performed. In Endpoint 0 typically two channels are reset (IN and OUT).
 *         In other endpoints ``null`` can be passed as the second parameter.
 * \param  one IN or OUT endpoint identifier to perform the reset on.
 * \param  two Optional second IN or OUT endpoint structure to perform a reset on.
 * \return Either ``XUD_SPEED_HS`` - the host has accepted that this device can execute
 *         at high speed, or ``XUD_SPEED_FS`` - the device should run at full speed.
 */
XUD_BusSpeed XUD_ResetEndpoint(XUD_ep one, XUD_ep &?two);


/**
 * \brief  Initialises an XUD_ep
 * \param  c_ep Endpoint channel to be connected to the XUD library.
 * \return Endpoint descriptor
 */
XUD_ep XUD_InitEp(chanend c_ep);


/**
 * \brief   Mark an endpoint as STALL based on its EP address.  Cleared automatically if a SETUP received on the endpoint.
 *          Note: the IN bit of the endpoint address is used.
 * \param   epNum Endpoint number.
 * \warning Must be run on same tile as XUD core
 */
void XUD_SetStallByAddr(int epNum);


/**
 * \brief   Mark an endpoint as NOT STALLed based on its EP address.
 *          Note: the IN bit of the endpoint address is used.
 * \param   epNum Endpoint number.
 * \warning Must be run on same tile as XUD core
 */
void XUD_ClearStallByAddr(int epNum);

/**
 * \brief   Mark an endpoint as STALLed.  It is cleared automatically if a SETUP received on the endpoint.
 * \param   ep XUD_ep type.
 * \warning Must be run on same tile as XUD core
 */
void XUD_SetStall(XUD_ep ep);


/**
 * \brief   Mark an endpoint as NOT STALLed
 * \param   ep XUD_ep type.
 * \warning Must be run on same tile as XUD core
 */
void XUD_ClearStall(XUD_ep ep);

/* USB 2.0 Spec 9.1.1.5 states that configuring a device should cause all
 * the status and configuration values associated with the endpoints in the
 * affected interfaces to be set to their default values.  This includes setting
 * the data toggle of any endpoint using data toggles to the value DATA0 */
/**
 * \brief   Reset and Endpoints state including data PID toggle
 *          Note: the IN bit of the endpoint address is used.
 * \param   epNum Endpoint number (including IN bit)
 * \warning Must be run on same tile as XUD core
 */
void XUD_ResetEpStateByAddr(unsigned epNum);



/* Advanced functions for supporting multple Endpoints in a single core */
/**
 * \brief   TBD
 */
#pragma select handler
void XUD_GetData_Select(chanend c, XUD_ep ep, int &tmp);

/**
 * \brief   TBD
 */
#pragma select handler
void XUD_SetData_Select(chanend c, XUD_ep ep, int &tmp);

/**
 * \brief   TBD
 */
inline void XUD_SetReady_Out(XUD_ep e, unsigned char bufferPtr[])
{
    int chan_array_ptr;
    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(e));
    asm ("stw %0, %1[3]"::"r"(bufferPtr),"r"(e));            // Store buffer
    asm ("stw %0, %1[0]"::"r"(e),"r"(chan_array_ptr));

}

/**
 * \brief   TBD
 */
inline void XUD_SetReady_OutPtr(XUD_ep ep, unsigned addr)
{
    int chan_array_ptr;

    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));
    asm ("stw %0, %1[3]"::"r"(addr),"r"(ep));            // Store buffer
    asm ("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));
}

/**
 * \brief   TBD
 */
inline void XUD_SetReady_In(XUD_ep e, unsigned char bufferPtr[], int len)
{
    int chan_array_ptr;
    int tmp, tmp2;
    int wordlength;
    int taillength;

    /* Knock off the tail bits */
    wordlength = len >>2;
    wordlength <<=2;

    taillength = zext((len << 5),7);

    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(e));

    // Get end off buffer address
    asm ("add %0, %1, %2":"=r"(tmp):"r"(bufferPtr),"r"(wordlength));

    asm ("neg %0, %1":"=r"(tmp2):"r"(len>>2));            // Produce negative offset from end off buffer

    // Store neg index
    asm ("stw %0, %1[6]"::"r"(tmp2),"r"(e));            // Store index

    // Store buffer pointer
    asm ("stw %0, %1[3]"::"r"(tmp),"r"(e));

    // Store tail len
    asm ("stw %0, %1[7]"::"r"(taillength),"r"(e));


    asm ("stw %0, %1[0]"::"r"(e),"r"(chan_array_ptr));      // Mark ready

}

/**
 * \brief   TBD
 */
inline void XUD_SetReady_InPtr(XUD_ep ep, unsigned addr, int len)
{
    int chan_array_ptr;
    int tmp, tmp2;
    int wordlength;
    int taillength;

    /* Knock off the tail bits */
    wordlength = len >>2;
    wordlength <<=2;

    taillength = zext((len << 5),7);

    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));

    // Get end off buffer address
    asm ("add %0, %1, %2":"=r"(tmp):"r"(addr),"r"(wordlength));

    asm ("neg %0, %1":"=r"(tmp2):"r"(len>>2));            // Produce negative offset from end off buffer

    // Store neg index
    asm ("stw %0, %1[6]"::"r"(tmp2),"r"(ep));            // Store index

    // Store buffer pointer
    asm ("stw %0, %1[3]"::"r"(tmp),"r"(ep));

    // Store tail len
    asm ("stw %0, %1[7]"::"r"(taillength),"r"(ep));

    asm ("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));      // Mark ready

}

/**
 *  \brief      TBD
 */
int XUD_ResetDrain(chanend one);

/**
 *  \brief      TBD
 */
XUD_BusSpeed XUD_GetBusSpeed(chanend c);

#define XUD_SUSPEND                 3

/* Control token defines - used to inform EPs of bus-state types */
#define USB_RESET_TOKEN             8        /* Control token value that signals RESET */
#define USB_SUSPEND_TOKEN           9        /* Control token value that signals SUSPEND */




#endif // __xud_h__
