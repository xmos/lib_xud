// Copyright 2017-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef __XUD_CONF_DEFAULT_H__
#define __XUD_CONF_DEFAULT_H__

#ifndef USB_ISO_EP_MAX_TRANSACTION_SIZE
#define USB_ISO_EP_MAX_TRANSACTION_SIZE     (1024) /* max size of the data payload for each individual transaction for an ISO EP */
#endif

#ifndef USB_ISO_MAX_TRANSACTIONS_PER_MICROFRAME
#define USB_ISO_MAX_TRANSACTIONS_PER_MICROFRAME     (2) /* maximum number of transactions per microframe for an ISO EP*/
#endif

#endif
