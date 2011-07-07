/** XUD_Sup_Lock.S
  * @brief     Functions for using hardware locks
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

#include <xs1_user.h>

/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_GetLock()
.extern XUD_Sup_GetRLock
.globl XUD_Sup_GetLock.nstackwords
.linkset XUD_Sup_GetLock.nstackwords, 0
.globl XUD_Sup_GetLock
.text 
XUD_Sup_GetLock:
  getr		r0, XS1_RES_TYPE_LOCK
  retsp 	0


/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_ClaimLock(lock l)
.extern XUD_Sup_ClaimLock
.globl XUD_Sup_ClaimLock.nstackwords
.linkset XUD_Sup_ClaimLock.nstackwords, 0
.globl XUD_Sup_ClaimLock
.text 
XUD_Sup_ClaimLock:
  in		r0, res[r0]
  retsp 	0


/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_FreeLock(lock l)
.extern XUD_Sup_FreeLock
.globl XUD_Sup_FreeLock.nstackwords
.linkset XUD_Sup_FreeLock.nstackwords, 0
.globl XUD_Sup_FreeLock
.text 
XUD_Sup_FreeLock:
  out		res[r0], r0
  retsp 	0


/////////////////////////////////////////////////////////////////////////
// void XUD_Sup_FreerLock(lock l)
.extern XUD_Sup_FreerLock
.globl XUD_Sup_FreerLock.nstackwords
.linkset XUD_Sup_FreerLock.nstackwords, 0
.globl XUD_Sup_FreerLock
.text 
XUD_Sup_FreerLock:
  freer		res[r0]
  retsp 	0


