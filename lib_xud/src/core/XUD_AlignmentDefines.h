// Copyright (c) 2021, XMOS Ltd, All rights reserved
/* XUD_AlignmentDefines.h
 * @brief Architecture-specific ASM function alignment
 */

#ifndef _XUD_ALIGNMENT_DEFINES_
#define _XUD_ALIGNMENT_DEFINES_
#if defined(__XS3A__)
#define IBUFFER_FETCH_CORRECTION 1
#elif defined(__XS2A__)
#define IBUFFER_FETCH_CORRECTION 0
#else
#error No architecture defined
#endif

#if IBUFFER_FETCH_CORRECTION == 1
#define FUNCTION_ALIGNMENT 16
#elif IBUFFER_FETCH_CORRECTION == 0
#define FUNCTION_ALIGNMENT 4
#else
#error IBUFFER_FETCH_CORRECTION not defined
#endif

#endif // _XUD_ALIGNMENT_DEFINES_
