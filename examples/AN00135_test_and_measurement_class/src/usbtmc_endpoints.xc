// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

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

/* This function receives the USBTMC endpoint transfers from the host */
void usbtmc_bulk_endpoints(chanend c_ep_out,chanend c_ep_in)
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

    while(1)
    {
        select
        {
            case XUD_GetData_Select(c_ep_out, ep_out, host_transfer_length, result):
                /* Packet from host recieved */
                if (result == XUD_RES_RST) {
                    XUD_ResetEndpoint(ep_in, null);
                }
                msg_id = host_transfer_buf[0];

                switch (msg_id) {
                    case DEV_DEP_MSG_OUT:
                    {
                        scpi_cmd_len = host_transfer_buf[4];    //TODO: Handle 4-byte TransferSize for scpi_cmd_len
                        SCPI_get_cmd(&host_transfer_buf[12], scpi_cmd_len, scpi_cmd);
                    }
                    break;

                    case REQUEST_DEV_DEP_MSG_IN:
                    {
                        /* Prepare response message buffer */
                        scpi_parse_res = SCPI_parse_cmd(scpi_cmd, scpi_cmd_len, &host_transfer_buf[12], host_transfer_length);
                        host_transfer_buf[4] = host_transfer_length;
                        host_transfer_buf[5] = 0x00;
                        host_transfer_buf[6] = 0x00;
                        host_transfer_buf[8] = 0x01;    //Set (EOM=1)
                        host_transfer_length += 12;     //Bulk-IN header size
                        host_transfer_buf[host_transfer_length++] = 0x00; //Set Alighnment byte

                        XUD_SetReady_In (ep_in, host_transfer_buf, host_transfer_length);
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
            break ;

            case XUD_SetData_Select(c_ep_in, ep_in, result):
                /* Packet successfully sent to host */
                if (result == XUD_RES_RST) {
                    XUD_ResetEndpoint(ep_in, null);
                }

                /* Mark EP OUT as ready again */
                XUD_SetReady_Out (ep_out, host_transfer_buf);
            break ;
        }
    }
}
