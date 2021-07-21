// Copyright 2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/*
 * @brief Defines shared data for HID example threads.
 */
#ifndef HID_DEFS_H
#define HID_DEFS_H

/* Global report buffer */
#define HID_REPORT_BUFFER_SIZE 3
extern char g_reportBuffer[HID_REPORT_BUFFER_SIZE];

#endif // HID_DEFS_H
