// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

// XUD_UIFM_PConfig.S
// Port configuration for UIFM
// Ross Owen

#include <xs1_user.h>

// From Autodefines...
#define SETCTRL_LMODE_SHIFT 12
#define SETCTRL_VALUE_SHIFT 3
#define SETCTRL_LMODE_PIN_DELAY 7
#define SETCTRL_LMODE_FALL_DELAY 8
#define SETCTRL_LMODE_RISE_DELAY 9
#define SETCTRL_MODE_LONG 7
#define SETCTRL_MODE_SHIFT 0

.text

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// XUD_UIFM_PortConfig(in port clk_port, out port reg_write_port, in port reg_read_port,
//                     in port flag0_port,
//                     in port flag1_port,
//                     in port flag2_port,
//                     out port txd_port, in port txd_port);
//

#define CLK r0
#define REG_WRITE r1
#define REG_READ r2
#define FLAG0 r3

.globl XUD_UIFM_PortConfig
.type XUD_UIFM_PortConfig, @function

.cc_top XUD_UIFM_PortConfig.function
XUD_UIFM_PortConfig:
  entsp     16
  stw       r10, sp[1]
  stw       r9, sp[2]
  stw       r8, sp[3]
  stw       r7, sp[4]

//EnableClockBuffers:
  //setc      res[r0], XS1_SETC_BUF_BUFFERS    // Set port to buffered strobed master
  //ldc       r11, 32  				         // Set transfer width to 32 bits
  //settw     res[r0], r11

InvertUsbClock:
  setc      res[r0], XS1_SETC_INV_INVERT
  setc      res[r0], XS1_SETC_COND_NONE

ConfigClockBlock:
  ldc       r10, XS1_CLKBLK_REF               // TODO Don't use clock block 0
  setc      res[r10], XS1_SETC_INUSE_ON
  //setc      res[r10], XS1_SETC_RUN_STOPR
  setclk    res[r10], r0  			              // Clock clockblock from usb clock

DelayFallingEdge:				                      // Delay falling clock block pulse
    ldc      r8, SETCTRL_LMODE_FALL_DELAY
    ldc      r11, SETCTRL_LMODE_SHIFT
    shl      r9, r8, r11
    ldc      r11, SETCTRL_VALUE_SHIFT
    ldc      r7, 1
    shl      r8, r7, r11
    or       r9, r9, r8
    ldc      r8, SETCTRL_MODE_LONG
    ldc      r11, SETCTRL_MODE_SHIFT
    shl      r8, r8, r11
    or       r9, r9, r8
    setc     res[r10], r9

DelayRisingEdge:				                            // Delay rising clock block pulse
    ldc      r8, SETCTRL_LMODE_RISE_DELAY
    ldc      r11, SETCTRL_LMODE_SHIFT
    shl      r9, r8, r11
    ldc      r11, SETCTRL_VALUE_SHIFT
    ldc      r7, 0
    shl      r8, r7, r11
    or       r9, r9, r8
    ldc      r8, SETCTRL_MODE_LONG
    ldc      r11, SETCTRL_MODE_SHIFT
    shl      r8, r8, r11
    or       r9, r9, r8
    setc     res[r10], r9



StartClockBlock:
  setc      res[r10], XS1_SETC_RUN_STARTR

ConfigRegWritePort:                                 // UIFM reg write port
  setc      res[REG_WRITE], XS1_SETC_SDELAY_SDELAY  // Sample on falling edge of clock
  setclk    res[REG_WRITE], r10			                // Clock off USB clock-block
  ldc       r11, 0				                          // Turn port around
  //out       res[REG_WRITE], r11                     // Caused intermittant issues on some boards (caused d+/d- spike on first reg-write on on occations

  setc      res[REG_WRITE], XS1_SETC_BUF_BUFFERS    // Set port to buffered strobed master
  setc      res[REG_WRITE], XS1_SETC_RDY_STROBED
  setc      res[REG_WRITE], XS1_SETC_MS_MASTER
  setc      res[REG_WRITE], XS1_SETC_RUN_CLRBUF

ConfigRegReadPort:                                  // UIFM reg read port
  setc      res[REG_READ], XS1_SETC_SDELAY_SDELAY
  setclk    res[REG_READ], r10

  setc      res[REG_READ], XS1_SETC_BUF_BUFFERS
  setc      res[REG_READ], XS1_SETC_RDY_HANDSHAKE
  setc      res[REG_READ], XS1_SETC_MS_MASTER
  setc      res[REG_READ], XS1_SETC_RUN_CLRBUF

ConfigFlagPort0:                                   	// Config UIFM flag port0
  setc      res[FLAG0], XS1_SETC_SDELAY_SDELAY
  setclk    res[FLAG0], r10
  setc      res[FLAG0], XS1_SETC_RUN_CLRBUF

ConfigFlagPort1:                                   	// Config UIFM flag port1
  ldw       r11, sp[17]                            	// Flag port1: 5th arg
  setc      res[r11], XS1_SETC_SDELAY_SDELAY
  setclk    res[r11], r10
  setc      res[r11], XS1_SETC_RUN_CLRBUF
  setc      res[r11], XS1_SETC_COND_EQ

ConfigFlagPort2:                                   	// Config UIFM flag port2
  ldw       r11, sp[18]                            	// Flag port2: 6th arg
  setc      res[r11], XS1_SETC_SDELAY_SDELAY
  setclk    res[r11], r10
  setc      res[r11], XS1_SETC_RUN_CLRBUF
  setc      res[r11], XS1_SETC_COND_EQ

ConfigureTxDataPort:
  ldw       r11, sp[19]
  setc      res[r11], XS1_SETC_SDELAY_SDELAY
  setclk    res[r11], r10

  ldc       r9, 0					// Turn port around
  out       res[r11], r9

  setc      res[r11], XS1_SETC_BUF_BUFFERS
  ldc       r9, 32  					// Set transfer width to 32 bits
  settw     res[r11], r9
  setc      res[r11], XS1_SETC_RDY_HANDSHAKE		// Set port to handshaken master
  setc      res[r11], XS1_SETC_MS_MASTER

  setc      res[r11], XS1_SETC_RUN_CLRBUF

ConfigureRxDataPort:
  ldw       r11, sp[20]
  setc      res[r11], XS1_SETC_SDELAY_SDELAY

  setc      res[r11], XS1_SETC_BUF_BUFFERS
  ldc       r9, 32
  settw     res[r11], r9                 		// Set transfer width to 32 bits
  setc      res[r11], XS1_SETC_RDY_HANDSHAKE
  setc      res[r11], XS1_SETC_MS_MASTER


  setclk    res[r11], r10
  setc      res[r11], XS1_SETC_RUN_CLRBUF

  ldw       r10, sp[1]
  ldw       r9, sp[2]
  ldw       r8, sp[3]
  ldw       r7, sp[4]
  retsp     16
.size XUD_UIFM_PortConfig,.-XUD_UIFM_PortConfig
.cc_bottom XUD_UIFM_PortConfig.function
.globl XUD_UIFM_PortConfig.nstackwords
.globl XUD_UIFM_PortConfig.maxthreads
.globl XUD_UIFM_PortConfig.maxtimers
.globl XUD_UIFM_PortConfig.maxchanends
.set XUD_UIFM_PortConfig.nstackwords, 16
.set XUD_UIFM_PortConfig.maxchanends, 0
.set XUD_UIFM_PortConfig.maxtimers, 0
.set XUD_UIFM_PortConfig.maxthreads, 0
