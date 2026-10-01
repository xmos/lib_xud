// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* MSOS 2.0 Descriptors for vendor Endpoint 0 handling */

#include "xud.h"
#if (XUD_ENABLE_MSOS_DFU_DESCS) || (XUD_ENABLE_MSOS_CONTROL_DESCS)

#include "xud_ep0_msos_descriptors.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <wchar.h>

#include "msos_descriptors.h"
#include "msos_helpers.h"
#include "xud_device.h"

/** Example of simple, single interface, MSOS 2.0 descriptor */
typedef struct {
  MSOS_desc_header_t              msos_desc_header;
  MSOS_desc_compat_id_t           msos_desc_compat_id;
  MSOS_desc_registry_property_t   msos_desc_registry_property;
} __attribute__((packed)) MSOS_desc_simple_t;

/* USB Binary Device Object Store (BOS) descriptor */
static USB_Descriptor_BOS_t desc_bos_simple =
{
    .usb_desc_bos_standard = {
        .bLength = sizeof(USB_Descriptor_BOS_standard_t),
        .bDescriptorType = USB_DESCTYPE_BOS,
        .wTotalLength = sizeof(USB_Descriptor_BOS_standard_t) + sizeof(USB_Descriptor_BOS_platform_t),
        .bNumDeviceCaps = 1
    },
    .usb_desc_bos_platform = {
        .bLength = sizeof(USB_Descriptor_BOS_platform_t),
        .bDescriptorType = USB_DESCTYPE_DEVICE_CAPABILITY,
        .bDevCapabilityType = DEVICE_CAPABILITY_PLATFORM,
        .bReserved = 0,
        .PlatformCapabilityUUID = {USB_BOS_MS_OS_20_UUID},
        .CapabilityData = {U32_TO_U8S_LE(0x06030000), U16_TO_U8S_LE(sizeof(MSOS_desc_simple_t)), XUD_REQUEST_GET_MSOS_DESCRIPTOR, 0}
    }
};

/* USB MSOS 2.0 descriptor */
static MSOS_desc_simple_t desc_ms_os_20_simple =
{
    .msos_desc_header =
    {
        .wLength = sizeof(MSOS_desc_header_t),
        .wDescriptorType = MS_OS_20_SET_HEADER_DESCRIPTOR,
        .dwWindowsVersion = 0x06030000, // 0603 == Windows 8.1
        .wTotalLength = sizeof(MSOS_desc_simple_t)
    },
    .msos_desc_compat_id =
    {
        .wLength = sizeof(MSOS_desc_compat_id_t),
        .wDescriptorType = MS_OS_20_FEATURE_COMPATIBLE_ID,
        .CompatibleID = {'W', 'I', 'N', 'U', 'S', 'B', 0x00, 0x00},
        .SubCompatibleID = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    },
    .msos_desc_registry_property =
    {
        .wLength = sizeof(MSOS_desc_registry_property_t),
        .wDescriptorType = MS_OS_20_FEATURE_REG_PROPERTY,
        .wPropertyDataType = MSOS_REG_PROPERTY_DATA_TYPE_REG_MULTI_SZ,
        .wPropertyNameLength = MSOS_PROPERTY_NAME_LEN,
        .PropertyName = {'D', 0x00, 'e', 0x00, 'v', 0x00, 'i', 0x00, 'c', 0x00, 'e', 0x00, 'I', 0x00, 'n', 0x00, 't', 0x00, 'e', 0x00,
                         'r', 0x00, 'f', 0x00, 'a', 0x00, 'c', 0x00, 'e', 0x00, 'G', 0x00, 'U', 0x00, 'I', 0x00, 'D', 0x00, 's', 0x00, 0x00, 0x00}, //"DeviceInterfaceGUIDs\0" in UTF-16
        .wPropertyDataLength = MSOS_INTERFACE_GUID_LEN,
        // "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}\0\0" generate from https://guidgenerator.com/ and stored as Unicode
        .PropertyData = { 0 } // defined in the XUD_WINUSB_DEVICE_INTERFACE_GUID_CONTROL define and updated in the descriptor at runtime with update_guid_in_msos_desc()
    }
};

typedef struct {
  MSOS_desc_header_t              msos_desc_header;
  MSOS_desc_cfg_subset_header_t   msos_desc_cfg_subset_header;

#if (XUD_ENABLE_MSOS_CONTROL_DESCS)
  MSOS_desc_fn_subset_header_t    msos_fn_subset_header_control;
  MSOS_desc_compat_id_t           msos_desc_compat_id_control;
  MSOS_desc_registry_property_t   msos_desc_registry_property_control;
#endif

#if XUD_ENABLE_MSOS_DFU_DESCS
  MSOS_desc_fn_subset_header_t    msos_fn_subset_header_dfu;
  MSOS_desc_compat_id_t           msos_desc_compat_id_dfu;
  MSOS_desc_registry_property_t   msos_desc_registry_property_dfu;
#endif
} __attribute__((packed)) MSOS_desc_composite_t;

/* USB Binary Device Object Store (BOS) descriptor */
// TODO - replace with simple MSOS Bos descriptor, but needs FW to change length based on request.
USB_Descriptor_BOS_t desc_bos_composite =
{
    .usb_desc_bos_standard = {
        .bLength = sizeof(USB_Descriptor_BOS_standard_t),
        .bDescriptorType = USB_DESCTYPE_BOS,
        .wTotalLength = sizeof(USB_Descriptor_BOS_standard_t) + sizeof(USB_Descriptor_BOS_platform_t),
        .bNumDeviceCaps = 1
    },
    .usb_desc_bos_platform = {
        .bLength = sizeof(USB_Descriptor_BOS_platform_t),
        .bDescriptorType = USB_DESCTYPE_DEVICE_CAPABILITY,
        .bDevCapabilityType = DEVICE_CAPABILITY_PLATFORM,
        .bReserved = 0,
        .PlatformCapabilityUUID = {USB_BOS_MS_OS_20_UUID},
        .CapabilityData = {U32_TO_U8S_LE(0x06030000), U16_TO_U8S_LE(sizeof(MSOS_desc_composite_t)), XUD_REQUEST_GET_MSOS_DESCRIPTOR, 0}
    }
};

MSOS_desc_composite_t desc_ms_os_20_composite =
{
    .msos_desc_header =
    {
        .wLength = sizeof(MSOS_desc_header_t),
        .wDescriptorType = MS_OS_20_SET_HEADER_DESCRIPTOR,
        .dwWindowsVersion = 0x06030000,
        .wTotalLength = sizeof(MSOS_desc_composite_t)
    },
    .msos_desc_cfg_subset_header =
    {
        .wLength = sizeof(MSOS_desc_cfg_subset_header_t),
        .wDescriptorType = MS_OS_20_SUBSET_HEADER_CONFIGURATION,
        .bConfigurationValue = 0,
        .bReserved = 0,
        .wTotalLength = sizeof(MSOS_desc_composite_t) - sizeof(MSOS_desc_header_t)
    },
  #if (XUD_ENABLE_MSOS_CONTROL_DESCS)
    .msos_fn_subset_header_control =
    {
        .wLength = sizeof(MSOS_desc_fn_subset_header_t),
        .wDescriptorType = MS_OS_20_SUBSET_HEADER_FUNCTION,
        .bFirstInterface = XUD_INTERFACE_NUMBER_MISC_CONTROL,
        .bReserved = 0,
        .wSubsetLength = sizeof(MSOS_desc_fn_subset_header_t) + sizeof(MSOS_desc_compat_id_t) + sizeof(MSOS_desc_registry_property_t)
    },
    .msos_desc_compat_id_control =
    {
        .wLength = sizeof(MSOS_desc_compat_id_t),
        .wDescriptorType = MS_OS_20_FEATURE_COMPATIBLE_ID,
        .CompatibleID = {'W', 'I', 'N', 'U', 'S', 'B', 0x00, 0x00}, // "WINUSB\0\0"
        .SubCompatibleID = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    },
    .msos_desc_registry_property_control =
    {
        .wLength = sizeof(MSOS_desc_registry_property_t),
        .wDescriptorType = MS_OS_20_FEATURE_REG_PROPERTY,
        .wPropertyDataType = 0x0007, // REG_MULTI_SZ as defined in Table 15 of Microsoft OS 2.0 Descriptors Specification. Check IMPORTANT NOTE 2 in https://github.com/pbatard/libwdi/wiki/WCID-Devices
        // for why we need REG_MULTI_SZ and not REG_SZ
        .wPropertyNameLength = MSOS_PROPERTY_NAME_LEN,
        .PropertyName = { 'D', 0x00, 'e', 0x00, 'v', 0x00, 'i', 0x00, 'c', 0x00, 'e', 0x00, 'I', 0x00, 'n', 0x00, 't', 0x00, 'e', 0x00,
                          'r', 0x00, 'f', 0x00, 'a', 0x00, 'c', 0x00, 'e', 0x00, 'G', 0x00, 'U', 0x00, 'I', 0x00, 'D', 0x00, 's', 0x00, 0x00, 0x00}, //"DeviceInterfaceGUIDs\0" in UTF-16
        .wPropertyDataLength = MSOS_INTERFACE_GUID_LEN,
        // "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}\0\0" generate from https://guidgenerator.com/ and stored as Unicode
        .PropertyData = { 0 } // defined in the XUA_WINUSB_DEVICE_INTERFACE_GUID_CONTROL define and updated in the descriptor at runtime with update_guid_in_msos_desc()
    },
#endif

#if XUD_ENABLE_MSOS_DFU_DESCS
    .msos_fn_subset_header_dfu =
    {
        .wLength = sizeof(MSOS_desc_fn_subset_header_t),
        .wDescriptorType = MS_OS_20_SUBSET_HEADER_FUNCTION,
        .bFirstInterface = XUD_INTERFACE_NUMBER_DFU,
        .bReserved = 0,
        .wSubsetLength = sizeof(MSOS_desc_fn_subset_header_t) + sizeof(MSOS_desc_compat_id_t) + sizeof(MSOS_desc_registry_property_t)
    },
    .msos_desc_compat_id_dfu =
    {
        .wLength = sizeof(MSOS_desc_compat_id_t),
        .wDescriptorType = MS_OS_20_FEATURE_COMPATIBLE_ID,
        .CompatibleID = {'W', 'I', 'N', 'U', 'S', 'B', 0x00, 0x00}, // "WINUSB\0\0"
        .SubCompatibleID = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    },
    .msos_desc_registry_property_dfu =
    {
        .wLength = sizeof(MSOS_desc_registry_property_t),
        .wDescriptorType = MS_OS_20_FEATURE_REG_PROPERTY,
        .wPropertyDataType = 0x0007, // REG_MULTI_SZ as defined in Table 15 of Microsoft OS 2.0 Descriptors Specification. Check IMPORTANT NOTE 2 in https://github.com/pbatard/libwdi/wiki/WCID-Devices
        // for why we need REG_MULTI_SZ and not REG_SZ
        .wPropertyNameLength = MSOS_PROPERTY_NAME_LEN,
        .PropertyName = { 'D', 0x00, 'e', 0x00, 'v', 0x00, 'i', 0x00, 'c', 0x00, 'e', 0x00, 'I', 0x00, 'n', 0x00, 't', 0x00, 'e', 0x00,
                          'r', 0x00, 'f', 0x00, 'a', 0x00, 'c', 0x00, 'e', 0x00, 'G', 0x00, 'U', 0x00, 'I', 0x00, 'D', 0x00, 's', 0x00, 0x00, 0x00}, //"DeviceInterfaceGUIDs\0" in UTF-16
        .wPropertyDataLength = MSOS_INTERFACE_GUID_LEN,
        // "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}\0\0" generate from https://guidgenerator.com/ and stored as Unicode
        .PropertyData = { 0 } // defined in the XUA_WINUSB_DEVICE_INTERFACE_GUID_CONTROL define and updated in the descriptor at runtime with update_guid_in_msos_desc()
    }
#endif
};

/* Device Interface GUID */
#if XUD_ENABLE_MSOS_DFU_DESCS
static char g_device_interface_guid_dfu_str[DEVICE_INTERFACE_GUID_MAX_STRLEN+1] = XUD_WINUSB_DEVICE_INTERFACE_GUID_DFU;
#endif
#if (XUD_ENABLE_MSOS_CONTROL_DESCS)
static char g_device_interface_guid_control_str[DEVICE_INTERFACE_GUID_MAX_STRLEN + 1] = XUD_WINUSB_DEVICE_INTERFACE_GUID_CONTROL;
#endif

void XUD_Init_Ep0_Msos_Descriptors(void)
{
#if XUD_ENABLE_MSOS_DFU_DESCS
    XUD_Update_Guid_In_Msos_Desc(&desc_ms_os_20_composite.msos_desc_registry_property_dfu, g_device_interface_guid_dfu_str);
#endif

#if (XUD_ENABLE_MSOS_CONTROL_DESCS)
    XUD_Update_Guid_In_Msos_Desc(&desc_ms_os_20_composite.msos_desc_registry_property_control, g_device_interface_guid_control_str);
#endif

#if (XUD_ENABLE_MSOS_DFU_DESCS)
    // Apply valid GUID
    if (strnlen(g_device_interface_guid_dfu_str, (DEVICE_INTERFACE_GUID_MAX_STRLEN + 1)) == DEVICE_INTERFACE_GUID_MAX_STRLEN) {
        XUD_Update_Guid_In_Msos_Desc(&desc_ms_os_20_simple.msos_desc_registry_property, g_device_interface_guid_dfu_str);
    }
#elif (XUD_ENABLE_MSOS_CONTROL_DESCS)
    if (strnlen(g_device_interface_guid_control_str, (DEVICE_INTERFACE_GUID_MAX_STRLEN + 1)) == DEVICE_INTERFACE_GUID_MAX_STRLEN) {
        XUD_Update_Guid_In_Msos_Desc(&desc_ms_os_20_simple.msos_desc_registry_property, g_device_interface_guid_control_str);
    }
#endif
}

static desc_handle_t bos_handle = {
    (unsigned char*)&desc_bos_simple, sizeof(USB_Descriptor_BOS_t),
};

static desc_handle_t msos_handle = {
    (unsigned char*)&desc_ms_os_20_simple, sizeof(MSOS_desc_simple_t),
};

static desc_handle_t composite_bos_handle = {
    (unsigned char*)&desc_bos_composite, sizeof(USB_Descriptor_BOS_t),
};

static desc_handle_t composite_msos_handle = {
    (unsigned char*)&desc_ms_os_20_composite, sizeof(MSOS_desc_composite_t),
};

XUD_Result_t XUD_GetBosDescriptor(int32_t num_interfaces, XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp)
{
    if ((num_interfaces == 1) && (bos_handle.desc_ptr != NULL)) {
        return XUD_DoGetRequest(ep0_out, ep0_in, bos_handle.desc_ptr, bos_handle.desc_size, sp->wLength);
    } else if ((num_interfaces > 1) && (composite_bos_handle.desc_ptr != NULL)) {
        return XUD_DoGetRequest(ep0_out, ep0_in, composite_bos_handle.desc_ptr, composite_bos_handle.desc_size, sp->wLength);
    } else {
        return XUD_RES_ERR;
    }
}

XUD_Result_t XUD_GetMsosDescriptor(int32_t num_interfaces, XUD_ep ep0_out, XUD_ep ep0_in, USB_SetupPacket_t *sp)
{
    if ((num_interfaces == 1) && (msos_handle.desc_ptr != NULL)) {
        return XUD_DoGetRequest(ep0_out, ep0_in, msos_handle.desc_ptr, msos_handle.desc_size, sp->wLength);
    } else if ((num_interfaces > 1) && (composite_msos_handle.desc_ptr != NULL)) {
        return XUD_DoGetRequest(ep0_out, ep0_in, composite_msos_handle.desc_ptr, composite_msos_handle.desc_size, sp->wLength);
    } else {
        return XUD_RES_ERR;
    }
}

#endif
