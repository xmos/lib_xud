#include <string.h>
#include "xud.h"

/*  This is the global declaration of the resources struct used to keep 
    the resource IDs of this instance of XUD. Needs initialising if
    multiple instances of XUD are used and XUD_EXTERNAL_RESOURCES defined.
    This needs to be declared in C to avoid checks and is initialised
    before the call to XUD_Main */

#if XUD_EXTERNAL_RESOURCES
XUD_resources_t XUD_resources = {0};
#endif


extern XUD_resources_t XUD_resources;

void init_xud_resources(XUD_resources_t * resources)
{
    memcpy(&XUD_resources, resources, sizeof(XUD_resources_t));
}