// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef PACKET_BUFFER_H_
#define PACKET_BUFFER_H_

#define NULL_PACKET 0xFFFFFFFF
#define NUM_PACKETS 8

#define MAX_FRAME_SIZE 1516

/* Buffer to hold the Ethernet frames */
extern unsigned int packetBuffer[NUM_PACKETS][MAX_FRAME_SIZE/sizeof(int)+2];

/* Initialize all the free buffers */
void packetBufferInit(void);

/* Allocate a free buffer and return the buffer id */
int  packetBufferAlloc(void);

/* Free up a buffer corresponding to the buffer id */
void packetBufferFree(int buffer_id);

/* Copy stream of bytes from an array to the packet buffer */
void packetCopyInto(int packetNum, char * unsafe from, int len);


#endif /* PACKET_BUFFER_H_ */
