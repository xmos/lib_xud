
#include <xs1.h>

void XUD_Sup_Delay(unsigned delay)
{
    timer t;
    unsigned time;

    t :> time;
    time += delay;
    t when timerafter(time) :> void;

}

