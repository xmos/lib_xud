// Copyright 2017-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include "usb.h"
#else
#include "libusb.h"
#endif

/* the device's vendor and product id */
#define XMOS_BULK_VID 0x20b1
#define XMOS_BULK_PID 0xb1
#define XMOS_BULK_EP_IN 0x81
#define XMOS_BULK_EP_OUT 0x01

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

int read_bulk_device(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = usb_bulk_read(devh, XMOS_BULK_EP_IN, data, length, timeout);
  return result;
}

int write_bulk_device(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = usb_bulk_write(devh, XMOS_BULK_EP_OUT, data, length, timeout);
  return result;
}

// Timing code
#include <Windows.h>

static int getMilliCount() {
  // Rolls over every 49.7 days
  return GetTickCount();
}

static int getMilliSpan(int startTime) {
  int milliSpan = GetTickCount() - startTime;
  return milliSpan;
}

#else 
static libusb_device_handle *devh = NULL;

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

  r = libusb_init(NULL);
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

static int bulk_device_io(int ep, char *bytes, int size, int timeout) {
  int actual_length;
  int r;
  r = libusb_bulk_transfer(devh, ep & 0xff, (unsigned char*)bytes, size, &actual_length, timeout);

  if (r == 0) {
    return 0;
  } else {
    return 1;
  }
}

static int read_bulk_device(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = bulk_device_io(XMOS_BULK_EP_IN, data, length, timeout);
  return result;
}

static int write_bulk_device(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = bulk_device_io(XMOS_BULK_EP_OUT, data, length, timeout);
  return result;
}

// Timing code
#include <sys/timeb.h>

static int getMilliCount() {
  // Something like GetTickCount but portable
  // It rolls over every ~ 12.1 days (0x100000/24/60/60)
  // Use getMilliSpan to correct for rollover
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
#endif

#define BUFFER_SIZE 128
int main(int argc, char **argv) {

  if (open_bulk_device() < 0)
    return 1;
  printf("XMOS Bulk USB device opened .....\n");

  while (1);

  unsigned buffers = 1000;
  if (argc > 1)
    buffers = atoi(argv[1]);

  int failed = 0;
  unsigned int data[BUFFER_SIZE];
  unsigned expected = 10;

  printf("Timing write/read of %d 512-byte buffers.....\n", buffers);
  int startTime = getMilliCount();
  for (int j = 0; j < buffers; j++) {
    // No need to initialise the data unless it is being checked
    for (int i = 0; i < BUFFER_SIZE; i++) {
      data[i] = expected + i;
    }
    write_bulk_device((char *)data, BUFFER_SIZE*4, 1000);
    read_bulk_device((char *)data, BUFFER_SIZE*4, 1000);

    // Only check expected results if values are written and read
    // Device increments by one
    expected++;
    for (int i = 0; i < BUFFER_SIZE; i++) {
      if (data[i] != (expected + i)) {
        printf("*** At data[%d]: Expected %d, got %d\n", i, expected, data[i]);
        failed = 1;
        break;
      }
    }
  }
  int milliSec = getMilliSpan(startTime);
  double megaBytes =  ((double)buffers * (128 * 4)) / (1024 * 1024) * 2.0;
  double megaBytesPerSec = (megaBytes / (double)milliSec) * 1000;
  printf("%d ms (%.2f MB/s)\n", milliSec, megaBytesPerSec);

  if (!failed)
    printf("XMOS Bulk USB device data processed correctly .....\n");

  if (close_bulk_device() < 0)
    return 1;

  printf("XMOS Bulk USB device closed .....\n");
  return failed;
}
