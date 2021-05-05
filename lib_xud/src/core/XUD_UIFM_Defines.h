// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/**
  * \brief Defines for interfacing UIFM (L-series and G-series only)
  * Author Ross Owen
  **/

#if defined (ARCH_L) && !defined(ARCH_X200) & !defined(ARCH_S)

#ifndef _XUD_UIFM_DEFINES_H_
#define _XUD_UIFM_DEFINES_H_ 1

#define UIFM_MODE               2   // ULPI

#if 1
/* Flags Register */
#ifdef ARCH_L
#define UIFM_REG_FLAGS           6
#else
#define UIFM_REG_FLAGS           5
#endif

#define UIFM_FLAGS_RXE                  0x1
#define UIFM_FLAGS_RXA                  0x2
#define UIFM_FLAGS_CRCFAIL              0x4
//#define UIFM_FLAGS_FS_K               0x8
//#define UIFM_FLAGS_FS_J               0x10
#define XS1_UIFM_IFM_FLAGS_K_MASK       0x10 /* Fullspeed J/High-speed K */
#define XS1_UIFM_IFM_FLAGS_J_MASK       0x08 /* Fullspeed K/High-speed J */
#define XS1_UIFM_IFM_FLAGS_SE0_MASK     0x20
#define UIFM_FLAGS_NEWTOK               0x40
#define XS1_IFM_FLAGS_HOSTACK           0x80


#ifdef ARCH_L
/* L Series UIFM Defines */

/* UIFM Ports */
//#define UIFM_INT_CLK_PORT        XS1_PORT_1I // Not required in software
#define UIFM_USB_CLK_PORT        XS1_PORT_1H

#define UIFM_REG_WRITE_PORT      XS1_PORT_8C
#define UIFM_REG_READ_PORT       XS1_PORT_8D
#define UIFM_FLAG_0_PORT         XS1_PORT_1N
#define UIFM_FLAG_1_PORT         XS1_PORT_1O
#define UIFM_FLAG_2_PORT         XS1_PORT_1P
#define UIFM_TX_DATA_PORT        XS1_PORT_8A
#define UIFM_RX_DATA_PORT        XS1_PORT_8B
#define UIFM_STP_SUS_PORT        XS1_PORT_1E
#define UIFM_LS_PORT             XS1_PORT_4D

/* Basic UIFM Commands */
#define UIFM_CMD_READ               0x00
#define UIFM_CMD_WRITE              0x80
#define UIFM_CMD_WRITEACK           0xc0

/* UIFM Registers */

/* Control Register */
#define UIFM_REG_CTRL               0x01

#define UIFM_CTRL_DEFAULT           0x00
#define UIFM_CTRL_DOTOK             0x01
#define UIFM_CTRL_CHKTOK            0x02
#define UIFM_CTRL_DECODE_LS         0x04
#define UIFM_CTRL_PKTBUF            0x08
#define UIFM_CTRL_BUFFRDY           0x10


/* Device Address Register */
#define UIFM_REG_ADDRESS            0x02


/* Phy Control Register */
#define UIFM_REG_PHYCON             0x03    /* Function Ctl */

#define UIFM_PHYCON_SUSPEND         0x01
#define UIFM_PHYCON_XCVRSEL         0x02
#define UIFM_PHYCON_TERMSEL         0x04


#define UIFM_REG_ULPICON         4

//#define UIFM_REG_SOF1               13
//#define UIFM_REG_SOF2               14


#define UIFM_REG_STATUS           7 /* NEW */
#define UIFM_REG_STICKY          8

#define UIFM_REG_FLAG_MASK0      9
#define UIFM_REG_FLAG_MASK1      10
#define UIFM_REG_FLAG_MASK2      11
#define UIFM_REG_FLAG_MASK3       12 /* NEW */
#define UIFM_REG_SOF0            13
#define UIFM_REG_SOF1            14
#define UIFM_REG_PID             15
#define UIFM_REG_EP              16
#define UIFM_REG_HANDSHAKE       17
#define UIFM_REG_BUFFCTRL        18
#define UIFM_REG_BUFFDATA        19

/* Misc config reg */
#define UIFM_REG_MISC            55
#define UIFM_MISC_SOFISTOKEN     0b10000

/* OTG Flags Reg */
#define UIFM_OTG_FLAGS_REG          5
#define UIFM_OTG_FLAGS_SESSEND_SHIFT      0
#define UIFM_OTG_FLAGS_SESSVLD_SHIFT      1
#define UIFM_OTG_FLAGS_VBUSVLD_SHIFT      2
#define UIFM_OTG_FLAGS_HOSTDIS_SHIFT      3
#define UIFM_OTG_FLAGS_NIDGND_SHIFT       4

#define UIFM_IN_REG_OFFSET       36
#define UIFM_OUT_REG_OFFSET      20

#else



#define UIFM_INT_CLK_PORT        XS1_PORT_1I // Not required in software
#define UIFM_USB_CLK_PORT        XS1_PORT_1H


// Basic UIFM Commands
#define UIFM_CMD_READ            0x00
#define UIFM_CMD_WRITE           0x80
#define UIFM_CMD_WRITEACK        0xc0
// //#define UIFM_CMD_WRITE_BUFFDATA  0x91
// //#define UIFM_CMD_READ_BUFFDATA   0x11
// //#define UIFM_CMD_READ_SBUFFDATA  0x34
//
// // UIFM Register Address'
 #define UIFM_REG_ADDRESS           2
 #define UIFM_REG_CTRL              1
 #define UIFM_REG_PHYCON            3
 #define UIFM_REG_ULPICON           4
 #define UIFM_REG_STICKY            7
 #define UIFM_REG_FLAG_MASK0        8
 #define UIFM_REG_FLAG_MASK1        9
 #define UIFM_REG_FLAG_MASK2        10
 #define UIFM_REG_SOF0              11
 #define UIFM_REG_SOF1              12
 #define UIFM_REG_PID               13
 #define UIFM_REG_EP                14
 #define UIFM_REG_HANDSHAKE         15
 #define UIFM_REG_BUFFCTRL          16
 #define UIFM_REG_BUFFDATA          17
//
// // Control Register defines
 #define UIFM_CTRL_DOTOK            0x1
 #define UIFM_CTRL_CHKTOK           0x2
 #define UIFM_CTRL_DECODE_LS        0x4
 #define UIFM_CTRL_PKTBUF           0x8
 #define UIFM_CTRL_BUFFRDY          0x10
//
 #define UIFM_IN_REG_OFFSET         36
 #define UIFM_OUT_REG_OFFSET        20
//

#endif
#endif

#endif // _XUD_UIFM_DEFINES_H_
#endif
