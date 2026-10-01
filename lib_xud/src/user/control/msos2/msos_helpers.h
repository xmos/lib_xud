// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* MSOS 2.0 Descriptors for vendor Endpoint 0 handling */

#ifndef _MSOS_HELPERS_H_
#define _MSOS_HELPERS_H_

#include <stddef.h>
#include <stdint.h>

#if defined(__XC__) || defined(__cplusplus)
extern "C" {
#endif

#if !defined(__XC__)
/* These types and functions are only available to C code. Due to struct packing requirements in the MSOS descriptors, they cannot be used in XC code.
 * If the endpoint0 code is run in XC, then a small wrapper should be used to initialise the BOS and MSOS descriptors.
 * For single interface example, see `xud_ep0_msos_descriptors.h` */

#include "msos_descriptors.h"

/** Descriptor handle
 * 
 * Used to pass descriptor pointer and size. As the type will change with different applications, as will the length.
 * The USB driver will only want a byte array and length.
 */
typedef struct desc_handle_t
{
    unsigned char *desc_ptr;
    size_t desc_size;
} desc_handle_t;

/** Update the device interface GUID in the MSOS descriptor, before enumeration.
 * 
 * The device MSOS 2.0 GUID is used by the host to bind the correct driver to the device.
 * The example GUID provided are intended to use with WINUSB driver on Windows.
 * 
 * When users develop their own USB device, they should generate their own unique GUID for the device
 * interface and link this to the host driver.
 * 
 * \param registry  Pointer to the registry property descriptor to update
 * \param guid_str  String containing the device interface GUID for the control interface.
 *                  Must be in the format "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}" and 
 *                  DEVICE_INTERFACE_GUID_MAX_STRLEN long, plus null terminator.
 */
void XUD_Update_Guid_In_Msos_Desc(MSOS_desc_registry_property_t *registry, const char *guid_str);

#endif

#if defined(__XC__) || defined(__cplusplus)
} // extern "C"
#endif

#endif
