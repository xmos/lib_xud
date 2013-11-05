#include <xs1.h>

//--------------------------------------------------------------------------------------------------
// write_sswitch_reg_noresp: as for write_sswitch_reg but places 0xff into return channel id
// and the source Nodeid as the return node to ensure no response is received for the write request
//--------------------------------------------------------------------------------------------------
.globl write_sswitch_reg_noresp, "f{si}(ui,ui,ui)"
.type read_sswitch_reg, @function
// r0 - coreid
// r1 - reg
// r2 - data
.cc_top write_sswitch_reg_noresp.function, write_sswitch_reg_noresp
.align 2
write_sswitch_reg_noresp:
  // Check range of coreid
  shr r3, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r3, write_switch_reg_noresp_fail

  // Check range of reg
  shr r3, r1, 16
  bt r3, write_switch_reg_noresp_fail

  // Allocate channel end
  getr r3, XS1_RES_TYPE_CHANEND

  // Set destination
  ldc r11, XS1_RES_TYPE_CONFIG | (XS1_CT_SSCTRL << XS1_CHAN_ID_CHANNUM_SHIFT)
  bu write_switch_reg_noresp
.cc_bottom write_sswitch_reg_noresp.function
.globl write_sswitch_reg_noresp.nstackwords
.set write_sswitch_reg_noresp.nstackwords, 0
.globl write_sswitch_reg_noresp.maxthreads
.set write_sswitch_reg_noresp.maxthreads, 1
.globl write_sswitch_reg_noresp.maxtimers
.set write_sswitch_reg_noresp.maxtimers, 0
.globl write_sswitch_reg_noresp.maxchanends
.set write_sswitch_reg_noresp.maxchanends, 1



// r0 - l
// r1 - reg
// r2 - data
// r3 - chanend
// r11 - low half of dest
write_switch_reg_noresp:
  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT
  or r0, r0, r11
  setd res[r3], r0

  // Send packet
  ldc r11, XS1_CT_WRITEC // Too big for outct immediate
  outct res[r3], r11
  // No ack, so set return chanEnd on this node, chanend FF
  // NodeID in [31:16]
  ldc r11, 0xffff
  shl r11, r11, 16
  and r11, r3, r11 // get the nodeID from r3
  // dummy chanEnd 0xff in [15:8]
  ldc r0, 0xff
  shl r0, r0, 8
  or r0, r0, r11
  // Put the regaddr[15:8] into [7:0]
  shr r11, r1, 8
  or r0, r0, r11
  out res[r3], r0 // (c & 0xffffff00) | (reg >> 8)
  // regaddr [7:0]
  outt res[r3], r1 // reg & 0xff
  out res[r3], r2
  outct res[r3], XS1_CT_END

  freer res[r3]
  retsp 0
write_switch_reg_noresp_fail:
  ldc r0, 0
  retsp 0


//--------------------------------------------------------------------------------------------------
// write_sswitch_reg_nodeid_noresp: as for write_sswitch_reg but places 0xff into return channel id
// and the source Nodeid as the return node to ensure no response is received for the write request
//--------------------------------------------------------------------------------------------------
.globl write_sswitch_reg_nodeid_noresp, "f{si}(ui,ui,ui)"
.type read_sswitch_reg, @function
// r0 - coreid
// r1 - reg
// r2 - data
.cc_top write_sswitch_reg_nodeid_noresp.function, write_sswitch_reg_nodeid_noresp
.align 2
write_sswitch_reg_nodeid_noresp:
  // Check range of coreid
  shr r3, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r3, write_switch_reg_nodeid_noresp_fail

  // Check range of reg
  shr r3, r1, 16
  bt r3, write_switch_reg_nodeid_noresp_fail

  // Allocate channel end
  getr r3, XS1_RES_TYPE_CHANEND

  // Set destination
  ldc r11, XS1_RES_TYPE_CONFIG | (XS1_CT_SSCTRL << XS1_CHAN_ID_CHANNUM_SHIFT)
  bu write_switch_reg_nodeid_noresp
.cc_bottom write_sswitch_reg_nodeid_noresp.function
.globl write_sswitch_reg_nodeid_noresp.nstackwords
.set write_sswitch_reg_nodeid_noresp.nstackwords, 0
.globl write_sswitch_reg_nodeid_noresp.maxthreads
.set write_sswitch_reg_nodeid_noresp.maxthreads, 1
.globl write_sswitch_reg_nodeid_noresp.maxtimers
.set write_sswitch_reg_nodeid_noresp.maxtimers, 0
.globl write_sswitch_reg_nodeid_noresp.maxchanends
.set write_sswitch_reg_nodeid_noresp.maxchanends, 1



// r0 - l
// r1 - reg
// r2 - data
// r3 - chanend
// r11 - low half of dest
write_switch_reg_nodeid_noresp:
  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT
  or r0, r0, r11
  setd res[r3], r0

  // Send packet
  ldc r11, XS1_CT_WRITEC // Too big for outct immediate
  outct res[r3], r11
  // To avoid sending the ack (to be junked) to another node
  // set the return node to be the new nodeId
  // NodeID in [15:0]
  shl r11, r2, 16
  and r11, r3, r11 // get the nodeID from r3
  // dummy chanEnd 0xff in [15:8]
  ldc r0, 0xff
  shl r0, r0, 8
  or r0, r0, r11
  // Put the regaddr[15:8] into [7:0]
  shr r11, r1, 8
  or r0, r0, r11
  out res[r3], r0 // (c & 0xffffff00) | (reg >> 8)
  // regaddr [7:0]
  outt res[r3], r1 // reg & 0xff
  out res[r3], r2
  outct res[r3], XS1_CT_END

  freer res[r3]
  retsp 0
write_switch_reg_nodeid_noresp_fail:
  ldc r0, 0
  retsp 0


//--------------------------------------------------------------------------------------------------
// as for write_sswitch_reg, but doesn't bother checking for a response.
// use this when you wish to test that galaxian doesn't send a response
//--------------------------------------------------------------------------------------------------
.globl write_sswitch_reg_skipresp, "f{si}(ui,ui,ui)"
.type read_sswitch_reg, @function
// r0 - coreid
// r1 - reg
// r2 - data
.cc_top write_sswitch_reg_skipresp.function, write_sswitch_reg_skipresp
.align 2
write_sswitch_reg_skipresp:
  // Check range of coreid
  shr r3, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r3, write_switch_reg_skipresp_fail

  // Check range of reg
  shr r3, r1, 16
  bt r3, write_switch_reg_skipresp_fail

  // Allocate channel end
  getr r3, XS1_RES_TYPE_CHANEND

  // Set destination
  ldc r11, XS1_RES_TYPE_CONFIG | (XS1_CT_SSCTRL << XS1_CHAN_ID_CHANNUM_SHIFT)
  bu write_switch_reg_skipresp
.cc_bottom write_sswitch_reg_skipresp.function
.globl write_sswitch_reg_skipresp.nstackwords
.set write_sswitch_reg_skipresp.nstackwords, 0
.globl write_sswitch_reg_skipresp.maxthreads
.set write_sswitch_reg_skipresp.maxthreads, 1
.globl write_sswitch_reg_skipresp.maxtimers
.set write_sswitch_reg_skipresp.maxtimers, 0
.globl write_sswitch_reg_skipresp.maxchanends
.set write_sswitch_reg_skipresp.maxchanends, 1



// r0 - l
// r1 - reg
// r2 - data
// r3 - chanend
// r11 - low half of dest
write_switch_reg_skipresp:
  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT
  or r0, r0, r11
  setd res[r3], r0

  // Send packet
  ldc r11, XS1_CT_WRITEC // Too big for outct immediate
  outct res[r3], r11
  shr r0, r3, 8
  shl r0, r0, 8
  shr r11, r1, 8
  or r0, r0, r11
  out res[r3], r0 // (c & 0xffffff00) | (reg >> 8)
  outt res[r3], r1 // reg & 0xff
  out res[r3], r2
  outct res[r3], XS1_CT_END

  freer res[r3]
  retsp 0

write_switch_reg_skipresp_fail:
  ldc r0, 0
  retsp 0
//--------------------------------------------------------------------------------------------------
// as for write_sswitch_reg but expects a NACK rather than ACK. Use for situations when
// attempting to deliberately cause an invalid ssctrl access you expect to be nacked
//--------------------------------------------------------------------------------------------------


.globl write_sswitch_reg_nackresp, "f{si}(ui,ui,ui)"
.type read_sswitch_reg, @function
// r0 - coreid
// r1 - reg
// r2 - data
.cc_top write_sswitch_reg_nackresp.function, write_sswitch_reg_nackresp
.align 2
write_sswitch_reg_nackresp:
  // Check range of coreid
  shr r3, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r3, write_switch_reg_nackresp_fail

  // Check range of reg
  shr r3, r1, 16
  bt r3, write_switch_reg_nackresp_fail

  // Allocate channel end
  getr r3, XS1_RES_TYPE_CHANEND

  // Set destination
  ldc r11, XS1_RES_TYPE_CONFIG | (XS1_CT_SSCTRL << XS1_CHAN_ID_CHANNUM_SHIFT)
  bu write_switch_reg_nackresp
.cc_bottom write_sswitch_reg_nackresp.function
.globl write_sswitch_reg_nackresp.nstackwords
.set write_sswitch_reg_nackresp.nstackwords, 0
.globl write_sswitch_reg_nackresp.maxthreads
.set write_sswitch_reg_nackresp.maxthreads, 1
.globl write_sswitch_reg_nackresp.maxtimers
.set write_sswitch_reg_nackresp.maxtimers, 0
.globl write_sswitch_reg_nackresp.maxchanends
.set write_sswitch_reg_nackresp.maxchanends, 1



// r0 - l
// r1 - reg
// r2 - data
// r3 - chanend
// r11 - low half of dest
write_switch_reg_nackresp:
  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT
  or r0, r0, r11
  setd res[r3], r0

  // Send packet
  ldc r11, XS1_CT_WRITEC // Too big for outct immediate
  outct res[r3], r11
  shr r0, r3, 8
  shl r0, r0, 8
  shr r11, r1, 8
  or r0, r0, r11
  out res[r3], r0 // (c & 0xffffff00) | (reg >> 8)
  outt res[r3], r1 // reg & 0xff
  out res[r3], r2
  outct res[r3], XS1_CT_END


  // Receive response
  inct r0, res[r3]
  eq r0, r0, XS1_CT_NACK
  chkct res[r3], XS1_CT_END
  freer res[r3]
  retsp 0

write_switch_reg_nackresp_fail:
  ldc r0, 0
  retsp 0

