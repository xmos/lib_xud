// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* MSOS 2.0 Descriptors for vendor Endpoint 0 handling */

#include "msos_helpers.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "msos_descriptors.h"

void XUD_Update_Guid_In_Msos_Desc(MSOS_desc_registry_property_t *registry, const char *guid_str)
{
    if (guid_str == NULL || registry == NULL) {
        return;
    }
    unsigned char *msos_guid_ptr = registry->PropertyData;
    size_t guid_len = strnlen(guid_str, DEVICE_INTERFACE_GUID_MAX_STRLEN + 1);

    if (guid_len != DEVICE_INTERFACE_GUID_MAX_STRLEN) {
        return;
    }

    // Convert char array to UTF-16LE
    for(int i = 0; i < DEVICE_INTERFACE_GUID_MAX_STRLEN; i++)
    {
        msos_guid_ptr[2 * i] = guid_str[i];
        msos_guid_ptr[(2 * i) + 1] = 0x0;
    }
}
