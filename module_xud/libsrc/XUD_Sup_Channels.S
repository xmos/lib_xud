/** XUD_Sup_Channels.S
  * @brief     Support functions for using channels
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

/* TODO we can inline all this.  This was before the compliler supported asm() */

.globl XUD_Sup_getd
.type XUD_Sup_getd, @function
.text
.cc_top XUD_Sup_getd.function
.align 2
XUD_Sup_getd:
  getd     	r0, res[r0]
  retsp  		0
.size XUD_Sup_getd, .-XUD_Sup_getd
.cc_bottom XUD_Sup_getd.function
.globl XUD_Sup_getd.nstackwords
.globl XUD_Sup_getd.maxcores
.globl XUD_Sup_getd.maxtimers
.globl XUD_Sup_getd.maxchanends
.set XUD_Sup_getd.nstackwords, 0
.set XUD_Sup_getd.maxchanends, 0
.set XUD_Sup_getd.maxtimers, 0
.set XUD_Sup_getd.maxcores, 1


.globl XUD_Sup_GetResourceId
.type XUD_Sup_GetResourceId, @function
.text
.cc_top XUD_Sup_GetResourceId.function
.align 2
XUD_Sup_GetResourceId:
  retsp       0
.size XUD_Sup_GetResourceId, .-XUD_Sup_GetResourceId
.cc_bottom XUD_Sup_GetResourceId.function
.globl XUD_Sup_GetResourceId.nstackwords
.globl XUD_Sup_GetResourceId.maxcores
.globl XUD_Sup_GetResourceId.maxtimers
.globl XUD_Sup_GetResourceId.maxchanends
.set XUD_Sup_GetResourceId.nstackwords, 0
.set XUD_Sup_GetResourceId.maxchanends, 0
.set XUD_Sup_GetResourceId.maxtimers, 0
.set XUD_Sup_GetResourceId.maxcores, 1


//void XUD_Sup_outuint(XUD_chan, unsigned x)
.globl XUD_Sup_outuint
.type XUD_Sup_outuint, @function
.text
.cc_top XUD_Sup_outuint.function
.align 2
//unsigned XUD_Sup_inuint(XUD_chan c)
XUD_Sup_outuint:
  out	  res[r0], r1
  retsp   0
.size XUD_Sup_outuint, .-XUD_Sup_outuint
.cc_bottom XUD_Sup_outuint.function
.globl XUD_Sup_outuint.nstackwords
.globl XUD_Sup_outuint.maxcores
.globl XUD_Sup_outuint.maxtimers
.globl XUD_Sup_outuint.maxchanends
.set XUD_Sup_outuint.nstackwords, 0
.set XUD_Sup_outuint.maxchanends, 0
.set XUD_Sup_outuint.maxtimers, 0
.set XUD_Sup_outuint.maxcores, 1


//void XUD_Sup_outct(XUD_chan, unsigned char x)
.globl XUD_Sup_outct
.type XUD_Sup_outct, @function
.text
.cc_top XUD_Sup_outct.function
.align 2
XUD_Sup_outct:
  outct	  res[r0], r1
  retsp 0
.size XUD_Sup_outct, .-XUD_Sup_outct
.cc_bottom XUD_Sup_outct.function
.globl XUD_Sup_outct.nstackwords
.globl XUD_Sup_outct.maxcores
.globl XUD_Sup_outct.maxtimers
.globl XUD_Sup_outct.maxchanends
.set XUD_Sup_outct.nstackwords, 0
.set XUD_Sup_outct.maxchanends, 0
.set XUD_Sup_outct.maxtimers, 0
.set XUD_Sup_outct.maxcores, 1

//void XUD_Sup_stop_streaming_master(XUD_chan)
.globl XUD_Sup_stop_streaming_master
.type XUD_Sup_stop_streaming_master, @function
.text
.cc_top XUD_Sup_stop_streaming_master.function
.align 2
XUD_Sup_stop_streaming_master:
  chkct	  res[r0], 1
  outct   res[r0], 1
  retsp 0
.size XUD_Sup_stop_streaming_master, .-XUD_Sup_stop_streaming_master
.cc_bottom XUD_Sup_stop_streaming_master.function
.globl XUD_Sup_stop_streaming_master.nstackwords
.globl XUD_Sup_stop_streaming_master.maxcores
.globl XUD_Sup_stop_streaming_master.maxtimers
.globl XUD_Sup_stop_streaming_master.maxchanends
.set XUD_Sup_stop_streaming_master.nstackwords, 0
.set XUD_Sup_stop_streaming_master.maxchanends, 0
.set XUD_Sup_stop_streaming_master.maxtimers, 0
.set XUD_Sup_stop_streaming_master.maxcores, 1

//unsigned XUD_Sup_inuint(XUD_chan c)
.globl XUD_Sup_inuint
.type XUD_Sup_inuint, @function
.text
.cc_top XUD_Sup_inuint.function
.align 2
XUD_Sup_inuint:
  in	  r0, res[r0]
  retsp 0
.size XUD_Sup_inuint, .-XUD_Sup_inuint
.cc_bottom XUD_Sup_inuint.function
.globl XUD_Sup_inuint.nstackwords
.globl XUD_Sup_inuint.maxcores
.globl XUD_Sup_inuint.maxtimers
.globl XUD_Sup_inuint.maxchanends
.set XUD_Sup_inuint.nstackwords, 0
.set XUD_Sup_inuint.maxchanends, 0
.set XUD_Sup_inuint.maxtimers, 0
.set XUD_Sup_inuint.maxcores, 1

//unsigned XUD_Sup_inuint(XUD_chan c)
.globl XUD_Sup_int
.type XUD_Sup_int, @function
.text
.cc_top XUD_Sup_int.function
.align 2
XUD_Sup_int:
  int	  r0, res[r0]
  retsp 0
.size XUD_Sup_int, .-XUD_Sup_int
.cc_bottom XUD_Sup_int.function
.globl XUD_Sup_int.nstackwords
.globl XUD_Sup_int.maxcores
.globl XUD_Sup_int.maxtimers
.globl XUD_Sup_int.maxchanends
.set XUD_Sup_int.nstackwords, 0
.set XUD_Sup_int.maxchanends, 0
.set XUD_Sup_int.maxtimers, 0
.set XUD_Sup_int.maxcores, 1

//unsigned XUD_Sup_inuint(XUD_chan c)
.globl XUD_Sup_inct
.type XUD_Sup_inct, @function
.text
.cc_top XUD_Sup_inct.function
.align 2
XUD_Sup_inct:
  inct	  r0, res[r0]
  retsp 0
.size XUD_Sup_inct, .-XUD_Sup_inct
.cc_bottom XUD_Sup_inct.function
.globl XUD_Sup_inct.nstackwords
.globl XUD_Sup_inct.maxcores
.globl XUD_Sup_inct.maxtimers
.globl XUD_Sup_inct.maxchanends
.set XUD_Sup_inct.nstackwords, 0
.set XUD_Sup_inct.maxchanends, 0
.set XUD_Sup_inct.maxtimers, 0
.set XUD_Sup_inct.maxcores, 1

//unsigned XUD_Sup_test(XUD_chan c)
.globl XUD_Sup_testct
.type XUD_Sup_testct, @function
.text
.cc_top XUD_Sup_testct.function
.align 2
XUD_Sup_testct:
  testct	  r0, res[r0]
  retsp 0
.size XUD_Sup_testct, .-XUD_Sup_testct
.cc_bottom XUD_Sup_testct.function
.globl XUD_Sup_testct.nstackwords
.globl XUD_Sup_testct.maxcores
.globl XUD_Sup_testct.maxtimers
.globl XUD_Sup_testct.maxchanends
.set XUD_Sup_testct.nstackwords, 0
.set XUD_Sup_testct.maxchanends, 0
.set XUD_Sup_testct.maxtimers, 0
.set XUD_Sup_testct.maxcores, 1
