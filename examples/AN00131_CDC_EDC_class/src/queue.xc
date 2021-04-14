// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <assert.h>
#include <stdio.h>
#include "queue.h"
#include "packet_buffer.h"

void qInit(struct queue &q) {
    q.len = 0;
    q.rd = 0;
    q.wr = 0;
}

int qGet(struct queue &q) {
    int r = q.rd;
    if (qIsEmpty(q)) {
        assert(0);
    }
    q.len--;
    q.rd++;
    if (q.rd == QUEUE_LENGTH) {
        q.rd = 0;
    }
    return r;
}

static void pq(struct queue &q) {
    printf("rd: %d, wr: %d len %d\n", q.rd, q.wr, q.len);
    for(int i = 0; i < QUEUE_LENGTH; i++) {
        int p = q.data[i].packet;
        int l = q.data[i].len;
        printf("Buf %d (%4d bytes) words %08x %08x %08x ... %08x %08x\n", p, l, packetBuffer[p][0],  packetBuffer[p][1],  packetBuffer[p][2],  packetBuffer[p][(l>>2)-2],  packetBuffer[p][(l>>2)-1]);
    }
}

int qPut(struct queue &q, int packet, int len) {
    int tail = q.wr;
    if (qIsFull(q)) {
        printf("Inserting %d in full queue\n", packet);
        pq(q);
        assert(0);
    }
    for(int k = 0; k < q.len; k++) {
        if (q.data[(q.rd+k)%QUEUE_LENGTH].packet == packet) {
            printf("Inserting duplicate %d\n", packet);
            pq(q);
            assert(0);
        }
    }
    q.data[tail].from = 0;
    q.data[tail].len = len;
    q.data[tail].packet = packet;
    q.len++;
    q.wr++;
    if (q.wr == QUEUE_LENGTH) {
        q.wr = 0;
    }
    return tail;
}

int qPeek(struct queue &q) {
    return q.rd;
}

int qIsEmpty(struct queue &q) {
    return q.len == 0;
}

int qIsFull(struct queue &q) {
    return q.len == QUEUE_LENGTH;
}

