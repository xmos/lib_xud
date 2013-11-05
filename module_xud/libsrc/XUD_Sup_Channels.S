/** XUD_Sup_Channels.S
  * @brief     Support functions for using channels
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

/* TODO we can inline all this.  This was before the compliler supported asm() */

.extern XUD_Sup_getd
.globl XUD_Sup_getd.nstackwords
.globl XUD_Sup_getd.maxthreads
.globl XUD_Sup_getd.maxtimers
.globl XUD_Sup_getd.maxchanends

.linkset XUD_Sup_getd.nstackwords, 0
.linkset XUD_Sup_getd.maxchanends, 0
.linkset XUD_Sup_getd.maxtimers, 0
.linkset XUD_Sup_getd.maxthreads, 0

.globl XUD_Sup_getd

.text

XUD_Sup_getd:
  getd     	r0, res[r0]
  retsp  		0

.extern XUD_Sup_GetResourceId
.globl XUD_Sup_GetResourceId.nstackwords

.linkset XUD_Sup_GetResourceId.nstackwords, 0
.text

.global XUD_Sup_GetResourceId
XUD_Sup_GetResourceId:
  retsp       0



//void XUD_Sup_outuint(XUD_chan, unsigned x)
.extern  XUD_Sup_outuint
.globl   XUD_Sup_outuint.nstackwords
.linkset XUD_Sup_outuint.nstackwords, 0
.globl   XUD_Sup_outuint
.text
//unsigned XUD_Sup_inuint(XUD_chan c)
XUD_Sup_outuint:
  out	  res[r0], r1
  retsp   0


//void XUD_Sup_outct(XUD_chan, unsigned char x)
.extern  XUD_Sup_outct
.globl   XUD_Sup_outct.nstackwords
.linkset XUD_Sup_outct.nstackwords, 0
.globl   XUD_Sup_outct
.text
XUD_Sup_outct:
  outct	  res[r0], r1
  retsp 0

//void XUD_Sup_stop_streaming_master(XUD_chan)
.extern  XUD_Sup_stop_streaming_master
.globl   XUD_Sup_stop_streaming_master.nstackwords
.linkset XUD_Sup_stop_streaming_master.nstackwords, 0
.globl   XUD_Sup_stop_streaming_master
.text
XUD_Sup_stop_streaming_master:
  chkct	  res[r0], 1
  outct   res[r0], 1
  retsp 0

.extern  XUD_Sup_inuint
.globl   XUD_Sup_inuint.nstackwords
.linkset XUD_Sup_inuint.nstackwords, 0
.globl   XUD_Sup_inuint
.text
//unsigned XUD_Sup_inuint(XUD_chan c)
XUD_Sup_inuint:
  in	  r0, res[r0]
  retsp 0

.extern  XUD_Sup_int
.globl   XUD_Sup_int.nstackwords
.linkset XUD_Sup_int.nstackwords, 0
.globl   XUD_Sup_int
.text
//unsigned XUD_Sup_inuint(XUD_chan c)
XUD_Sup_int:
  int	  r0, res[r0]
  retsp 0


.extern  XUD_Sup_inct
.globl   XUD_Sup_inct.nstackwords
.linkset XUD_Sup_inct.nstackwords, 0
.globl   XUD_Sup_inct
.text
//unsigned XUD_Sup_inuint(XUD_chan c)
XUD_Sup_inct:
  inct	  r0, res[r0]
  retsp 0


 .extern  XUD_Sup_testct
.globl   XUD_Sup_testct.nstackwords
.linkset XUD_Sup_testct.nstackwords, 0
.globl   XUD_Sup_testct
.text
//unsigned XUD_Sup_test(XUD_chan c)
XUD_Sup_testct:
  testct	  r0, res[r0]
  retsp 0
