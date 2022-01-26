// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <xcore/parallel.h>
#include <xcore/chanend.h>
#include <xcore/channel.h>
#include <xcore/hwtimer.h>
#include <xcore/select.h>
#include "xud_device.h"
#include "scpi_parser_wrapper.h"

#define BUFFER_SIZE 128 //512   //8
#define SCPI_CMD_BUF_SIZE   40

/* 3.2 Bulk-OUT endpoint */
#define DEV_DEP_MSG_OUT             0x01
#define REQUEST_DEV_DEP_MSG_IN      0x02
#define VENDOR_SPECIFIC_OUT         0x7E    /* MsgId = 126 */
#define REQUEST_VENDOR_SPECIFIC_IN  0x7F    /* MsgId = 127 */
#define TRIGGER                     0x80    /* MsgId = 128 */

/* 3.3 Bulk-IN endpoint */
#define DEV_DEP_MSG_IN              0x02    /* MsgId = 002 */
#define VENDOR_SPECIFIC_IN          0x7F    /* MsgId = 127 */

/* USB Endpoint Defines */
#define XUD_EP_COUNT_OUT   2    //Includes EP0 (1 out EP0 + USBTMC data output EP)
#define XUD_EP_COUNT_IN    2    //Includes EP0 (1 in EP0)

XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL};

// inline XUD_Result_t XUD_SetReady_InPtr(XUD_ep ep, unsigned addr, int len)
// {
//     int chan_array_ptr;
//     int tmp, tmp2;
//     int wordLength;
//     int tailLength;

//     int reset;

//     /* Firstly check if we have missed a USB reset - endpoint may not want to send out old data after a reset */
//     asm ("ldw %0, %1[9]":"=r"(reset):"r"(ep));
//     if(reset)
//     {
//         return XUD_RES_RST;
//     }

//     /* Tail length bytes to bits */
//     tailLength = zext((len << 3),5);

//     /* Datalength (bytes) --> datalength (words) */
//     wordLength = len >> 2;

//     /* If tail-length is 0 and word-length not 0. Make tail-length 32 and word-length-- */
//     if ((tailLength == 0) && (wordLength != 0))
//     {
//         wordLength = wordLength - 1;
//         tailLength = 32;
//     }
    
//      Get end off buffer address 
//     asm ("add %0, %1, %2":"=r"(tmp):"r"(addr),"r"(wordLength << 2));

//     /* Produce negative offset from end of buffer */
//     asm ("neg %0, %1":"=r"(tmp2):"r"(wordLength));

//     /* Store neg index */
//     asm ("stw %0, %1[6]"::"r"(tmp2),"r"(ep));

//     /* Store buffer pointer */
//     asm ("stw %0, %1[3]"::"r"(tmp),"r"(ep));

//     /*  Store tail len */
//     asm ("stw %0, %1[7]"::"r"(tailLength),"r"(ep));

//     /* Finally, mark ready */
//     asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));
//     asm ("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));

//     return XUD_RES_OKAY;
// }

// inline XUD_Result_t XUD_SetReady_In(XUD_ep ep, unsigned char buffer[], int len)
// {
//     unsigned addr;

//     asm("mov %0, %1":"=r"(addr):"r"(buffer));

//     return XUD_SetReady_InPtr(ep, addr, len);
// }

DECLARE_JOB(_usbtmc_bulk_endpoints, (chanend_t, chanend_t));
void _usbtmc_bulk_endpoints(chanend_t c_ep_out, chanend_t c_ep_in)
{
    unsigned char host_transfer_buf[BUFFER_SIZE];
    unsigned host_transfer_length = BUFFER_SIZE;//0;
    unsigned char scpi_cmd[SCPI_CMD_BUF_SIZE];
    XUD_Result_t result;
    int scpi_parse_res = 0;
    unsigned scpi_cmd_len = 0;
    unsigned char msg_id;   //MsgID field with Offset 0

    /* Initialise the XUD endpoints */
    XUD_ep ep_out = XUD_InitEp(c_ep_out);
    XUD_ep ep_in  = XUD_InitEp(c_ep_in);

    /* Mark OUT endpoint as ready to receive */
    XUD_SetReady_Out (ep_out, host_transfer_buf);

    SCPI_initialize_parser();
    
    SELECT_RES(
        CASE_THEN(c_ep_out, xud_getdata_select_handler),
        CASE_THEN(c_ep_in, xud_setdata_select_handler))
    {
        xud_getdata_select_handler:
            XUD_GetData_Select(c_ep_out, ep_out, &host_transfer_length, &result);
            if (result == XUD_RES_RST) {
                XUD_ResetEndpoint(ep_in, NULL);
            }
            msg_id = host_transfer_buf[0];

            switch (msg_id) {
                case DEV_DEP_MSG_OUT:
                {
                    scpi_cmd_len = host_transfer_buf[4];    //TODO: Handle 4-byte TransferSize for scpi_cmd_len
                    SCPI_get_cmd(&host_transfer_buf[12], &scpi_cmd_len, &scpi_cmd);
                }
                break;

                case REQUEST_DEV_DEP_MSG_IN:
                {
                    /* Prepare response message buffer */
                    scpi_parse_res = SCPI_parse_cmd(&scpi_cmd, scpi_cmd_len, &host_transfer_buf[12], &host_transfer_length);
                    host_transfer_buf[4] = host_transfer_length;
                    host_transfer_buf[5] = 0x00;
                    host_transfer_buf[6] = 0x00;
                    host_transfer_buf[8] = 0x01;    //Set (EOM=1)
                    host_transfer_length += 12;     //Bulk-IN header size
                    host_transfer_buf[host_transfer_length++] = 0x00; //Set Alighnment byte

                    XUD_SetReady_In (ep_in, host_transfer_buf, host_transfer_length);
                    // printf("ep in set ready\n");
                }
                break;

                case VENDOR_SPECIFIC_OUT:
                    /* Handle any vendor specific command messages */
                break;

                case REQUEST_VENDOR_SPECIFIC_IN:
                    /* Handle any vendor specific command messages */
                break;
    
                default:
                break;
            }
    
                /* Mark EP as ready again */
            XUD_SetReady_Out (ep_out, host_transfer_buf);
            // printf("ep out set ready\n");
            continue;

        xud_setdata_select_handler:
            XUD_SetData_Select(c_ep_in, ep_in, &result);
            if (result == XUD_RES_RST) {
                XUD_ResetEndpoint(ep_in, NULL);
            }

            /* Mark EP OUT as ready again */
            XUD_SetReady_Out (ep_out, host_transfer_buf);
            continue;
    }
    
}


/* Prototype for Endpoint0 function in endpoint0.xc */
void Endpoint0(chanend c_ep0_out, chanend c_ep0_in);
DECLARE_JOB(_Endpoint0, (chanend_t, chanend_t));
void _Endpoint0(chanend_t c_ep0_out, chanend_t c_ep0_in){
    hwtimer_realloc_xc_timer();
    Endpoint0(c_ep0_out, c_ep0_in);
    hwtimer_free_xc_timer();
}

// void usbtmc_bulk_endpoints(chanend c_ep_out,chanend c_ep_in);
// DECLARE_JOB(_usbtmc_bulk_endpoints, (chanend_t, chanend_t));
// void _usbtmc_bulk_endpoints(chanend_t c_ep_out, chanend_t c_ep_in){
//     usbtmc_bulk_endpoints(c_ep_out, c_ep_in);
// }

/* Global report buffer, global since used by Endpoint0 core */
unsigned char g_reportBuffer[] = {0, 0, 0, 0};

DECLARE_JOB(_XUD_Main, (chanend_t*, int, chanend_t*, int, chanend_t, XUD_EpType*, XUD_EpType*, XUD_BusSpeed_t, XUD_PwrConfig));
void _XUD_Main(chanend_t *c_epOut, int noEpOut, chanend_t *c_epIn, int noEpIn, chanend_t c_sof, XUD_EpType *epTypeTableOut, XUD_EpType *epTypeTableIn, XUD_BusSpeed_t desiredSpeed, XUD_PwrConfig pwrConfig)
{
    for(int i = 0; i < XUD_EP_COUNT_OUT; ++i) {
        printf("out[%d]: %x\n", i, c_epOut[i]);
    }
    for(int i = 0; i < XUD_EP_COUNT_IN; ++i) {
        printf("in[%d]: %x\n", i, c_epIn[i]);
    }
    XUD_Main(c_epOut, noEpOut, c_epIn, noEpIn, c_sof,
        epTypeTableOut, epTypeTableIn, desiredSpeed, pwrConfig);
}

/* The main function runs three cores: the XUD manager, Endpoint 0, and a USBTMC endpoints. An array of
   channels is used for both IN and OUT endpoints */
int main()
{
    // chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    channel_t channel_ep_out[XUD_EP_COUNT_OUT];
    channel_t channel_ep_in[XUD_EP_COUNT_IN];

    for(int i = 0; i < sizeof(channel_ep_out) / sizeof(*channel_ep_out); ++i) {
        channel_ep_out[i] = chan_alloc();
    }
    for(int i = 0; i < sizeof(channel_ep_in) / sizeof(*channel_ep_in); ++i) {
        channel_ep_in[i] = chan_alloc();
    }

    chanend_t c_ep_out[XUD_EP_COUNT_OUT];
    chanend_t c_ep_in[XUD_EP_COUNT_IN];

    for(int i = 0; i < XUD_EP_COUNT_OUT; ++i) {
        c_ep_out[i] = channel_ep_out[i].end_a;
    }
    for(int i = 0; i < XUD_EP_COUNT_IN; ++i) {
        c_ep_in[i] = channel_ep_in[i].end_a;
    }

    // par
    // {
    //     on USB_TILE: XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
    //                   null, epTypeTableOut, epTypeTableIn, 
    //                   XUD_SPEED_HS, XUD_PWR_BUS);

    //     on USB_TILE: Endpoint0(c_ep_out[0], c_ep_in[0]);

    //     on USB_TILE: usbtmc_bulk_endpoints(c_ep_out[1],c_ep_in[1]);

    // }

    PAR_JOBS(
        PJOB(_XUD_Main, (c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN, 0, epTypeTableOut, epTypeTableIn, XUD_SPEED_HS, XUD_PWR_BUS)),
        PJOB(_Endpoint0, (channel_ep_out[0].end_b, channel_ep_in[0].end_b)),
        PJOB(_usbtmc_bulk_endpoints, (channel_ep_out[1].end_b, channel_ep_in[1].end_b))
    );
    return 0;
}
