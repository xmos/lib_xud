// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "packet_buffer.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

unsigned int packetBuffer[NUM_PACKETS][1516/sizeof(int)+2];
static int freeList;

void packetBufferInit() {
    for(int i = 0; i < NUM_PACKETS; i++) {
        packetBuffer[i][0] = i+1;
        packetBuffer[i][1] = ~(i*i);
    }
    packetBuffer[NUM_PACKETS-1][0] = NULL_PACKET;
    freeList = 0;
}

int packetBufferAlloc() {
    int i = freeList;
    assert(i != NULL_PACKET); // buffer overflow
    assert(packetBuffer[i][1] == ~(i*i));
    freeList = packetBuffer[freeList][0];
    return i;
}

void packetBufferFree(int buffer_id) {
    packetBuffer[buffer_id][0] = freeList;
    packetBuffer[buffer_id][1] = ~(buffer_id*buffer_id);
    freeList = buffer_id;
}

void packetCopyInto(int packetNum, char * unsafe from, int len) {
    memcpy(packetBuffer[packetNum], from, len);
}
