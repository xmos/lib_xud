#include <xccompat.h>

#include "xud.h"
#include "usb_video.h"


int XUD_Main_wrapper(chanend c_epOut[], int noEpOut,
                chanend c_epIn[], int noEpIn,
                NULLABLE_RESOURCE(chanend, c_sof),
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[],
                XUD_BusSpeed_t desiredSpeed,
                XUD_PwrConfig pwrConfig);

void Endpoint0_wrapper(chanend chan_ep0_out, chanend chan_ep0_in, unsigned short PID);
void VideoEndpointsHandler_wrapper(chanend c_epint_in, chanend c_episo_in, unsigned instance);
