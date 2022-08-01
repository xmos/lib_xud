// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xclib.h>
#include <print.h>
#include "femtoTCP.h"
#include "femtoIP.h"
#include "string.h"
#include "http.h"
#include "ethernet.h"
#include "queue.h"
#include "packet_buffer.h"

unsigned int streamDestPortRev;
unsigned int streamSourcePortRev;

struct stream_t {
    unsigned int portNum;
    unsigned int sequenceNumber;
    unsigned int ackNumber;
} stream[4];

int stream_index = 0;
int stream_index_old = 0;

#define FIN 0x01
#define SYN 0x02
#define PSH 0x08
#define ACK 0x10

#define HEADERS_LEN_TCP 54

void patchTCPHeader(unsigned int packet[], int len, int flags) {
    int totalShorts;
    patchIPHeader(packet, 20 + 20 + len, 0, 1);
    (packet, unsigned short[])[17] = streamDestPortRev;
    (packet, unsigned short[])[18] = streamSourcePortRev;
    (packet, unsigned short[])[20] = byterev(stream[stream_index].sequenceNumber) >> 16;
    (packet, unsigned short[])[19] = byterev(stream[stream_index].sequenceNumber);
    (packet, unsigned short[])[22] = byterev(stream[stream_index].ackNumber) >> 16;
    (packet, unsigned short[])[21] = byterev(stream[stream_index].ackNumber);
    (packet, unsigned short[])[23] = 0x0050 | flags << 8;
    (packet, unsigned short[])[24] = byterev(1500) >> 16;
    (packet, unsigned short[])[25] = 0;
    (packet, unsigned short[])[26] = 0;
    totalShorts = 27 + ((len+1)>>1);
    onesChecksum(0x0006 + 20 + len /* packetType + packetLength */,
                 (packet, unsigned short[]), 13, totalShorts - 1, 25);
}

void tcpString(char s[], unsigned int rsp_packet[], unsigned &rsp_len) {

    int len = strlen(s);

    for(int i = 0; i < len; i++) {
        (rsp_packet, unsigned char[])[HEADERS_LEN_TCP+i] = s[i];
    }
    (rsp_packet, unsigned char[])[HEADERS_LEN_TCP+len] = 0;

    patchTCPHeader(rsp_packet, len, ACK | PSH | FIN);

    rsp_len = HEADERS_LEN_TCP + len;
    stream[stream_index].sequenceNumber += len;
    return;
}

void processTCPPacket(unsigned int packet[], unsigned len, unsigned int rsp_packet[], unsigned &rsp_len) {
    int sourcePortRev = (packet, unsigned short[])[17];
    int destPortRev = (packet, unsigned short[])[18];
    unsigned int sequenceNumberRev = (((packet, unsigned short[])[20])<<16) |
                            ((packet, unsigned short[])[19]);
    unsigned int ackNumberRev = (((packet, unsigned short[])[22])<<16) |
                       ((packet, unsigned short[])[21]);
    unsigned int packetLength;
    unsigned int headerLength;

    streamSourcePortRev = sourcePortRev;
    streamDestPortRev = destPortRev;
    /* Keep compiler happy */
    ackNumberRev = ackNumberRev;

    /* Chrome browser opens connections from multiple TCP ports, so it is mandatory to remember
     * the sequence and ACK numbers for each port connenction seperately */
    stream_index = -1;
    for(int i=0; i<4; i++) {
        if(stream[i].portNum == sourcePortRev) {
            stream_index = i;
        }
    }

    if(stream_index == -1) {
        /* No record found */
        stream_index = stream_index_old++;
        if(stream_index_old > 3) { stream_index_old = 0;}
        stream[stream_index].portNum = sourcePortRev;
        stream[stream_index].sequenceNumber = 0;
        stream[stream_index].ackNumber = 0;
    }

    if (packet[11] & 0x02000000) { // SYN
        stream[stream_index].ackNumber = byterev(sequenceNumberRev) + 1;
        stream[stream_index].sequenceNumber = 0; // could be random

        patchTCPHeader(rsp_packet, 0, SYN | ACK);
        stream[stream_index].sequenceNumber++;
        rsp_len = HEADERS_LEN_TCP;
        return;
    }
    if (packet[11] & 0x01000000) { // FIN, send an ACK.

        stream[stream_index].sequenceNumber++;
        stream[stream_index].ackNumber++;

        patchTCPHeader(rsp_packet, 0, ACK);
        rsp_len = HEADERS_LEN_TCP;
        return;
    }
    if (packet[11] & 0x10000000) { // ACK
        ; // required later to send long responses.
    }


    packetLength = byterev((packet, unsigned short[])[8]) >> 16;
    headerLength = ((packet, unsigned char[])[46])>>2;
    packetLength -= headerLength + 20;

    stream[stream_index].ackNumber += packetLength;

    if (packetLength > 0) {
        if (destPortRev == 0x5000) { // HTTP
            httpProcess(packet, 34 + headerLength, packetLength, rsp_packet, rsp_len);
        }
    }
    if (packet[11] & 0x08000000) { // PSH
        ; // Can safely be ignored.
    }
}
