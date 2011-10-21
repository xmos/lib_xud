// Similar to functions in ctrlRegisters.S but conforming to the ABI allowing
// use from Xc (see ctrlReg.h)

#include <xs1.h>

// r0 - chanend
// uses r1, r11
// returns header in r0
.globl BuildReturnHeader
BuildReturnHeader:
// put NODE in r1, then shift
  shr r1, r0, XS1_CHAN_ID_NODE_SHIFT
  zext r1, XS1_CHAN_ID_NODE_SIZE
  // now have header | xxx | xxx | NODE |

  // put PROC in r1, then shift
  shr r11, r0, XS1_CHAN_ID_PROCESSOR_SHIFT
  zext r11, XS1_CHAN_ID_PROCESSOR_SIZE
  shl r1, r1, XS1_HEADER_3BYTE_PROCESSOR_SIZE
  or r1, r1, r11
  // now have header | xxx | NODE | PROC |

  // put CHAN in r1, then shift
  shr r11, r0, XS1_CHAN_ID_CHANNUM_SHIFT
  zext r11, XS1_CHAN_ID_CHANNUM_SIZE
  shl r1, r1, XS1_HEADER_3BYTE_CHANNUM_SIZE
  or r1, r1, r11
  // now have header | NODE | PROC | CHAN |
  mov r0, r1
  retsp 0



// r0 - node
// r1 - chanend
// uses r11
// returns address in r0
BuildSSwitchAddressFromChanend:
  shr r1, r1, XS1_CHAN_ID_PROCESSOR_SHIFT
  zext r1, XS1_CHAN_ID_PROCESSOR_SIZE
  ldc r11, 0  // strange magic value - changed to 0 in ctrlRegisters.S
  xor r1, r1, r11
// r0 - node
// r1 - processor
// returns address in r0
buildSSwitchAddress:
  shl r0, r0, XS1_CHAN_ID_NODE_SHIFT
  shl r1, r1, XS1_CHAN_ID_PROCESSOR_SHIFT
  or r0, r0, r1

  ldc r1, XS1_RES_TYPE_CONFIG
  or r0, r0, r1

  ldc r1, XS1_CT_SSCTRL
  shl r1, r1, XS1_CHAN_ID_CHANNUM_SHIFT
  or r0, r0, r1
  retsp 0



// r0 - register
// r1 - value
.globl WritePS_XC0
.globl WritePS_XC0.nstackwords
.linkset WritePS_XC0.nstackwords,0
.align 2
WritePS_XC0:
	mov r11, r0
//  ldc r11, XS1_PS_XCORE_CTRL0
	set ps[r11], r1
	retsp 0

// r0 - register
.globl ReadPS_XC0
.globl ReadPS_XC0.nstackwords
.linkset ReadPS_XC0.nstackwords,0
.align 2
ReadPS_XC0:
	mov r11, r0
//	ldc r11, XS1_PS_XCORE_CTRL0
	get r0, ps[r11]
	retsp 0


// r0 - node
// r1 - register
// r2 - data to write
// returns success in r0
.globl WriteSSCtrlReg
WriteSSCtrlReg:
  entsp 2
  stw r4, sp[1]

  getr r4, XS1_RES_TYPE_CHANEND
  mov r3, r1
  mov r1, r4
  bl BuildSSwitchAddressFromChanend
  setd res[r4], r0
  mov r0, r4
  bl BuildReturnHeader

  ldc r11, XS1_CT_WRITEC                     // Command
  outct res[r4], r11

  shr r11, r0, 16
  outt res[r4], r11                     // Return header: NODE
  shr r11, r0, 8
  outt res[r4], r11                     // Return header: PROC
  outt res[r4], r0                      // Return header: CHAN

  shr r11, r3, 8                        // Register number
  outt res[r4], r11
  outt res[r4], r3

  out res[r4], r2                       // Out data

  outct res[r4], XS1_CT_END                 // End

// Get return message
  inct r0, res [r4]
  ldc r1, XS1_CT_ACK
  eq  r0, r0, r1
  chkct res[r4], XS1_CT_END                 // Consume EOM

  freer res[r4]
  ldw r4, sp[1]
  retsp 2

// r0 - node
// r1 - register
// returns success in r0, value in r1
.globl ReadSSCtrlReg
ReadSSCtrlReg:
  entsp 1

  getr r3, XS1_RES_TYPE_CHANEND
  mov r2, r1
  mov r1, r3
  bl BuildSSwitchAddressFromChanend
  setd res[r3], r0
  mov r0, r3
  bl BuildReturnHeader

  ldc r11, XS1_CT_READC                     // Command
  outct res[r3], r11

  shr r11, r0, 16
  outt res[r3], r11                     // Return header: NODE
  shr r11, r0, 8
  outt res[r3], r11                     // Return header: PROC
  outt res[r3], r0                      // Return header: CHAN

  shr r11, r2, 8                        // Register number
  outt res[r3], r11
  outt res[r3], r2

  outct res[r3], XS1_CT_END                   // End

// Get return message
  inct r0, res [r3]
  ldc r1, XS1_CT_ACK
  eq  r0, r0, r1
  bf  r0, ReadSSCtrlRegReturn
  in r1, res[r3]                        // Get return data

ReadSSCtrlRegReturn:
  chkct res[r3], XS1_CT_END                 // Consume EOM
  freer res[r3]
  retsp 1

