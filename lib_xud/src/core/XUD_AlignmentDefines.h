// Copyright 2021-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/* XUD_AlignmentDefines.h
 * @brief Architecture-specific ASM function alignment
 */

#ifndef _XUD_ALIGNMENT_DEFINES_
#define _XUD_ALIGNMENT_DEFINES_
#if !defined(__XS2A__)
#define IBUFFER_FETCH_CORRECTION 1
#else
#define IBUFFER_FETCH_CORRECTION 0
#endif

#if IBUFFER_FETCH_CORRECTION == 1
#define FUNCTION_ALIGNMENT 16
#elif IBUFFER_FETCH_CORRECTION == 0
#define FUNCTION_ALIGNMENT 4
#else
#error IBUFFER_FETCH_CORRECTION not defined
#endif

#endif // _XUD_ALIGNMENT_DEFINES_
