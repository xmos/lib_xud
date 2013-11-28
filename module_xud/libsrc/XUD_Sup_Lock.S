/** XUD_Sup_Lock.S
  * @brief     Functions for using hardware locks
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

#include <xs1_user.h>

/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_GetLock()
.globl XUD_Sup_GetLock
.type XUD_Sup_GetLock, @function
.text
.cc_top XUD_Sup_GetLock.function
.align 2
XUD_Sup_GetLock:
  getr		r0, XS1_RES_TYPE_LOCK
  retsp 	0
.size XUD_Sup_GetLock, .-XUD_Sup_GetLock
.cc_bottom XUD_Sup_GetLock.function
.globl XUD_Sup_GetLock.nstackwords
.globl XUD_Sup_GetLock.maxthreads
.globl XUD_Sup_GetLock.maxtimers
.globl XUD_Sup_GetLock.maxchanends
.set XUD_Sup_GetLock.nstackwords, 0
.set XUD_Sup_GetLock.maxchanends, 0
.set XUD_Sup_GetLock.maxtimers, 0
.set XUD_Sup_GetLock.maxthreads, 0


/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_ClaimLock(lock l)
.globl XUD_Sup_ClaimLock
.type XUD_Sup_ClaimLock, @function
.text
.cc_top XUD_Sup_ClaimLock.function
.align 2
XUD_Sup_ClaimLock:
  in		r0, res[r0]
  retsp 	0
.size XUD_Sup_ClaimLock, .-XUD_Sup_ClaimLock
.cc_bottom XUD_Sup_ClaimLock.function
.globl XUD_Sup_ClaimLock.nstackwords
.globl XUD_Sup_ClaimLock.maxthreads
.globl XUD_Sup_ClaimLock.maxtimers
.globl XUD_Sup_ClaimLock.maxchanends
.set XUD_Sup_ClaimLock.nstackwords, 0
.set XUD_Sup_ClaimLock.maxchanends, 0
.set XUD_Sup_ClaimLock.maxtimers, 0
.set XUD_Sup_ClaimLock.maxthreads, 1


/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_FreeLock(lock l)
.globl XUD_Sup_FreeLock
.type XUD_Sup_FreeLock, @function
.text
.cc_top XUD_Sup_FreeLock.function
.align 2
XUD_Sup_FreeLock:
  out		res[r0], r0
  retsp 	0
.size XUD_Sup_FreeLock, .-XUD_Sup_FreeLock
.cc_bottom XUD_Sup_FreeLock.function
.globl XUD_Sup_FreeLock.nstackwords
.globl XUD_Sup_FreeLock.maxthreads
.globl XUD_Sup_FreeLock.maxtimers
.globl XUD_Sup_FreeLock.maxchanends
.set XUD_Sup_FreeLock.nstackwords, 0
.set XUD_Sup_FreeLock.maxchanends, 0
.set XUD_Sup_FreeLock.maxtimers, 0
.set XUD_Sup_FreeLock.maxthreads, 1


/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_FreerLock(lock l)
.globl XUD_Sup_FreerLock
.type XUD_Sup_FreerLock, @function
.text
.cc_top XUD_Sup_FreerLock.function
.align 2
XUD_Sup_FreerLock:
  freer		res[r0]
  retsp 	0
.size XUD_Sup_FreerLock, .-XUD_Sup_FreerLock
.cc_bottom XUD_Sup_FreerLock.function
.globl XUD_Sup_FreerLock.nstackwords
.globl XUD_Sup_FreerLock.maxthreads
.globl XUD_Sup_FreerLock.maxtimers
.globl XUD_Sup_FreerLock.maxchanends
.set XUD_Sup_FreerLock.nstackwords, 0
.set XUD_Sup_FreerLock.maxchanends, 0
.set XUD_Sup_FreerLock.maxtimers, 0
.set XUD_Sup_FreerLock.maxthreads, 1
