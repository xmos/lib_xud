#include "xud.h"


void XUD_HAL_EnterMode_PeripheralFullSpeed();
void XUD_HAL_EnterMode_PeripheralChirp();
void XUD_HAL_EnterMode_PeripheralHighSpeed();


typedef struct XUD_HAL_t
{
    in port p_usb_fl0;
    in port p_usb_fl1;


} XUD_HAL_t;

typedef enum XUD_LineState_t 
{
    XUD_LINESTATE_SE0,
    XUD_LINESTATE_J,
    XUD_LINESTATE_K,
    XUD_LINESTATE_INVALID
} XUD_LineState_t;


int XUD_HAL_GetLineState(/*XUD_HAL_t &xudHal*/);


void XUD_HAL_Mode_PowerSig();
void XUD_HAL_Mode_DataTransfer();
