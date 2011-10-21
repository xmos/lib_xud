#include <xs1.h>

.file "glx_periph_reg.S"

///////////////////////////////////////////////////////////////////////////////
//
// glx_periph_adc_inc_data
//
///////////////////////////////////////////////////////////////////////////////

.globl glx_periph_adc_inc_data, "f{ui}(ui)"
.type glx_periph_adc_inc_data, @function
.cc_top glx_periph_adc_inc_data.function, glx_periph_adc_inc_data
.align 2
glx_periph_adc_inc_data:
  ldc     r1, 0x10
  add     r1, r0, r1
  ldc     r2, 0x01f0
  and     r1, r1, r2
  shr     r0, r0, 4
  zext    r0, 4
  or      r0, r1, r0
  retsp   0
.cc_bottom glx_periph_adc_inc_data.function
.globl glx_periph_adc_inc_data.nstackwords
.set glx_periph_adc_inc_data.nstackwords, 0
.globl glx_periph_adc_inc_data.maxthreads
.set glx_periph_adc_inc_data.maxthreads, 1
.globl glx_periph_adc_inc_data.maxtimers
.set glx_periph_adc_inc_data.maxtimers, 0
.globl glx_periph_adc_inc_data.maxchanends
.set glx_periph_adc_inc_data.maxchanends, 0


///////////////////////////////////////////////////////////////////////////////
//
// read_random_seed
//
///////////////////////////////////////////////////////////////////////////////

.globl read_random_seed, "f{si}()"
.type read_random_seed, @function
.cc_top read_random_seed.function, read_random_seed
.align 2
read_random_seed:
  ldc r1, 0x1
  shl r1, r1, 16
  ldc r2, 0xfffc
  add r1, r1, r2
  ldw r0, r1[0]
  retsp 0
.cc_bottom read_random_seed.function
.globl read_random_seed.nstackwords
.set read_random_seed.nstackwords, 0
.globl read_random_seed.maxthreads
.set read_random_seed.maxthreads, 1
.globl read_random_seed.maxtimers
.set read_random_seed.maxtimers, 0
.globl read_random_seed.maxchanends
.set read_random_seed.maxchanends, 0


///////////////////////////////////////////////////////////////////////////////
//
// read_glx_periph_reg
//
///////////////////////////////////////////////////////////////////////////////

.globl read_glx_periph_reg, "f{si}(ui,ui,ui,ui,ui,&(a(:uc)))"
.type read_glx_periph_reg, @function
// r0 - target id
// r1 - peripheral address
// r2 - dest reg address
// r3 - bad packets - (bad_length[24], length[23:16], bad_type[8], bad_token[7:0])
// r4 - data size
// r5 - data start address
.cc_top read_glx_periph_reg.function, read_glx_periph_reg
.align 2
read_glx_periph_reg:
  // Prologue
  entsp 8
  stw r4 , sp [1]
  stw r5 , sp [2]
  stw r6 , sp [3]
  stw r7 , sp [4]
  stw r8 , sp [5]
  stw r9 , sp [6]
  stw r10 , sp [7]

  // get values for r4 and r5
  ldw r4, sp[9]
  ldw r5, sp[10]

  // Check range of target id
  shr r10, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r10, read_glx_periph_reg_fail
  
  // Check range of peripheral id
  shr r10, r1, 3
  bt r10, read_glx_periph_reg_fail
  
  // Allocate channel end
  getr r10, XS1_RES_TYPE_CHANEND
  
  // Set destination from peripheral address in r1 and r0
  // XS1_RES_TYPE_CONFIG | (r1 << XS1_CHAN_ID_CHANNUM_SHIFT)
  shl r1, r1, XS1_CHAN_ID_CHANNUM_SHIFT
  ldc r7, XS1_RES_TYPE_CONFIG
  or r11, r1, r7 // low half of dest id

  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT // top half of dest id
  or r0, r0, r11 // combine to form dest id
  setd res[r10], r0 // transmit dest id

  // Send control token for read access : 0x125
  ldc r6, 0x25 // load token to transmit
  ldc r7, 0x00 // load token number to transmit
  bl  glx_periph_transmit_control_token

  // Send return address
  shr r6, r10, 24 // my id[15:8]
  ldc r7, 0x01    // load token number to transmit
  bl  glx_periph_transmit_data_token
  shr r6, r10, 16 // my id[ 7:0]
  ldc r7, 0x02    // load token number to transmit
  bl  glx_periph_transmit_data_token
  shr r6, r10, 8  // my channel-end
  ldc r7, 0x03    // load token number to transmit
  bl  glx_periph_transmit_data_token
  
  // send destination register address and block size
  mov r6, r2      // send address
  ldc r7, 0x04    // load token number to transmit
  bl  glx_periph_transmit_data_token
  // ldc r4, 1
  mov r6, r4      // send block size
  ldc r7, 0x05    // load token number to transmit
  bl  glx_periph_transmit_data_token

  // send END control token
  ldc r6, XS1_CT_END  // send END control token
  ldc r7, 0x06        // load token number to transmit
  bl  glx_periph_transmit_control_token

  // check if token corruption flag is set
  shr r7, r3, 8
  ldc r8, 0x01
  and r7, r8, r7
  bt r7, read_glx_periph_reg_fail // no response expected
  
  // Receive response
  inct r0, res[r10]
  eq r1, r0, XS1_CT_NACK
  bt r1, read_glx_periph_reg_nack
  eq r1, r0, XS1_CT_ACK
  bf r1, read_glx_periph_reg_fail

  // receive data
read_glx_periph_read_data:
  ldc r8, 0     // zero byte counter

read_glx_periph_read_data_loop:
  int r7, res[r10]  // load one byte
  st8 r7, r5[r8]    // store byte using array address pointer
                    // start address for data to load is r5
  
  add r8, r8, 1     // increment array address pointer
  sub r4, r4, 1     // decrement number of bytes to load
  
  // check if more data to be received
  bt r4, read_glx_periph_read_data_loop // if r4 is non 0 then repeat

read_glx_periph_ct_end:
  ldc r0, 0 // indicates PASS (ACK received)
  chkct res[r10], XS1_CT_END           // check for contrl token END
  bu read_glx_periph_return            // jump to return

read_glx_periph_reg_nack:
  ldc r0, 2                            // indicates FAIL (NACK received)
  chkct res[r10], XS1_CT_END           // check for contrl token END
  bu read_glx_periph_return            // jump to return

read_glx_periph_reg_fail:
  // only used if data/control data corrupted

  // special case - if END token corrupted then send PAUSE token
  //                (PAUSE token not sent to Galaxian, but will free CHANEND)
  ldc r8, 0xff     // check for the byte to be corrupted by...
  and r8, r3, r8   // ...getting byte which has been altered from r3
  eq  r8, r8, 0x06 // only matters if it is byte 6 which has been altered, as this should be the END control token
  bf  r8, read_glx_periph_reg_skip_send_pause // If it was NOT byte 6, do not send PAUSE control token
  outct res[r10], XS1_CT_PAUSE    // send PAUSE token
  
read_glx_periph_reg_skip_send_pause:
  ldc r0, 1 // indicates FAIL
  // bu read_glx_periph_return // implicit

read_glx_periph_return:
// Epilogue
  freer res[r10]                       // free channel end resource
  ldw r4 , sp [1]
  ldw r5 , sp [2]
  ldw r6 , sp [3]
  ldw r7 , sp [4]
  ldw r8 , sp [5]
  ldw r9 , sp [6]
  ldw r10 , sp [7]
  retsp 8

.cc_bottom read_glx_periph_reg.function
.globl read_glx_periph_reg.nstackwords
.set read_glx_periph_reg.nstackwords, 8
.globl read_glx_periph_reg.maxthreads
.set read_glx_periph_reg.maxthreads, 1
.globl read_glx_periph_reg.maxtimers
.set read_glx_periph_reg.maxtimers, 0
.globl read_glx_periph_reg.maxchanends
.set read_glx_periph_reg.maxchanends, 1



///////////////////////////////////////////////////////////////////////////////
//
// write_glx_periph_reg
//
///////////////////////////////////////////////////////////////////////////////

.globl write_glx_periph_reg, "f{si}(ui,ui,ui,ui,ui,&(a(:uc)))"
.type write_glx_periph_reg, @function
// r0 - target id
// r1 - peripheral address
// r2 - dest reg address
// r3 - bad packets - (bad_length[24], length[23:16], bad_type[8], bad_token[7:0])
// r4 - data size
// r5 - data start address
.cc_top write_glx_periph_reg.function, write_glx_periph_reg
.align 2
write_glx_periph_reg:
  // Prologue
  entsp 8
  stw r4 , sp [1]
  stw r5 , sp [2]
  stw r6 , sp [3]
  stw r7 , sp [4]
  stw r8 , sp [5]
  stw r9 , sp [6]
  stw r10 , sp [7]

  // get values for r4 and r5
  ldw r4, sp[9]
  ldw r5, sp[10]

  // Check range of target id
  shr r10, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r10, write_glx_periph_reg_fail
  
  // Check range of peripheral id
  shr r10, r1, 3
  bt r10, write_glx_periph_reg_fail
  
  // Allocate channel end
  getr r10, XS1_RES_TYPE_CHANEND
  
  // Set destination from peripheral address in r1 and r0
  // XS1_RES_TYPE_CONFIG | (r1 << XS1_CHAN_ID_CHANNUM_SHIFT)
  shl r1, r1, XS1_CHAN_ID_CHANNUM_SHIFT
  ldc r7, XS1_RES_TYPE_CONFIG
  or r11, r1, r7 // low half of dest id

  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT // top half of dest id
  or r0, r0, r11 // combine to form dest id
  setd res[r10], r0 // transmit dest id

  // Send control token for write access : 0x124
  ldc r6, 0x24 // load token to transmit
  ldc r7, 0x00 // load token number to transmit
  bl  glx_periph_transmit_control_token

  // Send return address
  shr r6, r10, 24 // my id[15:8]
  ldc r7, 0x01    // load token number to transmit
  bl  glx_periph_transmit_data_token
  shr r6, r10, 16 // my id[ 7:0]
  ldc r7, 0x02    // load token number to transmit
  bl  glx_periph_transmit_data_token
  shr r6, r10, 8  // my channel-end
  ldc r7, 0x03    // load token number to transmit
  bl  glx_periph_transmit_data_token
  
  // send destination register address and block size
  mov r6, r2      // send address
  ldc r7, 0x04    // load token number to transmit
  bl  glx_periph_transmit_data_token

  // If bad_length send incorrect packet length
  shr r7, r3, 24
  bf r7, write_glx_send_block_size
  // get length information out of bad_packet and transmit
  shr r7, r3, 16
  ldc r8, 0xff
  and r6, r7, r8
  ldc r7, 0x05    // load token number to transmit
  bl  glx_periph_transmit_data_token
  bu write_glx_check_data_to_send
write_glx_send_block_size:
  mov r6, r4      // send block size
  ldc r7, 0x05    // load token number to transmit
  bl  glx_periph_transmit_data_token

write_glx_check_data_to_send:
  // check if there is data to send (non zero block access size)
  bf r4, write_glx_periph_send_end // if r4 is 0 then finish

  // send data
  ldc r8, 0     // zero byte counter
  ldc r11, 0x03 // reuse r11 as a mask for 2 lsb's

write_glx_periph_write_data_loop:
  // loop counter is r4 - number of bytes to transmit 
  // start address for data to send is r5
  
  sub r4, r4, 1 // decrement number of bytes to send
  
  and r9, r8, r11                      // check if r8 is modulo 4
  bt  r9,  write_glx_periph_data_ready // if so more data needed
  shr r9, r8, 2                        // divide byte counter by 4 to create array pointer
  ldw r6, r5[r9]                       // load new data using array pointer

write_glx_periph_data_ready:
  add r8, r8, 1     // increment array address pointer
  add r7, r7, 1     // increment bad format token pointer
  bl  glx_periph_transmit_data_token
  shr r6, r6, 8     // move on to next byte
  // check if more data to be sent
  bt r4, write_glx_periph_write_data_loop // if r4 is non 0 then repeat

  // send END control token
write_glx_periph_send_end:
  ldc r6, XS1_CT_END  // send END control token
  add r7, r7, 1       // increment bad format token pointer
  bl  glx_periph_transmit_control_token

  // bad token packets do not get a response
  shr r6, r3, 8
  ldc r8, 0x01
  and r6, r6, r8
  bt r6, write_glx_periph_response_fail

  // bad length packets do not get a response
  shr r6, r3, 24
  bt r6, write_glx_periph_reg_skip_send_pause
  // // bad token packets do not get a response
  // shr r6, r3, 8
  // ldc r8, 0x01
  // and r6, r6, r8
  // bf r6, write_glx_periph_response
  // good packets do get a response
  bu write_glx_periph_response
write_glx_periph_response_fail:
  // only used if data/control data corrupted

  // special case - if END token corrupted then send PAUSE token
  //                (PAUSE token not sent to Galaxian, but will free CHANEND)
  ldc r8, 0xff     // check for the byte to be corrupted by...
  and r8, r3, r8   // ...getting byte which has been altered from r3
  eq  r8, r8, r7   // only matters if it is the last byte which has been altered, as this should be the END control token
  bf  r8, read_glx_periph_reg_skip_send_pause // If it was NOT the last byte, do not send PAUSE control token
  outct res[r10], XS1_CT_PAUSE    // send PAUSE token
  
write_glx_periph_reg_skip_send_pause:
  ldc r0, 1 // indicates FAIL, no NACK
  bu write_glx_periph_return

write_glx_periph_response:

  // Receive response
  inct r0, res[r10]
  eq r1, r0, XS1_CT_NACK
  bt r1, write_glx_periph_reg_nack
  eq r1, r0, XS1_CT_ACK
  bf r1, write_glx_periph_reg_fail
  ldc r0, 0 // indicates PASS (ACK received)
  chkct res[r10], XS1_CT_END
  bu write_glx_periph_return

write_glx_periph_reg_fail:
  ldc r0, 1 // indicates FAIL
  bu write_glx_periph_return

write_glx_periph_reg_nack:
  ldc r0, 2 // indicates FAIL (NACK received)
  chkct res[r10], XS1_CT_END

write_glx_periph_return:
  freer res[r10]
// Epilogue
  ldw r4 , sp [1]
  ldw r5 , sp [2]
  ldw r6 , sp [3]
  ldw r7 , sp [4]
  ldw r8 , sp [5]
  ldw r9 , sp [6]
  ldw r10 , sp [7]
  retsp 8

.cc_bottom write_glx_periph_reg.function
.globl write_glx_periph_reg.nstackwords
.set write_glx_periph_reg.nstackwords, 8
.globl write_glx_periph_reg.maxthreads
.set write_glx_periph_reg.maxthreads, 1
.globl write_glx_periph_reg.maxtimers
.set write_glx_periph_reg.maxtimers, 0
.globl write_glx_periph_reg.maxchanends
.set write_glx_periph_reg.maxchanends, 1

// little routine to send either a data or control token
// data token is the default
// r3 : bad format information
// r6 : token to transmit
// r7 : token number   (saved on stack)
// r8 : scratch        (saved on stack)
// r10 : resource to use
glx_periph_transmit_data_token:
  entsp 3
  stw r7 , sp [1]
  stw r8 , sp [2]
  // check which token to corrupt, send data token if not corrupting
  ldc r8, 0xff
  and r8, r3, r8
  eq  r8, r7, r8
  bf  r8, glx_periph_transmit_data_token_data

  // check if token corruption flag is set
  shr r7, r3, 8
  ldc r8, 0x01
  and r7, r8, r7
  bt r7, glx_periph_transmit_data_token_control
glx_periph_transmit_data_token_data:
  outt res[r10], r6     // send data token (byte) to channel-end
  ldw r7 , sp [1] // return
  ldw r8 , sp [2]
  retsp 3
glx_periph_transmit_data_token_control:
  // avoid reserved control tokens (oxe0 to 0xff) that are trapped for in hardware by...
  // ...clearing the top bit when sending too large data as a control token
  ldc r8, 0xff          // create byte mask
  and r6, r6, r8        // clear all but the bottom byte
  ldc r8, 0xdf          // check for data > 0xdf
  lss r8, r8, r6        // r8 <= 1 iff 0xdf < r6
  shl r8, r8, 7         // r8 bit 8 set if r6 too large
  xor r6, r8, r6        // clears bit 8 if r6 was too large
  outct res[r10], r6    // send control token (byte) to channel-end

// return
  ldw r7 , sp [1]
  ldw r8 , sp [2]
  retsp 3


// little routine to send either a data or control token
// control token is the default
// r3 : bad format information
// r6 : token to transmit
// r7 : token number   (saved on stack)
// r8 : scratch        (saved on stack)
// r10 : resource to use
glx_periph_transmit_control_token:
  entsp 3
  stw r7 , sp [1]
  stw r8 , sp [2]
  // check which token to corrupt, send control token if not corrupting
  ldc r8, 0xff
  and r8, r3, r8
  eq  r8, r7, r8
  bf  r8, glx_periph_transmit_control_token_control

  // check if token corruption flag is set
  shr r7, r3, 8
  ldc r8, 0x01
  and r7, r8, r7
  bt r7, glx_periph_transmit_control_token_data
glx_periph_transmit_control_token_control:
  outct res[r10], r6    // send control token (byte) to channel-end
  ldw r7 , sp [1] // return
  ldw r8 , sp [2]
  retsp 3
glx_periph_transmit_control_token_data:
  outt res[r10], r6     // send data token (byte) to channel-end
  ldw r7 , sp [1] // return
  ldw r8 , sp [2]
  retsp 3

///////////////////////////////////////////////////////////////////////////////
//
// read_glx_periph_word
//
///////////////////////////////////////////////////////////////////////////////

.globl read_glx_periph_word, "f{si}(ui,ui,ui,&(ui))"
.type read_glx_periph_word, @function
// r0 - target id
// r1 - peripheral address
// r2 - dest reg address
// r3 - data word pointer
.cc_top read_glx_periph_word.function, read_glx_periph_word
.align 2
read_glx_periph_word:
  // Prologue
  entsp 3
  stw r6 , sp [1]
  stw r10 , sp [2]

  // Check range of target id
  shr r10, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r10, read_glx_periph_word_fail
  
  // Check range of peripheral id
  shr r10, r1, 3
  bt r10, read_glx_periph_word_fail
  
  // Allocate channel end
  getr r10, XS1_RES_TYPE_CHANEND
  
  // Set destination from peripheral address in r1 and r0
  // XS1_RES_TYPE_CONFIG | (r1 << XS1_CHAN_ID_CHANNUM_SHIFT)
  shl r1, r1, XS1_CHAN_ID_CHANNUM_SHIFT
  ldc r6, XS1_RES_TYPE_CONFIG
  or r11, r1, r6 // low half of dest id

  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT // top half of dest id
  or r0, r0, r11 // combine to form dest id
  setd res[r10], r0 // transmit dest id

  // Send control token for read access : 0x125
  ldc   r6, 0x25
  outct res[r10], r6

  // Send return address
  shr r6, r10, 24 // my id[15:8]
  outt res[r10], r6

  shr r6, r10, 16 // my id[ 7:0]
  outt res[r10], r6

  shr r6, r10, 8  // my channel-end
  outt res[r10], r6
  
  // send destination register address and block size
  outt res[r10], r2
  ldc   r6, 0x04
  outt res[r10], r6

  // send END control token
  ldc r6, XS1_CT_END  // send END control token
  outct res[r10], r6

  // Receive response
  inct r0, res[r10]
  eq r1, r0, XS1_CT_NACK
  bt r1, read_glx_periph_word_nack

  // receive data
  in r6, res[r10]  // load one word
  stw r6, r3[0] 

  ldc r0, 0 // indicates PASS (ACK received)
  chkct res[r10], XS1_CT_END           // check for contrl token END
  bu read_glx_periph_word_freer            // jump to return

read_glx_periph_word_nack:
  ldc r0, 2                            // indicates FAIL (NACK received)
  chkct res[r10], XS1_CT_END           // check for contrl token END
  bu read_glx_periph_word_freer

read_glx_periph_word_fail:
  ldc r0, 1                            // indicates FAIL - never got a CHANEND
  bu read_glx_periph_word_return

read_glx_periph_word_freer:
// Epilogue
  freer res[r10]                       // free channel end resource
read_glx_periph_word_return:

  ldw r6 , sp [1]
  ldw r10 , sp [2]
  retsp 3

.cc_bottom read_glx_periph_word.function
.globl read_glx_periph_word.nstackwords
.set read_glx_periph_word.nstackwords, 3
.globl read_glx_periph_word.maxthreads
.set read_glx_periph_word.maxthreads, 1
.globl read_glx_periph_word.maxtimers
.set read_glx_periph_word.maxtimers, 0
.globl read_glx_periph_word.maxchanends
.set read_glx_periph_word.maxchanends, 1


///////////////////////////////////////////////////////////////////////////////
//
// write_glx_periph_word
//
///////////////////////////////////////////////////////////////////////////////

.globl write_glx_periph_word, "f{si}(ui,ui,ui,ui)"
.type write_glx_periph_word, @function
// r0 - target id
// r1 - peripheral address
// r2 - dest reg address
// r3 - data word
.cc_top write_glx_periph_word.function, write_glx_periph_word
.align 2
write_glx_periph_word:
  // Prologue
  entsp 3
  stw r6 , sp [1]
  stw r10 , sp [2]

  // Check range of target id
  shr r10, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r10, write_glx_periph_word_fail
  
  // Check range of peripheral id
  shr r10, r1, 3
  bt r10, write_glx_periph_word_fail
  
  // Allocate channel end
  getr r10, XS1_RES_TYPE_CHANEND
  
  // Set destination from peripheral address in r1 and r0
  // XS1_RES_TYPE_CONFIG | (r1 << XS1_CHAN_ID_CHANNUM_SHIFT)
  shl r1, r1, XS1_CHAN_ID_CHANNUM_SHIFT
  ldc r6, XS1_RES_TYPE_CONFIG
  or r11, r1, r6 // low half of dest id

  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT // top half of dest id
  or r0, r0, r11 // combine to form dest id
  setd res[r10], r0 // transmit dest id

  // Send control token for write access : 0x124
  ldc r6, 0x24 // load token to transmit
  outct res[r10], r6

  // Send return address
  shr r6, r10, 24 // my id[15:8]
  outt res[r10], r6
  shr r6, r10, 16 // my id[ 7:0]
  outt res[r10], r6
  shr r6, r10, 8  // my channel-end
  outt res[r10], r6
  
  // send destination register address and block size
  mov r6, r2      // send address
  outt res[r10], r6
  ldc r6, 0x04    // send block size
  outt res[r10], r6

  // send data
  out res[r10], r3

  // send END control token
  ldc r6, XS1_CT_END  // send END control token
  outct res[r10], r6

  // Receive response
  inct r0, res[r10]
  eq r1, r0, XS1_CT_ACK
  bf r1, write_glx_periph_word_nack

  ldc r0, 0 // indicates PASS (ACK received)
  chkct res[r10], XS1_CT_END
  bu write_glx_periph_word_freer

write_glx_periph_word_fail:
  ldc r0, 1 // indicates FAIL
  bu write_glx_periph_word_return

write_glx_periph_word_nack:
  ldc r0, 2 // indicates FAIL (NACK received)
  chkct res[r10], XS1_CT_END

write_glx_periph_word_freer:
  freer res[r10]
write_glx_periph_word_return:
// Epilogue
  ldw r6 , sp [1]
  ldw r10 , sp [2]
  retsp 3

.cc_bottom write_glx_periph_word.function
.globl write_glx_periph_word.nstackwords
.set write_glx_periph_word.nstackwords, 3
.globl write_glx_periph_word.maxthreads
.set write_glx_periph_word.maxthreads, 1
.globl write_glx_periph_word.maxtimers
.set write_glx_periph_word.maxtimers, 0
.globl write_glx_periph_word.maxchanends
.set write_glx_periph_word.maxchanends, 1

///////////////////////////////////////////////////////////////////////////////
//
// write_glx_periph_word_noresp
//
///////////////////////////////////////////////////////////////////////////////

.globl write_glx_periph_word_noresp, "f{si}(ui,ui,ui,ui)"
.type write_glx_periph_word_noresp, @function
// r0 - target id
// r1 - peripheral address
// r2 - dest reg address
// r3 - data word
.cc_top write_glx_periph_word_noresp.function, write_glx_periph_word_noresp
.align 2
write_glx_periph_word_noresp:
  // Prologue
  entsp 3
  stw r6 , sp [1]
  stw r10 , sp [2]

  // Check range of target id
  shr r10, r0, XS1_CHAN_ID_PROCESSOR_SIZE + XS1_CHAN_ID_NODE_SIZE
  bt r10, write_glx_periph_word_noresp_fail
  
  // Check range of peripheral id
  shr r10, r1, 3
  bt r10, write_glx_periph_word_noresp_fail
  
  // Allocate channel end
  getr r10, XS1_RES_TYPE_CHANEND
  
  // Set destination from peripheral address in r1 and r0
  // XS1_RES_TYPE_CONFIG | (r1 << XS1_CHAN_ID_CHANNUM_SHIFT)
  shl r1, r1, XS1_CHAN_ID_CHANNUM_SHIFT
  ldc r6, XS1_RES_TYPE_CONFIG
  or r11, r1, r6 // low half of dest id

  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT // top half of dest id
  or r0, r0, r11 // combine to form dest id
  setd res[r10], r0 // transmit dest id

  // Send control token for write access : 0x124
  ldc r6, 0x24 // load token to transmit
  outct res[r10], r6

  // Send return address
  shr r6, r10, 24 // my id[15:8]
  outt res[r10], r6
  shr r6, r10, 16 // my id[ 7:0]
  outt res[r10], r6
  ldc r6, 0xff // no response
  outt res[r10], r6
  
  // send destination register address and block size
  mov r6, r2      // send address
  outt res[r10], r6
  ldc r6, 0x04    // send block size
  outt res[r10], r6

  // send data
  out res[r10], r3

  // send END control token
  ldc r6, XS1_CT_END  // send END control token
  outct res[r10], r6

  ldc r0, 0 // indicates PASS
  bu write_glx_periph_word_noresp_freer

write_glx_periph_word_noresp_fail:
  ldc r0, 1 // indicates FAIL
  bu write_glx_periph_word_noresp_return

write_glx_periph_word_noresp_freer:
  freer res[r10]
write_glx_periph_word_noresp_return:
// Epilogue
  ldw r6 , sp [1]
  ldw r10 , sp [2]
  retsp 3

.cc_bottom write_glx_periph_word_noresp.function
.globl write_glx_periph_word_noresp.nstackwords
.set write_glx_periph_word_noresp.nstackwords, 3
.globl write_glx_periph_word_noresp.maxthreads
.set write_glx_periph_word_noresp.maxthreads, 1
.globl write_glx_periph_word_noresp.maxtimers
.set write_glx_periph_word_noresp.maxtimers, 0
.globl write_glx_periph_word_noresp.maxchanends
.set write_glx_periph_word_noresp.maxchanends, 1

///////////////////////////////////////////////////////////////////////////////
//
// read_glx_periph_request
//
// Performs the glx periph read request, but does not input any read data
//
///////////////////////////////////////////////////////////////////////////////

.globl read_glx_periph_request, "f{ui}(ui,ui,ui,ui)"
.type read_glx_periph_request, @function
// r0 - target id
// r1 - peripheral address
// r2 - dest reg address
// r3 - data size
.cc_top read_glx_periph_request.function, read_glx_periph_request
.align 2
read_glx_periph_request:
  // Prologue
  entsp 8
  stw r4 , sp [1]
  stw r5 , sp [2]
  stw r6 , sp [3]
  stw r7 , sp [4]
  stw r8 , sp [5]
  stw r9 , sp [6]
  stw r10 , sp [7]

  // Allocate channel end
  getr r10, XS1_RES_TYPE_CHANEND
  
  // Set destination from peripheral address in r1 and r0
  // XS1_RES_TYPE_CONFIG | (r1 << XS1_CHAN_ID_CHANNUM_SHIFT)
  shl r1, r1, XS1_CHAN_ID_CHANNUM_SHIFT
  ldc r7, XS1_RES_TYPE_CONFIG
  or r11, r1, r7 // low half of dest id

  shl r0, r0, XS1_CHAN_ID_PROCESSOR_SHIFT // top half of dest id
  or r0, r0, r11 // combine to form dest id
  setd res[r10], r0 // transmit dest id

  // Send control token for read access : 0x125
  ldc r6, 0x25 // load token to transmit
  outct res[r10], r6
  

  // Send return address
  shr r6, r10, 24 // my id[15:8]
  outt res[r10], r6
  shr r6, r10, 16 // my id[ 7:0]
  outt res[r10], r6
  shr r6, r10, 8  // my channel-end
  outt res[r10], r6
  
  // send destination register address
  outt res[r10], r2
  //  and block size
  outt res[r10], r3

  // send END control token
  ldc r6, XS1_CT_END  // send END control token
  outct res[r10], r6

// Epilogue
  mov r0, r10         // Return the chanendID
  ldw r4 , sp [1]
  ldw r5 , sp [2]
  ldw r6 , sp [3]
  ldw r7 , sp [4]
  ldw r8 , sp [5]
  ldw r9 , sp [6]
  ldw r10 , sp [7]
  retsp 8

.cc_bottom read_glx_periph_request.function
.globl read_glx_periph_request.nstackwords
.set read_glx_periph_request.nstackwords, 8
.globl read_glx_periph_request.maxthreads
.set read_glx_periph_request.maxthreads, 1
.globl read_glx_periph_request.maxtimers
.set read_glx_periph_request.maxtimers, 0
.globl read_glx_periph_request.maxchanends
.set read_glx_periph_request.maxchanends, 1
