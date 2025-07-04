// Copyright 2011-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/*
 * \brief     User defines and functions for XMOS USB Device library
 */

#ifndef _XUD_H_
#define _XUD_H_

#include <platform.h>

#if !defined(__XS2A__)
#define XUD_OPT_SOFTCRC5 (1)
#else
#define XUD_OPT_SOFTCRC5 (0)
#endif

#ifdef __xud_conf_h_exists__
#include "xud_conf.h"
#endif

#ifndef XUD_STARTUP_ADDRESS
#define XUD_STARTUP_ADDRESS (0)
#endif

#ifndef __ASSEMBLER__

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <xccompat.h>

#ifndef XUD_WEAK_API
#define XUD_WEAK_API       (0)
#endif

#if defined(__STDC__) && XUD_WEAK_API
#define ATTRIB_WEAK __attribute__((weak));
#else
#define ATTRIB_WEAK
#endif

#if !defined(USB_TILE)
  #define USB_TILE tile[0]
#endif

#ifndef XUD_CORE_CLOCK
    #ifdef __XS2A__
        //#warning XUD_CORE_CLOCK not defined, using default (500MHz)
        #define XUD_CORE_CLOCK (500)
    #else
        //#warning XUD_CORE_CLOCK not defined, using default (600MHz)
        #define XUD_CORE_CLOCK (600)
    #endif
#endif

#if !defined(PORT_USB_CLK)
    /* Ports have not been defined in the .xn file */
    #define PORT_USB_CLK         on USB_TILE: XS1_PORT_1J
    #define PORT_USB_TXD         on USB_TILE: XS1_PORT_8A
    #define PORT_USB_RXD         on USB_TILE: XS1_PORT_8B
    #define PORT_USB_TX_READYOUT on USB_TILE: XS1_PORT_1K
    #define PORT_USB_TX_READYIN  on USB_TILE: XS1_PORT_1H
    #define PORT_USB_RX_READY    on USB_TILE: XS1_PORT_1I
    #define PORT_USB_FLAG0       on USB_TILE: XS1_PORT_1E
    #define PORT_USB_FLAG1       on USB_TILE: XS1_PORT_1F
    #ifdef __XS2A__
        /* XS2A has an additional flag port */
        #define PORT_USB_FLAG2       on USB_TILE: XS1_PORT_1G
    #endif
#endif // PORT_USB_CLK

/**
 * \var        typedef     XUD_EpTransferType
 * \brief      Typedef for endpoint data transfer types.  Note: it is important that ISO is 0
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
 * \var        typedef XUD_EpType
 * \brief      Typedef for endpoint type
 */
typedef unsigned int XUD_EpType;

/**
 * \var        typedef XUD_ep
 * \brief      Typedef for endpoint identifiers
 */
typedef unsigned int XUD_ep;

/* Value to be or'ed in with EpTransferType to enable bus state notifications */
#define XUD_STATUS_ENABLE           0x80000000

#define XUD_SPEED_FS_VAL            1
#define XUD_SPEED_HS_VAL            2

typedef enum XUD_BusSpeed
{
    XUD_SPEED_FS = XUD_SPEED_FS_VAL,
    XUD_SPEED_HS = XUD_SPEED_HS_VAL
} XUD_BusSpeed_t;

#define XUD_PWR_BUS_VAL             0
#define XUD_PWR_SELF_VAL            1

typedef enum XUD_PwrConfig
{
    XUD_PWR_BUS = XUD_PWR_BUS_VAL,
    XUD_PWR_SELF = XUD_PWR_SELF_VAL
} XUD_PwrConfig;

typedef enum XUD_Result
{
    XUD_RES_UPDATE = -1,
    XUD_RES_OKAY = 0,
    XUD_RES_ERR =  2,
} XUD_Result_t;

/* Note, also used at CT to inform EPs of bus-state change type */
typedef enum XUD_BusState_t
{
    XUD_BUS_SUSPEND = 8,
    XUD_BUS_RESUME,
    XUD_BUS_RESET,
    XUD_BUS_KILL
} XUD_BusState_t;

#ifndef XUD_OSC_MHZ
#define XUD_OSC_MHZ                 (24)
#endif

/* Option to put the phy in low power mode during USB suspend */
#ifndef XUD_SUSPEND_PHY
#define XUD_SUSPEND_PHY             (1)
#endif

/** This performs the low-level USB I/O operations. Note that this
 *  needs to run in a thread with at least 80 MIPS worst case execution
 *  speed.
 *
 * \param   c_epOut     An array of channel ends, one channel end per
 *                      output endpoint (USB OUT transaction); this includes
 *                      a channel to obtain requests on Endpoint 0.
 * \param   noEpOut     The number of output endpoints, should be at least 1 (for Endpoint 0).
 * \param   c_epIn      An array of channel ends, one channel end per input endpoint (USB IN transaction);
 *                      this includes a channel to respond to requests on Endpoint 0.
 * \param   noEpIn      The number of input endpoints, should be at least 1 (for Endpoint 0).
 * \param   c_sof       A channel to receive SOF tokens on. This channel must be connected to a process that
 *                      can receive a token once every 125 ms. If tokens are not read, the USB layer will lock up.
 *                      If no SOF tokens are required ``null`` should be used for this parameter.
 *
 * \param   epTypeTableOut See ``epTypeTableIn``.
 * \param   epTypeTableIn  This and ``epTypeTableOut`` are two arrays
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
 * \param   desiredSpeed This parameter specifies what speed the device will attempt to run at
 *                      i.e. full-speed (ie 12Mbps) or high-speed (480Mbps) if supported
 *                      by the host. Pass ``XUD_SPEED_HS`` if high-speed is desired or ``XUD_SPEED_FS``
 *                         if not. Low speed USB is not supported by XUD.
 * \param   pwrConfig   Specifies whether the device is bus or self-powered. When self-powered the XUD
 *                      will monitor the VBUS line for host disconnections. This is required for compliance reasons.
 *                      Valid values are XUD_PWR_SELF and XUD_PWR_BUS.
 *
 */
int XUD_Main(/*tileref * unsafe usbtileXUD_res_t &xudres, */
                chanend c_epOut[], int noEpOut,
                chanend c_epIn[], int noEpIn,
                NULLABLE_RESOURCE(chanend, c_sof),
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[],
                XUD_BusSpeed_t desiredSpeed,
                XUD_PwrConfig pwrConfig);

/* Legacy API support */
int XUD_Manager(chanend c_epOut[], int noEpOut,
                chanend c_epIn[], int noEpIn,
                NULLABLE_RESOURCE(chanend, c_sof),
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[],
                NULLABLE_RESOURCE(port, p_usb_rst),
                NULLABLE_RESOURCE(xcore_clock_t, clk),
                unsigned rstMask,
                XUD_BusSpeed_t desiredSpeed,
                XUD_PwrConfig pwrConfig);

/**
 * \brief   This function must be called by a thread that deals with an OUT endpoint.
 *          When the host sends data, the low-level driver will fill the buffer. It
 *          pauses until data is available.
 * \param   ep_out      The OUT endpoint identifier (created by ``XUD_InitEP``).
 * \param   buffer      The buffer in which to store data received from the host.
 *                      The buffer is assumed to be word aligned.
 * \param   length      The number of bytes written to the buffer
 * \return  XUD_RES_OKAY on success, for errors see `Status Reporting`_.
 **/
XUD_Result_t XUD_GetBuffer(XUD_ep ep_out, unsigned char buffer[], REFERENCE_PARAM(unsigned, length)) ATTRIB_WEAK;

/**
 * \brief   Request setup data from usb buffer for a specific endpoint, pauses until data is available.
 * \param   ep_out      The OUT endpoint identifier (created by ``XUD_InitEP``).
 * \param   buffer      A char buffer passed by ref into which data is returned.
 * \param   length      Length of the buffer received (expect 8 bytes)
 * \return  XUD_RES_OKAY on success, for errors see ``Status Reporting``_.
 **/
XUD_Result_t XUD_GetSetupBuffer(XUD_ep ep_out, unsigned char buffer[], REFERENCE_PARAM(unsigned, length)) ATTRIB_WEAK;

/**
 * \brief  This function must be called by a thread that deals with an IN endpoint.
 *         When the host asks for data, the low-level driver will transmit the buffer
 *         to the host.
 * \param   ep_in       The endpoint identifier (created by ``XUD_InitEp``).
 * \param   buffer      The buffer of data to transmit to the host.
 * \param   datalength  The number of bytes in the buffer.
 * \return  XUD_RES_OKAY on success, for errors see `Status Reporting`_.
 */
XUD_Result_t XUD_SetBuffer(XUD_ep ep_in, unsigned char buffer[], unsigned datalength) ATTRIB_WEAK;

/**
 * \brief   Similar to XUD_SetBuffer but breaks up data transfers into smaller packets.
 *          This function must be called by a thread that deals with an IN endpoint.
 *          When the host asks for data, the low-level driver will transmit the buffer
 *          to the host.
 * \param   ep_in       The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param   buffer      The buffer of data to transmit to the host.
 * \param   datalength  The number of bytes in the buffer.
 * \param   epMax       The maximum packet size in bytes.
 * \return  XUD_RES_OKAY on success, for errors see `Status Reporting`_.
 */
XUD_Result_t XUD_SetBuffer_EpMax(XUD_ep ep_in, unsigned char buffer[], unsigned datalength, unsigned epMax) ATTRIB_WEAK;

/**
 * \brief  Performs a combined ``XUD_SetBuffer`` and ``XUD_GetBuffer``.
 *         It transmits the buffer of the given length over the ``ep_in`` endpoint to
 *         answer an IN request, and then waits for a 0 length Status OUT transaction on ``ep_out``.
 *         This function is normally called to handle Get control requests to Endpoint 0.
 *
 * \param   ep_out      The endpoint identifier that handles Endpoint 0 OUT data in the XUD manager.
 * \param   ep_in       The endpoint identifier that handles Endpoint 0 IN data in the XUD manager.
 * \param   buffer      The data to send in response to the IN transaction. Note that this data
 *                      is chopped up in fragments of at most 64 bytes.
 * \param   length      Length of data to be sent.
 * \param   requested   The length that the host requested, (Typically pass the value ``wLength``).
 * \return  XUD_RES_OKAY on success, for errors see `Status Reporting`_
 **/
XUD_Result_t XUD_DoGetRequest(XUD_ep ep_out, XUD_ep ep_in,  unsigned char buffer[], unsigned length, unsigned requested) ATTRIB_WEAK;

/**
 * \brief   This function sends an empty packet back on the next IN request with
 *          PID1. It is normally used by Endpoint 0 to acknowledge success of a control transfer.
 * \param   ep_in       The Endpoint 0 IN identifier to the XUD manager.
 * \return  XUD_RES_OKAY on success, for errors see `Status Reporting`_.
 **/
XUD_Result_t XUD_DoSetRequestStatus(XUD_ep ep_in) ATTRIB_WEAK;

/**
 * \brief   If an API function returns XUD_RES_UPDATE a bus update notification is available.
 *          The endpoint must now call this function to receive the bus update - these
 *          updates represent suspend, resume, reset and kill.
 * \param   one      IN or OUT endpoint identifier to receive update on.
 * \param   two      Optional second IN or OUT endpoint structure to receive update on.
 * \return  Either:
 *          XUD_BUS_SUSPEND - the host has suspended the device. The Endpoint should perform any
 *          desired suspend related functionality and then must call XUD_AckBusState() to inform
 *          XUD that it has been accepted.
 *          XUD_BUS_RESUME - the host has resumed the device. The Endpoint should perform any
 *          desired resume related functionality and then must call XUD_AckBusState() to inform
 *          XUD that it has been accepted.
 *          XUD_BUS_RESET - the host has issued a bus reset. The endpoint must now call
 *          XUD_ResetEndpoint().
 *          XUD_BUS_KILL - indicate that the USB stack has been shut down
 *          by another part of the user code (using XUD_Kill). If this value is returned, the
 *          endpoint code should call XUD_CloseEndpoint() and then
 *          terminate.
 */
XUD_BusState_t XUD_GetBusState(XUD_ep one, NULLABLE_REFERENCE_PARAM(XUD_ep, two));

/**
 * \brief   This function will complete a reset on an endpoint. Can take
 *          one or two ``XUD_ep`` as parameters (the second parameter can be set to ``null``).
 *          The return value should be inspected to find the new bus-speed.
 *          In Endpoint 0 typically two endpoints are reset (IN and OUT).
 *          In other endpoints ``null`` can be passed as the second parameter.
 * \param   one      IN or OUT endpoint identifier to perform the reset on.
 * \param   two      Optional second IN or OUT endpoint structure to perform a reset on.
 * \return  Either ``XUD_SPEED_HS`` - the device is now running as a high-speed device or
 *          ``XUD_SPEED_FS`` - the device is now running as full speed device.
 *
 */
XUD_BusSpeed_t XUD_ResetEndpoint(XUD_ep one, NULLABLE_REFERENCE_PARAM(XUD_ep, two));

/**
 * \brief   Must be called if an endpoint has received XUD_BUS_RESUME or XUD_BUS_SUSPEND
 *          in order to acknowledge the bus state update. Any related actions should be performed
 *          (i.e. clocking down the core) before calling this function.
 * \param   one      IN or OUT endpoint identifier to send the ack on.
 * \param   two      Optional second IN or OUT endpoint structure send the ack on.
 * \return  XUD_RES_OKAY on success, for errors see `Status Reporting`_.
 */
XUD_Result_t XUD_AckBusState(XUD_ep one, NULLABLE_REFERENCE_PARAM(XUD_ep, two));

/**
 * \brief   This function closes an endpoint. It should be called when the USB stack
 *          is shutting down. It should be called on all endpoints, either in parallel
 *          or in numerical order, first all OUT and then all IN endpoints
 * \param   one      endpoint to close.
 */
void XUD_CloseEndpoint(XUD_ep one);

/**
 * \brief      Initialises an XUD_ep
 * \param      c_ep     Endpoint channel to be connected to the XUD library.
 * \return     Endpoint identifier
 */
XUD_ep XUD_InitEp(chanend c_ep);

/**
 * \brief      Mark an endpoint as STALL based on its EP address.  Cleared automatically if a SETUP received on the endpoint.
 *             Note: the IN bit of the endpoint address is used.
 * \param      epNum    Endpoint number.
 * \warning    Must be run on same tile as XUD core
 */
void XUD_SetStallByAddr(int epNum);

/**
 * \brief      Mark an endpoint as NOT STALLed based on its EP address.
 *             Note: the IN bit of the endpoint address is used.
 * \param      epNum    Endpoint number.
 * \warning    Must be run on same tile as XUD core
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
 * \brief      Reset an Endpoints state including data PID toggle
 *             Note: the IN bit of the endpoint address is used.
 * \param      epNum    Endpoint number (including IN bit)
 * \warning    Must be run on same tile as XUD core
 */
void XUD_ResetEpStateByAddr(unsigned epNum);

/**
 * \brief   Enable a specific USB test mode in XUD
 * \param   ep          XUD_ep type (must be endpoint 0 in or out)
 * \param   testMode    The desired test-mode
 * \warning Must be run on same tile as XUD core
 */
void XUD_SetTestMode(XUD_ep ep, unsigned testMode);

/**
 * \brief   Terminate XUD core
 * \param   ep          XUD_ep type (must be endpoint 0 in or out)
 * \warning Must be run on same tile as XUD core
 */
void XUD_Kill(XUD_ep ep);

/***********************************************************************************************/

/*
 * Advanced functions for supporting multple Endpoints in a single task
 */

/**
 * \brief      Marks an OUT endpoint as ready to receive data
 * \param      ep          The OUT endpoint identifier (created by ``XUD_InitEp``).
 * \param      addr        The address of the buffer in which to store data received from the host.
 *                         The buffer is assumed to be word aligned.
 * \return     XUD_RES_OKAY on success, for errors see `Status Reporting`.
 */
#if (XUD_WEAK_API)
XUD_Result_t XUD_SetReady_OutPtr(XUD_ep ep, unsigned addr);
#else
static inline XUD_Result_t XUD_SetReady_OutPtr(XUD_ep ep, unsigned addr)
{
    int chan_array_ptr;
    int reset;

    /* Firstly check if we have missed a USB reset - endpoint may would not want receive after a reset */
    asm volatile("ldw %0, %1[9]":"=r"(reset):"r"(ep));
    if(reset)
    {
        return XUD_RES_UPDATE;
    }
    asm volatile("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));
    asm volatile("stw %0, %1[3]"::"r"(addr),"r"(ep));            // Store buffer
    asm volatile("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));

    return XUD_RES_OKAY;
}
#endif

/**
 * \brief      Marks an OUT endpoint as ready to receive data
 * \param      ep          The OUT endpoint identifier (created by ``XUD_InitEp``).
 * \param      buffer      The buffer in which to store data received from the host.
 *                         The buffer is assumed to be word aligned.
 * \return     XUD_RES_OKAY on success, for errors see `Status Reporting`.
 */
int XUD_SetReady_Out(XUD_ep ep, unsigned char buffer[]) ATTRIB_WEAK;

/**
 * \brief      Marks an IN endpoint as ready to transmit data
 * \param      ep          The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param      addr        The address of the buffer to transmit to the host.
 *                         The buffer is assumed be word aligned.
 * \param      len         The length of the data to transmit.
 * \return     XUD_RES_OKAY on success, for errors see `Status Reporting`.
 */
#if (XUD_WEAK_API)
XUD_Result_t XUD_SetReady_InPtr(XUD_ep ep, unsigned addr, int len);
#else
static inline XUD_Result_t XUD_SetReady_InPtr(XUD_ep ep, unsigned addr, int len)
{
    int chan_array_ptr;
    int tmp, tmp2;
    int wordLength;
    int tailLength;

    int reset;

    /* Firstly check if we have missed a USB reset - endpoint may not want to send out old data after a reset */
    asm volatile("ldw %0, %1[9]":"=r"(reset):"r"(ep));
    if(reset)
    {
        return XUD_RES_UPDATE;
    }

    /* Tail length bytes to bits */
#ifdef __XC__
    tailLength = zext((len << 3),5);
#else
    tailLength = (len << 3) & 0x1F;
#endif

    /* Datalength (bytes) --> datalength (words) */
    wordLength = len >> 2;

    /* If tail-length is 0 and word-length not 0. Make tail-length 32 and word-length-- */
    if ((tailLength == 0) && (wordLength != 0))
    {
        wordLength = wordLength - 1;
        tailLength = 32;
    }

    /* Get end off buffer address */
    asm volatile("add %0, %1, %2":"=r"(tmp):"r"(addr),"r"(wordLength << 2));

    /* Produce negative offset from end of buffer */
    asm volatile("neg %0, %1":"=r"(tmp2):"r"(wordLength));

    /* Store neg index */
    asm volatile("stw %0, %1[6]"::"r"(tmp2),"r"(ep));

    /* Store buffer pointer */
    asm volatile("stw %0, %1[3]"::"r"(tmp),"r"(ep));

    /*  Store tail len */
    asm volatile("stw %0, %1[7]"::"r"(tailLength),"r"(ep));

    /* Finally, mark ready */
    asm volatile("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));
    asm volatile("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));

    return XUD_RES_OKAY;
}
#endif

/**
 * \brief   Marks an IN endpoint as ready to transmit data
 * \param   ep          The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param   buffer      The buffer to transmit to the host.
 *                      The buffer is assumed be word aligned.
 * \param   len         The length of the data to transmit.
 * \return  XUD_RES_OKAY on success, for errors see `Status Reporting`.
 */
static inline XUD_Result_t XUD_SetReady_In(XUD_ep ep, unsigned char buffer[], int len)
{
    unsigned addr;

    asm volatile("mov %0, %1":"=r"(addr):"r"(buffer));

    return XUD_SetReady_InPtr(ep, addr, len);
}

/**
 * \brief   Select handler function for receiving OUT endpoint data in a select.
 * \param   c        The chanend related to the endpoint
 * \param   ep       The OUT endpoint identifier (created by ``XUD_InitEp``).
 * \param   length   Passed by reference. The number of bytes written to the buffer (that was passed into
 *                   XUD_SetReady_Out())
 * \param   result   XUD_Result_t passed by reference. XUD_RES_OKAY on success, for errors see `Status Reporting`.
 */
#ifdef __XC__
#pragma select handler
#endif
void XUD_GetData_Select(chanend c, XUD_ep ep, REFERENCE_PARAM(unsigned, length), REFERENCE_PARAM(XUD_Result_t, result));

/**
 * \brief   Select handler function for transmitting IN endpoint data in a select.
 * \param   c        The chanend related to the endpoint
 * \param   ep       The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param   result   Passed by reference. XUD_RES_OKAY on success, for errors see `Status Reporting`.
 */
#ifdef __XC__
#pragma select handler
#endif
void XUD_SetData_Select(chanend c, XUD_ep ep, REFERENCE_PARAM(XUD_Result_t, result));

/* Control token defines - used to inform EPs of bus-state types */
#define USB_RESET_TOKEN             (8)        /* Control token value that signals RESET */

/**
 * @def XUD_OSC_MHZ
 * @brief Frequency of oscillator used to clock xcore (in MHz)
 */
#ifndef XUD_OSC_MHZ
#define XUD_OSC_MHZ                 (24)
#endif

/**
 * @def XUD_SUSPEND_PHY
 * @brief Option to put the PHY in low power mode during USB suspend.
 *
 * When set to 1, the PHY will enter low power mode during USB suspend.
 * When set to 0 (default), this feature is disabled.
 *
 * Only supported on XS3A/xcore.ai based devices.
 */
#ifndef XUD_SUSPEND_PHY
#define XUD_SUSPEND_PHY             (0)
#endif

/**
 * @def XUD_THREAD_MODE_FAST_EN
 * @brief Enable fast thread mode for XUD.
 *
 * This option should not be changed unless expressly told to do so by XMOS support or documentation.
 *
 * When set to 1, the XUD thread will run in fast mode.
 * When set to 0, the XUD thread will run in standard mode.
 */
#ifndef XUD_THREAD_MODE_FAST_EN
#define XUD_THREAD_MODE_FAST_EN     (1)
#endif

/*
 * TODO size of this hardcoded in ResetEpStateByAddr_
 */
typedef struct XUD_ep_info
{
    unsigned int array_ptr;            // 0
    unsigned int xud_chanend;          // 1
    unsigned int client_chanend;       // 2
    unsigned int buffer;               // 3 Pointer to buffer
    unsigned int pid;                  // 4 Expected out PID
    unsigned int epType;               // 5 Data
    unsigned int actualPid;            // 6 Actual OUT PID received for OUT, Length (words) for IN.
    unsigned int tailLength;           // 7 "tail" length for IN (bytes)
    unsigned int epAddress;            // 8 EP address assigned by XUD (Used for marking stall etc)
    unsigned int busUpdate;            // 9 Flag to indicate to EP a bus-reset occured.
    unsigned int halted;               // 10 NAK or STALL
    unsigned int saved_array_ptr;      // 11
    unsigned int array_ptr_setup;      // 12
} XUD_ep_info;

#endif
#endif // _XUD_H_
