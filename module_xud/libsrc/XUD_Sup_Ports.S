/** XUD_Sup_Ports.S
  * @brief     Support functions for using ports
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

.extern XUD_Sup_Outpw8
.globl XUD_Sup_Outpw8.nstackwords
.globl XUD_Sup_Outpw8.maxthreads
.globl XUD_Sup_Outpw8.maxtimers
.globl XUD_Sup_Outpw8.maxchanends

.linkset XUD_Sup_Outpw8.nstackwords, 0
.linkset XUD_Sup_Outpw8.maxchanends, 0
.linkset XUD_Sup_Outpw8.maxtimers, 0
.linkset XUD_Sup_Outpw8.maxthreads, 0

.globl XUD_Sup_Outpw8

.text

XUD_Sup_Outpw8:
  outpw     res[r0], r1, 8
  retsp  0


.extern XUD_Sup_Outpw16
.globl XUD_Sup_Outpw16.nstackwords
.globl XUD_Sup_Outpw16.maxthreads
.globl XUD_Sup_Outpw16.maxtimers
.globl XUD_Sup_Outpw16.maxchanends

.linkset XUD_Sup_Outpw16.nstackwords, 0
.linkset XUD_Sup_Outpw16.maxchanends, 0
.linkset XUD_Sup_Outpw16.maxtimers, 0
.linkset XUD_Sup_Outpw16.maxthreads, 0

.globl XUD_Sup_Outpw16

.text

XUD_Sup_Outpw16:
  outpw  	res[r0], r1, 16
  retsp 0


.extern XUD_Sup_Outpw24
.globl XUD_Sup_Outpw24.nstackwords
.globl XUD_Sup_Outpw24.maxthreads
.globl XUD_Sup_Outpw24.maxtimers
.globl XUD_Sup_Outpw24.maxchanends

.linkset XUD_Sup_Outpw24.nstackwords, 0
.linkset XUD_Sup_Outpw24.maxchanends, 0
.linkset XUD_Sup_Outpw24.maxtimers, 0
.linkset XUD_Sup_Outpw24.maxthreads, 0

.globl XUD_Sup_Outpw24

.text

XUD_Sup_Outpw24:
  outpw  	res[r0], r1, 24
  retsp 0




// XUD_Sup_Inpw24.S

.extern XUD_Sup_Inpw24
.globl XUD_Sup_Inpw24.nstackwords
.globl XUD_Sup_Inpw24.maxthreads
.globl XUD_Sup_Inpw24.maxtimers
.globl XUD_Sup_Inpw24.maxchanends

.linkset XUD_Sup_Inpw24.nstackwords, 0
.linkset XUD_Sup_Inpw24.maxchanends, 0
.linkset XUD_Sup_Inpw24.maxtimers, 0
.linkset XUD_Sup_Inpw24.maxthreads, 0

.globl XUD_Sup_Inpw24

.text

//unsigned XUD_Sup_Inpw24(in port p)
XUD_Sup_Inpw24:
   inpw      r0, res[r0], 24
   retsp     0

.extern XUD_Sup_Inpw8
.globl XUD_Sup_Inpw8.nstackwords
.globl XUD_Sup_Inpw8.maxthreads
.globl XUD_Sup_Inpw8.maxtimers
.globl XUD_Sup_Inpw8.maxchanends

.linkset XUD_Sup_Inpw8.nstackwords, 0
.linkset XUD_Sup_Inpw8.maxchanends, 0
.linkset XUD_Sup_Inpw8.maxtimers, 0
.linkset XUD_Sup_Inpw8.maxthreads, 0

.globl XUD_Sup_Inpw8

.text

//unsigned XUD_Sup_Inpw24(in port p)
XUD_Sup_Inpw8:
   inpw      r0, res[r0], 8
   retsp     0



