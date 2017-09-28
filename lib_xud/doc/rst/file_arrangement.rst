File Arrangement
================

The following list gives a brief description of the files that make up
the XUD layer:

include/xud.h
    User defines and functions for the XUD library.

lib/xs1b/libxud_l.a
    Library for L-Series devices.

lib/xs1b/libxud_u.a
    Library for U-Series devices.

lib/xs1b/libxud_g.a
    Library for G-Series devices.

src/XUD_EpFunctions.xc
    User functions that control the XUD library.

src/XUD_EpFuncs.S
    Assembler stubs of access functions.

src/XUD_Ports.xc
    Definition of port mapping.
