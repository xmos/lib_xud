// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT       (5)
#define EP_COUNT_IN        (5)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START   (8)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END     (20)
#endif

#include "test_control_basic_get.xc"

#include "test_main.xc"

