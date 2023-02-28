// Copyright 2019-2023 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/**
 * @file   XUD_HAL.h
 * \brief   USB HAL Layer
**/

#include <xccompat.h>
#include "xud.h"
#include <platform.h>

#define USB_TILE_REF usb_tile

#if !defined(__XS2A__)
#include <xs1.h>
// TODO should be properly in HAL
unsigned XtlSelFromMhz(unsigned m);
#else
#include "XUD_USBTile_Support.h"
#include "xs1_to_glx.h"
#include "xs2_su_registers.h"
#endif

/**
 * \enum    XUD_LineState_t
 * \brief   USB Line States
 */
typedef enum XUD_LineState_t
{
    XUD_LINESTATE_SE0 = 0,      /**< SE0 State */
    XUD_LINESTATE_HS_J_FS_K = 1,/**< J/K State */
    XUD_LINESTATE_HS_K_FS_J = 2,/**< K/J State */
    XUD_LINESTATE_SE1 = 3       /**< Invalid bus state - both lines high **/
} XUD_LineState_t;

void XUD_HAL_EnterMode_PeripheralChirp();
void XUD_HAL_EnterMode_PeripheralFullSpeed();
void XUD_HAL_EnterMode_PeripheralHighSpeed();
#ifdef __XS2A__
/* Special case for __XS2A__ where writing to USB register is relatively slow */
void XUD_HAL_EnterMode_PeripheralHighSpeed_Start();
void XUD_HAL_EnterMode_PeripheralHighSpeed_Complete();
#endif
void XUD_HAL_EnterMode_PeripheralTestJTestK();
void XUD_HAL_EnterMode_TristateDrivers();

/**
 * \brief   Get current linestate status
 * \return  XUD_LineState_t representing current line status
**/
XUD_LineState_t XUD_HAL_GetLineState();

/**
 * \brief   Wait for a change in linestate and return, or timeout
 * \param   Reference to current linestate (updated with new linestate
 * \return  1 for timed out, otherwise 0
**/
unsigned XUD_HAL_WaitForLineStateChange(REFERENCE_PARAM(XUD_LineState_t, currentLs), unsigned timeout);

/**
 *  \brief   HAL function to set xCORE into signalling mode
 *           (as opposed to "data transfer" mode)
 *
 * TODO     Should this be combined with EnterMode_PeripheralChirp()?
 **/
void XUD_HAL_Mode_Signalling();

/**
 *  \brief   HAL function to set xCORE into data transfer mode
 *           (as opposed to "signalling" mode )
 *
 * TODO     Should this be combined with EnterMode_PeripheralHigh/FullSpeed()?
 **/
void XUD_HAL_Mode_DataTransfer();

/**
 * \brief   HAL function to set xCORE to correct USB device address
 * \param   address        The new address
 * \return  void
 **/
void XUD_HAL_SetDeviceAddress(unsigned char address);

/**
 * \brief   Enable USB funtionality in the device
 **/
void XUD_HAL_EnableUsb(unsigned pwrConfig);

/**
 * \brief  HAL funtion to get state of VBUS line, if any
 * \param  none
 * \return unsigned int non-zero if VBUS asserted, zero otherwise
 **/
unsigned int XUD_HAL_GetVBusState(void);

