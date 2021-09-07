#include "xud.h"

/* Legacy API support */
__attribute__((deprecated)) int XUD_Manager(chanend c_epOut[], int noEpOut,
                chanend c_epIn[], int noEpIn,
                NULLABLE_RESOURCE(chanend, c_sof),
                XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[],
                NULLABLE_RESOURCE(port, p_usb_rst),
                NULLABLE_RESOURCE(clock, clk),
                unsigned rstMask,
                XUD_BusSpeed_t desiredSpeed,
                XUD_PwrConfig pwrConfig)
{
    return XUD_Main(c_epOut, noEpOut, c_epIn, noEpIn, c_sof, epTypeTableOut, epTypeTableIn, desiredSpeed, pwrConfig);
}
