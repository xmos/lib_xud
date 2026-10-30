// Copyright 2025-2026 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/** MSOS 2.0 Descriptors
*/

#ifndef _MSOS_DESCRIPTORS_H_
#define _MSOS_DESCRIPTORS_H_

#include <stddef.h>
#include <stdint.h>

#ifdef __XC__
#error "mos_descriptors.h is not supported in XC, only C. Due to struct packing requirements."
#endif

#define PACKED_STRUCT __attribute__((packed))

// total length, number of device caps
#define _U16(_high, _low)   ((uint16_t) (((_high) << 8) | (_low)))
#define _U16_HIGH(_u16)     ((uint8_t) (((_u16) >> 8) & 0x00ff))
#define _U16_LOW(_u16)      ((uint8_t) ((_u16)       & 0x00ff))
#define U16_TO_U8S_BE(_u16)   _U16_HIGH(_u16), _U16_LOW(_u16)
#define U16_TO_U8S_LE(_u16)   _U16_LOW(_u16), _U16_HIGH(_u16)

#define _U32_BYTE3(_u32)    ((uint8_t) ((((uint32_t) _u32) >> 24) & 0x000000ff)) // MSB
#define _U32_BYTE2(_u32)    ((uint8_t) ((((uint32_t) _u32) >> 16) & 0x000000ff))
#define _U32_BYTE1(_u32)    ((uint8_t) ((((uint32_t) _u32) >>  8) & 0x000000ff))
#define _U32_BYTE0(_u32)    ((uint8_t) (((uint32_t)  _u32)        & 0x000000ff)) // LSB

#define U32_TO_U8S_BE(_u32)   _U32_BYTE3(_u32), _U32_BYTE2(_u32), _U32_BYTE1(_u32), _U32_BYTE0(_u32)
#define U32_TO_U8S_LE(_u32)   _U32_BYTE0(_u32), _U32_BYTE1(_u32), _U32_BYTE2(_u32), _U32_BYTE3(_u32)

// BOS descriptor related defines
#define USB_DESCTYPE_DEVICE_CAPABILITY      (0x10)
#define DEVICE_CAPABILITY_PLATFORM          0x05
#define USB_BOS_MS_OS_20_UUID               0xDF, 0x60, 0xDD, 0xD8, 0x89, 0x45, 0xC7, 0x4C, \
                                            0x9C, 0xD2, 0x65, 0x9D, 0x9E, 0x64, 0x8A, 0x9F

/** USB Binary Device Object Store (BOS) Descriptor */
typedef struct {
  uint8_t  bLength;         ///< Size of this descriptor in bytes
  uint8_t  bDescriptorType; ///< BOS Descriptor Type
  uint16_t wTotalLength;    ///< Total length of data returned for this descriptor
  uint8_t  bNumDeviceCaps;  ///< Number of device capability descriptors in the BOS
} PACKED_STRUCT USB_Descriptor_BOS_standard_t;

// Platform device capability BOS descriptor
// MSOS 2.0 platform capability
typedef struct
{
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDevCapabilityType;
  uint8_t bReserved;
  uint8_t PlatformCapabilityUUID[16];
  uint8_t CapabilityData[8]; // defined as Variable sized for the descriptor in general but 8 for us
} PACKED_STRUCT USB_Descriptor_BOS_platform_t;

typedef struct
{
  USB_Descriptor_BOS_standard_t usb_desc_bos_standard;
  USB_Descriptor_BOS_platform_t usb_desc_bos_platform;
} PACKED_STRUCT USB_Descriptor_BOS_t;

// MSOS descriptor related defines
#define MSOS_PROPERTY_NAME_LEN            (42) /* bytes */
#define MSOS_INTERFACE_GUID_LEN           (80) /* bytes */
/* x/2 to go from utf-16 to single byte characters that make up the GUID string, -2 to remove both null characters */
#define DEVICE_INTERFACE_GUID_MAX_STRLEN  ((MSOS_INTERFACE_GUID_LEN / 2) - 2)

typedef enum
{
  MS_OS_20_SET_HEADER_DESCRIPTOR       = 0x00,
  MS_OS_20_SUBSET_HEADER_CONFIGURATION = 0x01,
  MS_OS_20_SUBSET_HEADER_FUNCTION      = 0x02,
  MS_OS_20_FEATURE_COMPATIBLE_ID       = 0x03,
  MS_OS_20_FEATURE_REG_PROPERTY        = 0x04,
  MS_OS_20_FEATURE_MIN_RESUME_TIME     = 0x05,
  MS_OS_20_FEATURE_MODEL_ID            = 0x06,
  MS_OS_20_FEATURE_CCGP_DEVICE         = 0x07,
  MS_OS_20_FEATURE_VENDOR_REVISION     = 0x08
} microsoft_os_20_type_t;



// USB MSOS2.0 Descriptors
typedef struct {
  uint16_t wLength;
  uint16_t  wDescriptorType;
  uint32_t dwWindowsVersion;
  uint16_t  wTotalLength;
} PACKED_STRUCT MSOS_desc_header_t;

typedef struct {
  uint16_t wLength;
  uint16_t  wDescriptorType;
  uint8_t bConfigurationValue;
  uint8_t bReserved;
  uint16_t wTotalLength;
} PACKED_STRUCT MSOS_desc_cfg_subset_header_t;

typedef struct {
  uint16_t wLength;
  uint16_t  wDescriptorType;
  uint8_t bFirstInterface;
  uint8_t bReserved;
  uint16_t wSubsetLength;
} PACKED_STRUCT MSOS_desc_fn_subset_header_t;

typedef struct {
  uint16_t wLength;
  uint16_t  wDescriptorType;
  uint8_t CompatibleID[8];
  uint8_t SubCompatibleID[8];
} PACKED_STRUCT MSOS_desc_compat_id_t;


typedef struct
{
  uint16_t wLength;
  uint16_t  wDescriptorType;
  uint16_t wPropertyDataType;
  uint16_t wPropertyNameLength;
  uint8_t PropertyName[MSOS_PROPERTY_NAME_LEN];
  uint16_t wPropertyDataLength;
  // wchar_t PropertyData[MSOS_INTERFACE_GUID_WCHARS];
  uint8_t PropertyData[MSOS_INTERFACE_GUID_LEN];
} PACKED_STRUCT MSOS_desc_registry_property_t;


// Registry property descriptor - wPropertyDataType
typedef enum
{
    MSOS_REG_PROPERTY_DATA_TYPE_REG_RESERVED,
    MSOS_REG_PROPERTY_DATA_TYPE_REG_SZ,
    MSOS_REG_PROPERTY_DATA_TYPE_REG_EXPAND_SZ,
    MSOS_REG_PROPERTY_DATA_TYPE_REG_BINARY,
    MSOS_REG_PROPERTY_DATA_TYPE_REG_DWORD_LITTLE_ENDIAN,
    MSOS_REG_PROPERTY_DATA_TYPE_REG_DWORD_BIG_ENDIAN,
    MSOS_REG_PROPERTY_DATA_TYPE_REG_LINK,
    MSOS_REG_PROPERTY_DATA_TYPE_REG_MULTI_SZ
} msos_property_data_type_t;

#endif // _MSOS_DESCRIPTORS_H_
