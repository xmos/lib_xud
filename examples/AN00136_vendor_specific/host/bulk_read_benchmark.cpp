// Copyright 2017-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include "usb.h"
#include <Windows.h>
#error ERROR: This application is not supported on windows
#else
#include "libusb.h"
#include <pthread.h>
#include <sys/timeb.h>
#endif

/* the device's vendor and product id */
#define XMOS_BULK_VID 0x20b1
#define XMOS_BULK_PID 0xb1
#define XMOS_BULK_EP_IN 0x81
#define XMOS_BULK_EP_OUT 0x01

#ifdef _WIN32
#define NUMTRANSFERS 10
#define PACKET_BUFFER_SIZE 128
#else
#define NUMTRANSFERS 4
#define PACKET_BUFFER_SIZE 128
#define TRANSFER_BUFFER_SIZE 1024 * 64
#endif

unsigned int start = 0;
unsigned int count = 0;

#ifdef _WIN32
static usb_dev_handle *devh = NULL;

static int find_xmos_bulk_device(unsigned int id) {
  struct usb_bus *bus;
  struct usb_device *dev;

  for (bus = usb_get_busses(); bus && !devh; bus = bus->next) {
    for (dev = bus->devices; dev; dev = dev->next) {
      if ((dev->descriptor.idVendor == XMOS_BULK_VID) &&
              (dev->descriptor.idProduct == XMOS_BULK_PID)) {
          devh = usb_open(dev);
          break;
        }
      }
    }

  if (!devh)
    return -1;
  
  return 0;
}

static int open_bulk_device() {
  int r = 1;
  
  usb_init();
  usb_find_busses(); /* find all busses */
  usb_find_devices(); /* find all connected devices */

  r = find_xmos_bulk_device(0);
  if (r < 0) {
    fprintf(stderr, "Could not find/open device\n");
    return -1;
  }
 
  r = usb_set_configuration(devh, 1);
  if (r < 0) {
    fprintf(stderr, "Error setting config 1\n");
    usb_close(devh);
    return -1;
  }

  r = usb_claim_interface(devh, 0);
  if (r < 0) {
    fprintf(stderr, "Error claiming interface %d %d\n", 0, r);
    return -1;
  }

  return 0;
}

static int close_bulk_device() {
  usb_release_interface(devh, 0);
  usb_close(devh);
  return 0;
}

static int getMilliCount() {
  return GetTickCount();
}

static int getMilliSpan(int startTime) {
  int milliSpan = GetTickCount() - startTime;
  return milliSpan;
}

void *contexts[NUMTRANSFERS];
unsigned int data[NUMTRANSFERS][PACKET_BUFFER_SIZE];

static int allocate_transfers() {

  for (int i = 0; i < NUMTRANSFERS; i++) {
    usb_bulk_setup_async(devh, &contexts[i], XMOS_BULK_EP_IN);
  }

  return 0;
}

static int submit_transfers() {
  for (int i = 0; i < NUMTRANSFERS; i++) {
    usb_submit_async(contexts[i], (char *)&data[i][0], PACKET_BUFFER_SIZE*4);
  }

  return 0;
}

static int process_transfers() {
  
  if (start == 0) {
    start = getMilliCount();
    count = 0;
  } else {

    if (getMilliSpan(start) > 1000) {
      printf("Read transfer rate %.2f MB/s\n", (float)count / (float)(1024*1024));
      start = getMilliCount();
      count = 0;
    }

    for (int i = 0; i < NUMTRANSFERS; i++) {
      usb_reap_async(contexts[i], 5000);
      usb_submit_async(contexts[i], (char *)&data[i][0], PACKET_BUFFER_SIZE*4);
      count += PACKET_BUFFER_SIZE * 4;
    }
  }
  return 0;
}

static int complete_transfers() {
  for (int i = 0; i < NUMTRANSFERS; i++) {
    usb_reap_async(contexts[i], 5000);
    usb_free_async(&contexts[i]);
  }

  return 0;
}

#else 

static libusb_device_handle *devh = NULL;
static libusb_context* ctx = NULL;
static struct libusb_transfer** transfers = NULL;

pthread_t transfer_thread;

static int find_xmos_bulk_device(unsigned int id) {
  libusb_device *dev;
  libusb_device **devs;
  int i = 0;
  int found = 0;
  
  libusb_get_device_list(NULL, &devs);

  while ((dev = devs[i++]) != NULL) {
    struct libusb_device_descriptor desc;
    libusb_get_device_descriptor(dev, &desc); 
    if (desc.idVendor == XMOS_BULK_VID && desc.idProduct == XMOS_BULK_PID) {
      if (found == id) {
        if (libusb_open(dev, &devh) < 0) {
          return -1;
        }
        break;
      }
      found++;
    }
  }

  libusb_free_device_list(devs, 1);

  return devh ? 0 : -1;
}

static int open_bulk_device() {
  int r = 1;

  r = libusb_init(&ctx);
  if (r < 0) {
    fprintf(stderr, "failed to initialise libusb\n");
    return -1;
  }

  r = find_xmos_bulk_device(0);
  if (r < 0) {
    fprintf(stderr, "Could not find/open device\n");
    return -1;
  }

  r = libusb_claim_interface(devh, 0);
  if (r < 0) {
    fprintf(stderr, "Error claiming interface %d %d\n", 0, r);
    return -1;
  }

  return 0;
}

static int close_bulk_device() {
  libusb_release_interface(devh, 0);
  libusb_close(devh);
  libusb_exit(NULL);
  return 0;
}

static int getMilliCount() {
  timeb tb;
  ftime(&tb);
  int startTime = tb.millitm + (tb.time & 0xfffff) * 1000;
  return startTime;
}

static int getMilliSpan( int startTime ) {
  int milliSpan = getMilliCount() - startTime;
  if (milliSpan < 0)
    milliSpan += 0x100000 * 1000;
  return milliSpan;
}

static void libusbCallback(struct libusb_transfer* transfer)
{
  if (start == 0)
  {
    start = getMilliCount();
    count = 0;
  }
  else
  {
    if (getMilliSpan(start) > 1000)
    {
      printf("Read transfer rate %.2f MB/s\n", (float)count / (float)(1024*1024));
      start = getMilliCount();
      count = 0;
    }
  }

  count += transfer->actual_length;
  libusb_submit_transfer(transfer);
}

void *contexts[NUMTRANSFERS];
unsigned int data[NUMTRANSFERS][PACKET_BUFFER_SIZE];

static int allocate_transfers() {
  if (transfers == NULL) {
    transfers = (struct libusb_transfer**)malloc(NUMTRANSFERS * sizeof (struct libusb_transfer*));
    if (transfers == NULL) {
       printf("Error allocating transfers.  Exitting...\n");
       return -1;
    }

    for (int i = 0; i < NUMTRANSFERS; i++) {
      transfers[i] = libusb_alloc_transfer(0);
      if (transfers[i] == NULL) {
        printf("Error allocating transfer....\n");
        return -1;
      }
      libusb_fill_bulk_transfer(transfers[i], 
                                devh, 
                                XMOS_BULK_EP_IN, 
                                (unsigned char*)malloc(TRANSFER_BUFFER_SIZE * sizeof(unsigned char)), 
                                TRANSFER_BUFFER_SIZE, 
                                (libusb_transfer_cb_fn)&libusbCallback, 
                                NULL, 
                                0);

      if (transfers[i]->buffer == NULL) {
        printf("Error allocating buffer.\n");
        return -1;
      }
    }

    return 0;
  } else {
    return -1;
  }

  return 0;
}

static int submit_transfers() {
  for (int i = 0; i < NUMTRANSFERS; i++) {
    if (libusb_submit_transfer(transfers[i]) < 0) {
      libusb_free_transfer(transfers[i]);
      fprintf(stderr, "Error submitting transfer\n");
    } 
  }

  return 0;
}

static int process_transfers() {
  unsigned int ret = 0;
  while(1){
    ret = libusb_handle_events(ctx);
  }
  return 0;
}

static int complete_transfers() {
  for (int i = 0; i < NUMTRANSFERS; i++) {
    libusb_free_transfer(transfers[i]);
  }
  return 0;
}

#endif

int main(int argc, char **argv) {

  if (open_bulk_device() < 0)
    return 1;

  printf("XMOS Bulk USB device opened .....\n");

  allocate_transfers();
  submit_transfers();

  while (1) {
    process_transfers();
  }

  complete_transfers();
 
  if (close_bulk_device() < 0)
    return 1;

  printf("XMOS Bulk USB device closed .....\n");
  return 0;
}
