

#ifndef _XUD_USB_DEFINES_H_
#define _XUD_USB_DEFINES_H_

// Defines relating to USB/ULPI/UTMI/Phy specs

#define RESET_TIME_us                5 // 5us
#define RESET_TIME                   (RESET_TIME_us * REF_CLK_FREQ)

// Device attach timing defines
#define T_SIGATT_ULPI_us            5000     // 5ms
#define T_SIGATT_ULPI               (T_SIGATT_ULPI_us * REF_CLK_FREQ)
#define T_ATTDB_us                  1000000  // 1000ms
#define T_ATTDB                     (T_ATTDB_us * REF_CLK_FREQ)
#define T_UCHEND_T_UCH_us           1000000  // 1000ms
#define T_UCHEND_T_UCH              (T_UCHEND_T_UCH_us * REF_CLK_FREQ)
#define T_UCHEND_T_UCH_ULPI_us      2000     //    2ms
#define T_UCHEND_T_UCH_ULPI         (T_UCHEND_T_UCH_us * REF_CLK_FREQ)
#define T_FILT_us                   40       //   40us
#define T_FILT                      (T_FILT_us * REF_CLK_FREQ)


#define T_SUSPEND_TIMEOUT_us        2000     // 2ms
#define T_SUSPEND_TIMEOUT           (T_SUSPEND_TIMEOUT_us * REF_CLK_FREQ)
#define SUSPEND_T_WTWRSTHS_us       200 // 200us Time beforechecking for J after asserting XcvrSelect and Termselect
#define SUSPEND_T_WTWRSTHS          (SUSPEND_T_WTWRSTHS_us * REF_CLK_FREQ)

#define OUT_TIMEOUT_us              500 // How long we wait for data after OUT token
#define OUT_TIMEOUT                 (OUT_TIMEOUT_us * REF_CLK_FREQ)
#define TX_HANDSHAKE_TIMEOUT_us      5 // How long we wait for handshake after sending tx data
#define TX_HANDSHAKE_TIMEOUT        (TX_HANDSHAKE_TIMEOUT_us * REF_CLK_FREQ)


//////////////////////////////////////////////////////////////////////////////////
// String descriptor defines:
#define XUD_DESC_STR_USENG             0x0409 // US English

////////////////////////////////////////////////////////////////////////////////
// Interface descriptor defines:
//
// Classes:
#define XUD_DESC_INT_B_CLASS_HID       0x3
#define XUD_DESC_INT_B_SUBCLASS_BOOT   0x1

#define XUD_DESC_INT_B_CLASS_AUDIO     0x1
#define XUD_DESC_INT_B_SUBCLASS_AUDIOCONTROL 0x1

// Protocols:
#define XUD_DESC_INT_B_PROTOCOL_MOUSE  0x2

////////////////////////////////////////////////////////////////////////////////
// Endpoint descriptor defines:
//
// bmAtributes.TransferType
#define DESC_EP_BM_ATTRIBS_TTYPE_INT   0x3 // Interupt
              // Control
              // Bulk... iso
              //
#define XUD_DESC_EP_ADDRESS_IN         0x80
#define XUD_DESC_EP_ADDRESS_OUT        0x00

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

// Test selector defines for Test mode
#define WINDEX_TEST_J               (0x1<<8)
#define WINDEX_TEST_K               (0x2<<8)
#define WINDEX_TEST_SE0_NAK         (0x3<<8)
#define WINDEX_TEST_PACKET          (0x4<<8)
#define WINDEX_TEST_FORCE_ENABLE    (0x5<<8)

#endif
