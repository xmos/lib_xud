

#ifndef _XUD_USB_DEFINES_H_
#define _XUD_USB_DEFINES_H_

// Defines relating to USB/ULPI/UTMI/Phy specs

//---------------------------------------
// Absolute times are relative to the system clock freq and the reference clock divider
// Their values must correspond to the values derived from the XN file,
// and must be the same for all code domains

//#define XCORE_FREQ_MHz        500
#define XCORE_FREQ_Hz         (XCORE_FREQ_MHz * 1000000)

// The value is that written to the ref clock divider register.  The actual divide ratio is 1 more than this.
// E.g. for a divide by 4, the value 3 should be used
//#define REF_CLK_DIVIDER         4    // Ref freq = sys freq / (REF_CLK_DIVIDER +1)
//---------------------------------------


#define RESET_TIME_us                5 // 5us
#define RESET_TIME                       (RESET_TIME_us           * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))

// Device attach timing defines
#define T_SIGATT_ULPI_us          5000 // 5ms
#define T_SIGATT_ULPI                    (T_SIGATT_ULPI_us        * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))
#define T_ATTDB_us             1000000 // 1000ms
#define T_ATTDB                          (T_ATTDB_us              * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))
#define T_UCHEND_T_UCH_us      1000000 // 1000ms
#define T_UCHEND_T_UCH                   (T_UCHEND_T_UCH_us       * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))
#define T_UCHEND_T_UCH_ULPI_us    2000 //    2ms
#define T_UCHEND_T_UCH_ULPI              (T_UCHEND_T_UCH_us       * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))
#define T_FILT_us                   40 //   40us
#define T_FILT                           (T_FILT_us               * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))


#define T_SUSPEND_TIMEOUT_us      2000 // 2ms
#define T_SUSPEND_TIMEOUT                (T_SUSPEND_TIMEOUT_us    * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))
#define SUSPEND_T_WTWRSTHS_us      200 // 200us How long before checking for J after asserting XcvrSelect and Termselect
#define SUSPEND_T_WTWRSTHS               (SUSPEND_T_WTWRSTHS_us   * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))

#define OUT_TIMEOUT_us             500 // How long we wait for data after OUT token
#define OUT_TIMEOUT                      (OUT_TIMEOUT_us          * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))
#define TX_HANDSHAKE_TIMEOUT_us      5 // How long we wait for handshake after sending tx data
#define TX_HANDSHAKE_TIMEOUT             (TX_HANDSHAKE_TIMEOUT_us * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))


//////////////////////////////////////////////////////////////////////////////////
// String descriptor defines:
#define XUD_DESC_STR_USENG     0x0409 // US English

////////////////////////////////////////////////////////////////////////////////
// Interface descriptor defines:
//
// Classes:
#define XUD_DESC_INT_B_CLASS_HID  0x3
#define XUD_DESC_INT_B_SUBCLASS_BOOT  0x1

#define XUD_DESC_INT_B_CLASS_AUDIO      0x1
#define XUD_DESC_INT_B_SUBCLASS_AUDIOCONTROL 0x1

// Protocols:
#define XUD_DESC_INT_B_PROTOCOL_MOUSE   0x2

////////////////////////////////////////////////////////////////////////////////
// Endpoint descriptor defines:
//
// bmAtributes.TransferType
#define DESC_EP_BM_ATTRIBS_TTYPE_INT  0x3 // Interupt
              // Control
              // Bulk... iso
              //
#define XUD_DESC_EP_ADDRESS_IN              0x80
#define XUD_DESC_EP_ADDRESS_OUT             0x00

///////////////////////////////////////////////////////////////////////////////////
// HID Descriptor defines


// Raw PIDs
#define PID_OUT   0x01
#define PID_ACK   0x02
#define PID_IN    0x09
#define PID_SOF   0x05
#define PID_SETUP 0x0d
#define PID_PING  0x04

// PIDs with error check
// Token
#define PIDn_OUT   0xe1
#define PIDn_IN    0x69
#define PIDn_SOF   0xa5
#define PIDn_SETUP 0x2d

// Data PIDs
#define PIDn_DATA0  0xc3
#define PIDn_DATA1  0x4b
#define PID_DATA0   0x3
#define PID_DATA1   0xb

#define PIDn_ACK 0xd2
#define PIDn_NAK 0x5a
#define PIDn_STALL 0x1e



#define XUD_EP_TYPE_CON 1
#define XUD_EP_TYPE_DIS 1
#define XUD_EP_TYPE_ISO 0
#define XUD_EP_TYPE_INT 1











// TODO Move these.. they are not usn spec related
#define EP_BUFFER_SIZE 1024



// OUT endpoints
#define EP_OUT_DATA        1
//
// // IN endpoints
#define EP_IN_DATA_AVAIL   1
//
// // Generic
 #define EP_OK              0
 #define EP_TROUBLE         9
 #define EP_HALT            8
//
//
#endif
