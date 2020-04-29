#include "xud.h"
/** 
 * @file   XUD_HAL.h 
 * \brief   USB HAL Layer 
**/

/** 
 * \enum    XUD_LineState_t
 * \brief   USB Line States 
 */
typedef enum XUD_LineState_t 
{
    XUD_LINESTATE_SE0,      /**< SE0 State */
    XUD_LINESTATE_J,        /**< J State */
    XUD_LINESTATE_K,        /**< K State */
    XUD_LINESTATE_INVALID   /**< Invalid bus state both lines high **/
} XUD_LineState_t;


void XUD_HAL_EnterMode_PeripheralChirp();
void XUD_HAL_EnterMode_PeripheralFullSpeed();
void XUD_HAL_EnterMode_PeripheralHighSpeed();

/**
 * \brief   Get current linestate status 
 * \return  XUD_LineState_t representing current line status 
**/
XUD_LineState_t XUD_HAL_GetLineState(/*XUD_HAL_t &xudHal*/);

/**
 * \brief   Wait for a change in linestate and return, or timeout
 * \param   Reference to current linestate (updated with new linestate 
 * \return  1 for timed out, otherwise 0
**/
unsigned XUD_HAL_WaitForLineStateChange(XUD_LineState_t &currentLs, unsigned timeout);

/**
 *  \brief   HAL function to set xCORE into signalling mode 
 *           (as opposed to "data transfer" mode)
 *
 * TODO     Should this be combined with EnterMode_PeripheralChirp()?     
 **/
void XUD_HAL_Mode_PowerSig();

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
