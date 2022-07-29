// Copyright 2011-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** XUD_EpFuncs.S
  * @brief     ASM functions for data transfer to/from XUD
  * @author    Ross Owen, XMOS Limited
  */
#include "XUD_USB_Defines.h"
#include "XUD_AlignmentDefines.h"

#if defined __XS2A__
.set too_many_cores, main.maxcores > 6
.assert 0, too_many_cores, "Warning: More than 6 cores used on a tile. Ensure this is not the case on tile running XUD."
#endif

//void XUD_SetTestMode(XUD_ep ep, unsigned testMode);
.globl XUD_SetTestMode
.type XUD_SetTestMode, @function

.cc_top XUD_SetTestMode.func
.align FUNCTION_ALIGNMENT
XUD_SetTestMode:
.issue_mode single
    ENTSP_lu6  0
    ldw        r0, r0[2]                       // Load our chanend ID to use
    outct      res[r0], 1
    chkct      res[r0], 1
    out        res[r0], r1                     // Output test mode
    outct      res[r0], 1
    chkct      res[r0], 1
    retsp      0
.size XUD_SetTestMode, .-XUD_SetTestMode
.cc_bottom XUD_SetTestMode.func
.globl XUD_SetTestMode.nstackwords
.globl XUD_SetTestMode.maxchanends
.globl XUD_SetTestMode.maxtimers
.globl XUD_SetTestMode.maxcores
.set XUD_SetTestMode.nstackwords, 0
.set XUD_SetTestMode.maxchanends, 0
.set XUD_SetTestMode.maxtimers, 0
.set XUD_SetTestMode.maxcores, 1
.globl XUD_SetTestMode.locnoside
.globl XUD_SetTestMode.locnochandec
.globl XUD_SetTestMode.locnoglobalaccess
.globl XUD_SetTestMode.locnointerfaceaccess
.globl XUD_SetTestMode.locnonotificationselect
.set XUD_SetTestMode.locnoside, 1
.set XUD_SetTestMode.locnochandec, 1
.set XUD_SetTestMode.locnoglobalaccess, 1
.set XUD_SetTestMode.locnointerfaceaccess, 1
.set XUD_SetTestMode.locnonotificationselect, 1
