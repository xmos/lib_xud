
#ifndef _XUD_DEFINES_H_
#define _XUD_DEFINES_H_

/* Defines for EP counts.  Normally 16 in/out but can be reduced to reduce memory usage
 * but this may result in undefined behaviour for un-used endpoints.
 */
#ifndef XUD_MAX_NUM_EP_OUT  
#define XUD_MAX_NUM_EP_OUT  16
#endif

#ifndef XUD_MAX_NUM_EP_IN  
#define XUD_MAX_NUM_EP_IN   16
#endif

#define XUD_MAX_NUM_EP      (XUD_MAX_NUM_EP_OUT + XUD_MAX_NUM_EP_IN)

#endif
