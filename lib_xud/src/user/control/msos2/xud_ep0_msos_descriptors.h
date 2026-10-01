// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* MSOS 2.0 Descriptors for vendor Endpoint 0 handling */

#ifndef XUD_EP0_MSOS_DESCRIPTORS_H
#define XUD_EP0_MSOS_DESCRIPTORS_H

#include <stddef.h>
#include <stdint.h>

#include "xud.h"
#include "xud_device.h"
#if (XUD_ENABLE_MSOS_DFU_DESCS) || (XUD_ENABLE_MSOS_CONTROL_DESCS) || (__DOXYGEN__)

/* Example of simple, single interface, MSOS 2.0 descriptor */

#if defined(__XC__) || defined(__cplusplus)
extern "C" {
#endif

/** Initialise the Simple Ep0 MSOS Descriptors before enumeration of the device */
void XUD_Init_Ep0_Msos_Descriptors(void);

/** Function to send the BOS descriptor when prompted via a Standard Get request
 * 
 * Request will be Standard Get request (USB_GET_DESCRIPTOR) with wValue high byte == USB_DESCTYPE_BOS
 * 
 * \param num_interfaces  Number of interfaces in the device
 * \param ep0_out   Endpoint 0 OUT endpoint
 * \param ep0_in    Endpoint 0 IN endpoint
 * \param sp        Pointer to the setup packet of the request
 * 
 * \retval          XUD_RES_ERR if request not handled
 * \retval          XUD_RES_OKAY if successful
 * \retval          XUD_RES_WAIT if transfer in progress
 */
XUD_Result_t XUD_GetBosDescriptor(int32_t num_interfaces, XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp);

/** Function to send the MSOS descriptor when prompted via a Vendor Get request
 * 
 * Request will be a Vendor Get request with bRequest == XUA_REQUEST_GET_MSOS_DESCRIPTOR.
 * This is defined in xua_conf_default.h
 * 
 * \param num_interfaces  Number of interfaces in the device
 * \param ep0_out   Endpoint 0 OUT endpoint
 * \param ep0_in    Endpoint 0 IN endpoint
 * \param sp        Pointer to the setup packet of the request
 * 
 * \retval          XUD_RES_ERR if request not handled
 * \retval          XUD_RES_OKAY if successful
 * \retval          XUD_RES_WAIT if transfer in progress
 */
XUD_Result_t XUD_GetMsosDescriptor(int32_t num_interfaces, XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp);

#if defined(__XC__) || defined(__cplusplus)
} // extern "C"
#endif
#endif // (XUD_ENABLE_MSOS_DFU_DESCS) || (XUD_ENABLE_MSOS_CONTROL_DESCS)
#endif
