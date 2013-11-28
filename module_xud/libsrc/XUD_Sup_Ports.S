/** XUD_Sup_Ports.S
  * @brief     Support functions for using ports
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

.globl XUD_Sup_Outpw8
.type XUD_Sup_Outpw8, @function

.text

.cc_top XUD_Sup_Outpw8.function
.align 2
XUD_Sup_Outpw8:
  outpw     res[r0], r1, 8
  retsp  0
.size XUD_Sup_Outpw8, .-XUD_Sup_Outpw8
.cc_bottom XUD_Sup_Outpw8.function
.globl XUD_Sup_Outpw8.nstackwords
.globl XUD_Sup_Outpw8.maxthreads
.globl XUD_Sup_Outpw8.maxtimers
.globl XUD_Sup_Outpw8.maxchanends
.set XUD_Sup_Outpw8.nstackwords, 0
.set XUD_Sup_Outpw8.maxchanends, 0
.set XUD_Sup_Outpw8.maxtimers, 0
.set XUD_Sup_Outpw8.maxthreads, 1

.globl XUD_Sup_Outpw16
.type XUD_Sup_Outpw16, @function

.text

.cc_top XUD_Sup_Outpw16.function
.align 2
XUD_Sup_Outpw16:
  outpw  	res[r0], r1, 16
  retsp 0
.size XUD_Sup_Outpw16, .-XUD_Sup_Outpw16
.cc_bottom XUD_Sup_Outpw16.function
.globl XUD_Sup_Outpw16.nstackwords
.globl XUD_Sup_Outpw16.maxthreads
.globl XUD_Sup_Outpw16.maxtimers
.globl XUD_Sup_Outpw16.maxchanends
.set XUD_Sup_Outpw16.nstackwords, 0
.set XUD_Sup_Outpw16.maxchanends, 0
.set XUD_Sup_Outpw16.maxtimers, 0
.set XUD_Sup_Outpw16.maxthreads, 1

.globl XUD_Sup_Outpw24
.type XUD_Sup_Outpw24, @function

.text

.cc_top XUD_Sup_Outpw24.function
.align 2
XUD_Sup_Outpw24:
  outpw  	res[r0], r1, 24
  retsp 0
.size XUD_Sup_Outpw24, .-XUD_Sup_Outpw24
.cc_bottom XUD_Sup_Outpw24.function
.globl XUD_Sup_Outpw24.nstackwords
.globl XUD_Sup_Outpw24.maxthreads
.globl XUD_Sup_Outpw24.maxtimers
.globl XUD_Sup_Outpw24.maxchanends
.set XUD_Sup_Outpw24.nstackwords, 0
.set XUD_Sup_Outpw24.maxchanends, 0
.set XUD_Sup_Outpw24.maxtimers, 0
.set XUD_Sup_Outpw24.maxthreads, 1

// XUD_Sup_Inpw24.S


.globl XUD_Sup_Inpw24
.type XUD_Sup_Inpw24, @function

.text

//unsigned XUD_Sup_Inpw24(in port p)
.cc_top XUD_Sup_Inpw24.function
.align 2
XUD_Sup_Inpw24:
   inpw      r0, res[r0], 24
   retsp     0
.size XUD_Sup_Inpw24, .-XUD_Sup_Inpw24
.cc_bottom XUD_Sup_Inpw24.function
.globl XUD_Sup_Inpw24.nstackwords
.globl XUD_Sup_Inpw24.maxthreads
.globl XUD_Sup_Inpw24.maxtimers
.globl XUD_Sup_Inpw24.maxchanends
.set XUD_Sup_Inpw24.nstackwords, 0
.set XUD_Sup_Inpw24.maxchanends, 0
.set XUD_Sup_Inpw24.maxtimers, 0
.set XUD_Sup_Inpw24.maxthreads, 1


.globl XUD_Sup_Inpw8
.type XUD_Sup_Inpw8, @function

.text

//unsigned XUD_Sup_Inpw24(in port p)
.cc_top XUD_Sup_Inpw8.function
.align 2
XUD_Sup_Inpw8:
   inpw      r0, res[r0], 8
   retsp     0
.size XUD_Sup_Inpw8, .-XUD_Sup_Inpw8
.cc_bottom XUD_Sup_Inpw8.function
.globl XUD_Sup_Inpw8.nstackwords
.globl XUD_Sup_Inpw8.maxthreads
.globl XUD_Sup_Inpw8.maxtimers
.globl XUD_Sup_Inpw8.maxchanends
.set XUD_Sup_Inpw8.nstackwords, 0
.set XUD_Sup_Inpw8.maxchanends, 0
.set XUD_Sup_Inpw8.maxtimers, 0
.set XUD_Sup_Inpw8.maxthreads, 1
