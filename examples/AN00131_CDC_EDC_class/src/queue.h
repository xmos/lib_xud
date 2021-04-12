// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef QUEUE_H_
#define QUEUE_H_


#define QUEUE_LENGTH 4

typedef struct queue {
    int rd, wr, len;
    struct {
        int packet, from, len;
    } data[QUEUE_LENGTH];
} Queue_t;

/* Initializes the Circular Queue variables */
void qInit(struct queue &q);

/* Gets index of the data waiting in the queue and also removes it from the queue */
int qGet(struct queue &q) ;

/* Adds a packet id on the queue */
int qPut(struct queue &q, int packet, int len);

/* Gets the index of the data waiting in the queue but doesn't remove it */
int qPeek(struct queue &q) ;

/* Checks if queue is empty, Use this function before calling 'qGet()' */
int qIsEmpty(struct queue &q) ;

/* Checks if queue is full, Use this function before calling 'qPut()' */
int qIsFull(struct queue &q) ;


#endif /* QUEUE_H_ */
