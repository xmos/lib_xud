// Copyright 2017-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libusb.h"
#include "ptp.h"


/* USB Still image capture descriptors */
#define USB_DATA_PKT_SIZE 64    // USB image data packet size

/* the device's vendor and product id */
#define XMOS_BULK_VID 0x20b1
#define XMOS_BULK_PID 0xc1
#define XMOS_BULK_EP_IN 0x81
#define XMOS_BULK_EP_OUT 0x01

static libusb_device_handle *devh = NULL;

static int find_xmos_image_device() {
  libusb_device *dev;
  libusb_device **devs;
  int i = 0;
  
  libusb_get_device_list(NULL, &devs);

  while ((dev = devs[i++]) != NULL) {
    struct libusb_device_descriptor dev_desc;
    libusb_get_device_descriptor(dev, &dev_desc);
        if (dev_desc.idVendor == XMOS_BULK_VID && dev_desc.idProduct == XMOS_BULK_PID) {
            if (libusb_open(dev, &devh) < 0) {
                return -1;
            }
            break;
        }
  }

  libusb_free_device_list(devs, 1);

  return devh ? 0 : -1;
}


static int open_image_device() {
  int r = 1;

  r = libusb_init(NULL);
  if (r < 0) {
    fprintf(stderr, "failed to initialise libusb\n");
    return -1;
  }

  r = find_xmos_image_device();
  if (r < 0) {
    fprintf(stderr, "Could not find/open device\n");
    return -1;
  }

  return 0;
}


static int close_image_device() {
  libusb_release_interface(devh, 0);
  libusb_close(devh);
  libusb_exit(NULL);
  return 0;
}


static int image_device_io(int ep, char *bytes, int size, int timeout) {
  int actual_length;
  int r;
  r = libusb_bulk_transfer(devh, ep & 0xff, (unsigned char*)bytes, size, &actual_length, timeout);

  if (r == 0) {
    return 0;
  }
  else {
    return 1;
  }
}


static int read_image_device(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = image_device_io(XMOS_BULK_EP_IN, data, length, timeout);
  return result;
}


static int write_image_device(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = image_device_io(XMOS_BULK_EP_OUT, data, length, timeout);
  return result;
}



int main() {

  /* Allocate memory */
  PTPContainer operation_response;
  PTPObjectInfo obj_info;
  char *cmd_buf, *image_info, *image_data;

  cmd_buf = (char*) malloc(sizeof(PTPContainer));
  image_info = (char*) malloc(sizeof(PTPObjectInfo));
  image_data = (char*) malloc(USB_DATA_PKT_SIZE);


  /* Open USB image device */
  if (open_image_device() < 0)
    return 1;
  printf("XMOS USB image device opened .....\n");

  /* Open a session */
  operation_response.Code = PTP_OC_OpenSession;
  operation_response.SessionID = 0;
  operation_response.Transaction_ID = 0;
  operation_response.Param1 = 1;    //SessionID
  operation_response.Nparam = 1;
  memcpy (cmd_buf, &operation_response, sizeof(PTPContainer));
  write_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);

  /* Wait for response */
  read_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);
  memcpy (&operation_response, cmd_buf, sizeof(PTPContainer));

  if (operation_response.Code == PTP_RC_OK)
      printf ("Session opened ....\n");


  /* Initiate capture */
  operation_response.Code = PTP_OC_InitiateCapture;
  operation_response.SessionID = 1;
  operation_response.Transaction_ID = 1;
  operation_response.Param1 = 0;    //StorageID
  operation_response.Param2 = PTP_OFC_Undefined_0x3806;  //Raw image file
  operation_response.Nparam = 2;

  memcpy (cmd_buf, &operation_response, sizeof(PTPContainer));
  write_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);

  /* Wait for response */
  read_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);
  memcpy (&operation_response, cmd_buf, sizeof(PTPContainer));

  if (operation_response.Code == PTP_RC_OK)
      printf ("Image captured ....\n");


  /* Get image info */
  operation_response.Code = PTP_OC_GetObjectInfo;
  operation_response.SessionID = 1;
  operation_response.Transaction_ID = 2;
  operation_response.Param1 = 1;    //Object handle
  operation_response.Nparam = 1;

  memcpy (cmd_buf, &operation_response, sizeof(PTPContainer));
  write_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);

  /* Receive object info dataset */
  read_image_device((char *)image_info, USB_DATA_PKT_SIZE, 1000);
  read_image_device((char *)image_info+USB_DATA_PKT_SIZE, sizeof(PTPObjectInfo)-USB_DATA_PKT_SIZE, 1000);
  memcpy (&obj_info, image_info, sizeof(PTPObjectInfo));

  /* Wait for response */
  read_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);
  memcpy (&operation_response, cmd_buf, sizeof(PTPContainer));

  if (operation_response.Code == PTP_RC_OK)
      printf ("Image info got ....\n");

  uint rows = obj_info.ImagePixHeight;
  uint cols = obj_info.ImagePixWidth;
  uint pix_depth = obj_info.ImageBitDepth;
  char file_name[10];
  strcpy (file_name, obj_info.Filename);


  /* Get image */
  operation_response.Code = PTP_OC_GetObject;
  operation_response.SessionID = 1;
  operation_response.Transaction_ID = 3;
  operation_response.Param1 = 1;    //Object handle
  operation_response.Nparam = 1;

  memcpy (cmd_buf, &operation_response, sizeof(PTPContainer));
  write_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);

  /* Write image data packets to file */
  FILE *f;
  f = fopen(file_name, "w");

  if (f == NULL)
  {
      printf("Error opening file!\n");
      exit(1);
  }

  if (pix_depth==24)	//color image
      fprintf(f, "P3\n%d %d\n255\n", cols, rows);
  else
      fprintf(f, "P2\n%d %d\n255\n", cols, rows);

  int pkt_size = USB_DATA_PKT_SIZE;
  int nbytes, ncols;
  if (pix_depth==24){
      nbytes = rows*cols*3;
      ncols = cols*3;
  }
  else{
      nbytes = rows*cols;
      ncols = cols;
  }

  int index = 0;
  while (index < nbytes){
      if ((nbytes-index) < USB_DATA_PKT_SIZE)
          pkt_size = nbytes-index;
      read_image_device((char *)image_data, pkt_size, 1000);
      for (int i=0; i<pkt_size; i++){
          unsigned int data = (unsigned char)image_data[i];
          fprintf(f, "%d ", data);
          index++;
          if (index%ncols==0) fprintf(f, "\n");
      }
  }

  /* Wait for response */
  read_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);
  memcpy (&operation_response, cmd_buf, sizeof(PTPContainer));

  if (operation_response.Code == PTP_RC_OK){
      fclose(f);
      system("convert *.pnm image.jpg");
      printf("Image written to PNM and JPG files .....\n");
      printf("Displaying image .....\n");
      system("display image.jpg");
  }
  else
      printf ("Image not received correctly !!!!\n");


  /* Close the session */
  operation_response.Code = PTP_OC_CloseSession;
  operation_response.SessionID = 1;
  operation_response.Transaction_ID = 4;
  operation_response.Nparam = 0;

  memcpy (cmd_buf, &operation_response, sizeof(PTPContainer));
  write_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);

  /* Wait for response */
  read_image_device((char *)cmd_buf, sizeof(PTPContainer), 1000);
  memcpy (&operation_response, cmd_buf, sizeof(PTPContainer));

  if (operation_response.Code == PTP_RC_OK)
      printf ("Session closed ....\n");


  /* Close USB image device */
  close_image_device();
  printf("XMOS USB image device closed .....\n");
  return 1;
}
