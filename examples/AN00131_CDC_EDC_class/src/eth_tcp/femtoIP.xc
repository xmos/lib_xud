// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xclib.h>
#include "femtoIP.h"
#include "ethernet.h"

void patchIPHeader(unsigned int packet[], int packetLength, int to, int isTCP) {
    if (to == 0) {
        to = ipAddressClient;
    }
    if ((to & 0xff000000) == 0xe0000000) {
        packet[0] = 0x005e0001;
        packet[1] = 0x2200fb00;
    } else {
        for(int i = 0; i < 6; i++) {
            (packet, char[])[i] = macAddressClient[i];
        }
    }
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressServer[i];
    }
    packet[3] = 0x00450008;
    packet[4] = 0xff630000 | byterev(packetLength) >> 16;
    packet[5] = 0x11010000 | (isTCP  ? 0x00100000 : 0x00010000); // TTL > 1 for TCP.
    (packet, unsigned char[])[23] = isTCP ? 0x06 : 0x11;
    (packet, unsigned short[])[12] = 0;
    (packet, unsigned short[])[13] = ((unsigned)byterev(ipAddressServer));
    (packet, unsigned short[])[14] = ((unsigned)byterev(ipAddressServer))>> 16;
    (packet, unsigned short[])[15] = ((unsigned)byterev(to));
    (packet, unsigned short[])[16] = ((unsigned)byterev(to))>> 16;
    onesChecksum(0, (packet, unsigned short[]), 7, 16, 12);
}
