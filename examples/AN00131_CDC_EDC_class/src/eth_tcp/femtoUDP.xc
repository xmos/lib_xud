// Copyright (c) 2015-2017, XMOS Ltd, All rights reserved

#include <xclib.h>
#include <print.h>
#include "femtoUDP.h"
#include "femtoIP.h"
#include "ethernet.h"

void patchUDPHeader(unsigned int packet[], int packetHighestByteIndex, int to, int srcPortRev, int destPortRev) {
    int packetLength = packetHighestByteIndex - 34;

    patchIPHeader(packet, packetLength + 20, to, 0);

    (packet, unsigned short[])[17] = srcPortRev;
    (packet, unsigned short[])[18] = destPortRev;
    (packet, unsigned short[])[19] = byterev(packetLength) >> 16;
    (packet, unsigned short[])[20] = 0; // checksum to be patched.

    onesChecksum(0x0011 + packetLength,
                 (packet, unsigned short[]), 13, (packetHighestByteIndex-1)>>1, 20);
}
