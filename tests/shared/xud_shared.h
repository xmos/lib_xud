// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef _XUD_SHARED_H_
#define _XUD_SHARED_H_
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <platform.h>
#include <stdint.h>
#include <assert.h>
#include "xud.h"

void exit(int);

#define FAIL_RX_DATAERROR        1
#define FAIL_RX_LENERROR         2
#define FAIL_RX_EXPECTED_CTL     3
#define FAIL_RX_BAD_RETURN_CODE  4
#define FAIL_RX_FRAMENUMBER      5

#ifndef PKT_LEN_START
#define PKT_LEN_START       (10)
#endif

#ifndef PKT_LEN_END
#define PKT_LEN_END         (21)
#endif

#ifndef MAX_PKT_COUNT
#define MAX_PKT_COUNT       (50)
#endif

#ifndef TEST_EP_NUM
#error TEST_EP_NUM not defined, using default value
#define TEST_EP_NUM         (1)
#endif

typedef enum t_runMode
{
    RUNMODE_LOOP,
    RUNMODE_DIE
} t_runMode;

int TestEp_Tx(chanend c_in, int epNum1, unsigned start, unsigned end, t_runMode runMode);
int TestEp_Rx(chanend c_out, int epNum, int start, int end);
int TestEp_Loopback(chanend c_out1, chanend c_in1, t_runMode runMode);

void dummyThreads();

#ifdef XUD_SIM_XSIM
void TerminateFail(int failReason);
void TerminatePass(int x);
#endif

int RxDataCheck(unsigned char b[], int l, int epNum, unsigned expectedLength);
void GenTxPacketBuffer(unsigned char buffer[], int length, int epNum);
XUD_Result_t SendTxPacket(XUD_ep ep, int length, int epNum);
#endif
