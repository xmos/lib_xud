// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <string.h>
#include <stdint.h>
#include "xud_device.h"
#include "ptp.h"

/* USB endpoint defines */
#define XUD_EP_COUNT_OUT   2
#define XUD_EP_COUNT_IN    2

/* Endpoint type tables - informs XUD what the transfer types for each Endpoint in use and also
 * if the endpoint wishes to be informed of USB bus resets
  */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL};

#define USB_DATA_PKT_SIZE 64    // USB data packet size

/* Image type */
enum {
    GRAY, COLOR
};
#define IMG_TYPE GRAY

/* Image pixel component starting values */
#define ST_GRAY 0
#define ST_RED 0
#define ST_GREEN 100
#define ST_BLUE 200

/* Image size */
#define IMG_HEIGHT 200
#define IMG_WIDTH 250

/* Prototype for Endpoint0 function in endpoint0.xc */
void Endpoint0(chanend c_ep0_out, chanend c_ep0_in);


/*
 * This function responds to the USB image data and control requests from the host
 */

void bulk_endpoint(chanend chan_ep_from_host, chanend chan_ep_to_host)
{
    PTPContainer operation_response;
    PTPObjectInfo image_info;
    unsigned char cmd_buf[sizeof(PTPContainer)];
    unsigned char data_buf[USB_DATA_PKT_SIZE];
    unsigned char info_buf[sizeof(PTPObjectInfo)];
    unsigned cmd_length;
    XUD_Result_t result;

    XUD_ep ep_from_host = XUD_InitEp(chan_ep_from_host);
    XUD_ep ep_to_host = XUD_InitEp(chan_ep_to_host);


    while(1)
    {
        /* Receive the operation request from the host */
        if((result = XUD_GetBuffer(ep_from_host, cmd_buf, cmd_length)) == XUD_RES_RST)
        {
            XUD_ResetEndpoint(ep_from_host, ep_to_host);
            continue;
        }
        memcpy (&operation_response, cmd_buf, sizeof(PTPContainer));

        /* Process the command of custom simple protocol similar to PTP */
        uint16_t opcode = operation_response.Code;
        switch (opcode){

        case PTP_OC_OpenSession:
        case PTP_OC_InitiateCapture:
        case PTP_OC_CloseSession:
            operation_response.Code = PTP_RC_OK;
            break;

        case PTP_OC_GetObjectInfo:
            image_info.ObjectFormat = PTP_OFC_Undefined_0x3806;
            image_info.ImagePixHeight = IMG_HEIGHT;
            image_info.ImagePixWidth = IMG_WIDTH;
            if (IMG_TYPE==COLOR)
                image_info.ImageBitDepth = 24;
            else
                image_info.ImageBitDepth = 8;
            strcpy(image_info.Filename, "image.pnm");

            /* Send image info */
            memcpy (info_buf, &image_info, sizeof(PTPObjectInfo));
            if((result = XUD_SetBuffer(ep_to_host, info_buf, USB_DATA_PKT_SIZE)) == XUD_RES_RST)
            {
                XUD_ResetEndpoint(ep_from_host, ep_to_host);
                break;
            }
            if((result = XUD_SetBuffer(ep_to_host, info_buf+USB_DATA_PKT_SIZE, sizeof(PTPObjectInfo)-USB_DATA_PKT_SIZE)) == XUD_RES_RST)
            {
                XUD_ResetEndpoint(ep_from_host, ep_to_host);
                break;
            }

            operation_response.Code = PTP_RC_OK;
            break;

         case PTP_OC_GetObject:

             /* Generate image */
             int ncols = IMG_WIDTH;
             if (IMG_TYPE==COLOR) ncols = 3*IMG_WIDTH;

             int index = 0;
             int pkt_size = USB_DATA_PKT_SIZE;
             while (index < (IMG_HEIGHT*ncols)){

                 if (((IMG_HEIGHT*ncols)-index) < USB_DATA_PKT_SIZE)
                     pkt_size = (IMG_HEIGHT*ncols)-index;
                 for (int i=0; i<pkt_size; i++){
                     if (IMG_TYPE==COLOR){
                         switch (index%3){
                         case 0: data_buf[i] = ST_RED+(index%ncols); break;
                         case 1: data_buf[i] = ST_GREEN+(index%ncols); break;
                         case 2: data_buf[i] = ST_BLUE+(index%ncols); break;
                         }
                     }
                     else data_buf[i] = ST_GRAY+(index%ncols);
                     index++;
                 }
                 /* Send the image data packet to the host */
                 if((result = XUD_SetBuffer(ep_to_host, data_buf, pkt_size)) == XUD_RES_RST)
                 {
                     XUD_ResetEndpoint(ep_from_host, ep_to_host);
                     break;
                 }
             }
             operation_response.Code = PTP_RC_OK;
             break;

         default:
             operation_response.Code = PTP_RC_Undefined;
             break;

        }

        /* Send response */
        operation_response.Nparam = 0;
        memcpy (cmd_buf, &operation_response, sizeof(PTPContainer));
        if((result = XUD_SetBuffer(ep_to_host, cmd_buf, sizeof(PTPContainer))) == XUD_RES_RST)
        {
            XUD_ResetEndpoint(ep_from_host, ep_to_host);
        }

    }

}


/* The main function runs three cores: the XUD manager, Endpoint 0, and USB image endpoints.
 * An array of channels is used for both IN and OUT endpoints, endpoint zero requires both,
 * USB bulk data IN and OUT endpoints are used to receive operation request and send image data and response.
 */
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        on USB_TILE: XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        on USB_TILE: Endpoint0(c_ep_out[0], c_ep_in[0]);

        on USB_TILE: bulk_endpoint(c_ep_out[1], c_ep_in[1]);

    }

    return 0;
}
