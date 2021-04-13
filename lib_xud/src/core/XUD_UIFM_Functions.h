// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef UIFM_FUNCTIONS_H_
#define UIFM_FUNCTIONS_H_ 1

#include "XUD_Support.h"

// Sets up the ports for use with UIFM
void XUD_UIFM_PortConfig(buffered in port:32 clk_port, out port reg_write_port, in port reg_read_port, in port flag0_port, in port flag1_port, in port flag2_port, out port txd_port, in port rxd_port);

// Enables UIFM in the passed mode
unsigned XUD_UIFM_Enable(unsigned mode);

// Write value to UIFM register
void XUD_UIFM_RegWrite(out port reg_write_port, unsigned regNo, unsigned val);

// Same as above but loads reg write port from DP
void XUD_UIFM_RegWrite_( unsigned regNo, unsigned val);

// Read value from specified UIFM register
unsigned XUD_UIFM_RegRead(out port reg_write_port, in port reg_read_port, unsigned regNo);

/*
// Write value to UIFM register. Uses a lock for mutual exclusion
void XUD_UIFM_RegWrite_Locked(out port reg_write_port, XUD_lock l_ifm, unsigned regNo, unsigned val);

// Read value from specified UIFM register. Uses a lock for mutual exclusion
unsigned XUD_UIFM_RegRead_Locked(out port reg_write_port, in port reg_read_port, XUD_lock l_ifm, unsigned regNo);
*/

// Write specified endpoint buffer to UIFM packet buffer
void WriteEpBuffToPktBuff(out port reg_write_port, unsigned ep, unsigned datalength);

// Read data from specified endpoint buffer.
// Returns DATA PID for sequence checking
// Does CRC checking... returns 0 if CRC16 bad
unsigned ReadPktBuffToEpBuff(out port reg_write_port, in port reg_read_port, unsigned ep, unsigned datalength);

unsigned ReadSetupBuffToEpBuff(out port reg_write_port, in port reg_read_port, unsigned ep);


#endif
