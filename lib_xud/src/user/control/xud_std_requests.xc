// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <print.h>

#include "xud_std_requests.h"

void USB_ParseSetupPacket(unsigned char b[], USB_SetupPacket_t &p)
{
    // Byte 0: bmRequestType.
    p.bmRequestType.Recipient = b[0] & 0x1f;
    p.bmRequestType.Type      = (b[0] & 0x60) >> 5;
    p.bmRequestType.Direction = b[0] >> 7;

    // Byte 1:  bRequest
    p.bRequest = b[1];

    // Bytes [2:3] wValue
    p.wValue = (b[3] << 8) | (b[2]);

    // Bytes [4:5] wIndex
    p.wIndex = (b[5] << 8) | (b[4]);

    // Bytes [6:7] wLength
    p.wLength = (b[7] << 8) | (b[6]);
}

void USB_ComposeSetupBuffer(USB_SetupPacket_t sp, unsigned char buffer[])
{
    buffer[0] = sp.bmRequestType.Recipient
                  | (sp.bmRequestType.Type << 5)
                  | (sp.bmRequestType.Direction << 7);

    buffer[1] = sp.bRequest;

    buffer[2] = sp.wValue & 0xff;
    buffer[3] = (sp.wValue & 0xff00)>>8;

    buffer[4] = sp.wIndex & 0xff;
    buffer[5] = (sp.wIndex & 0xff00)>>8;

    buffer[6] = sp.wLength & 0xff;
    buffer[7] = (sp.wLength & 0xff00)>>8;
}

void USB_PrintSetupPacket(USB_SetupPacket_t sp)
{
    printstr("Setup data\n"); //NOCOVER
    printstr("bmRequestType.Recipient: "); //NOCOVER
    printhexln(sp.bmRequestType.Recipient); //NOCOVER
    printstr("bmRequestType.Type: "); //NOCOVER
    printhexln(sp.bmRequestType.Type); //NOCOVER
    printstr("bmRequestType.Direction: "); //NOCOVER
    printhexln(sp.bmRequestType.Direction); //NOCOVER
    printstr("bRequest: "); //NOCOVER
    printhexln(sp.bRequest); //NOCOVER
    printstr("bmRequestType.wValue: "); //NOCOVER
    printhexln(sp.wValue); //NOCOVER
    printstr("bmRequestType.wIndex: "); //NOCOVER
    printhexln(sp.wIndex); //NOCOVER
    printstr("bmRequestType.wLength: "); //NOCOVER
    printhexln(sp.wLength); //NOCOVER
}
