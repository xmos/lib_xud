// Copyright 2013-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "XUD_Support.h"
#include <xs1.h>

// Force external definitions of inline functions in this file.
extern inline unsigned XUD_Sup_GetResourceId(chanend c);
extern inline unsigned char XUD_Sup_inct(XUD_chan c);
extern inline unsigned char XUD_Sup_int(XUD_chan c);
extern inline unsigned char XUD_Sup_testct(XUD_chan c);
extern inline void XUD_Sup_outuint(XUD_chan c, unsigned x);
extern inline void XUD_Sup_outct(XUD_chan c, unsigned char x);

