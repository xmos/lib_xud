#include "xud.h"

/*  This is the global declaration of the resources struct used to keep 
    the resource IDs of this instance of XUD. Needs initialising if
    multiple instances of XUD are used and XUD_EXTERNAL_RESOURCES defined.
    This needs to be declared in C to avoid checks and is initialised
    before the call to XUD_Main */

#if XUD_EXTERNAL_RESOURCES
XUD_resources_t XUD_resources;
#endif
