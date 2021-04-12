// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/**
 * @brief  Wrapper calls for SCPI interfacing from a XC client core
 *
 */
#include <string.h>
#include "scpi/scpi.h"
#include "scpi_cmds.h"
#include "print.h"

extern scpi_t scpi_context;
extern scpi_results_t scpi_result_data;

char err_msg[] = "SCPI command not implemented";

void SCPI_initialize_parser(void)
{
    SCPI_Init(&scpi_context);
}

int SCPI_get_cmd(unsigned char *cmd, unsigned *scpi_cmd_len, unsigned char *scpi_cmd)
{
    int len = *scpi_cmd_len;
    for (int i=0; i<len; i++)
        *scpi_cmd++ = *cmd++;
    *scpi_cmd++ = '\r';
    *scpi_cmd++ = '\n';
    *scpi_cmd_len += 2;
    return len;
}

int SCPI_parse_cmd(unsigned char *cmd, unsigned cmd_len, unsigned char *buf, unsigned *len)
{
    int result = -1;
    result = SCPI_Input(&scpi_context, (const char *) cmd, (size_t) cmd_len);
    if (1 == result) {
        scpi_result_data.scpi_result_buffer[scpi_result_data.buf_len] = '\0'; //TODO: to be removed
        *len = scpi_result_data.buf_len + 1;
        strncpy((const char *) buf, scpi_result_data.scpi_result_buffer, *len);
    }
    else {
        *len = strlen(err_msg)+1;
        strncpy((const char *) buf, err_msg, *len);
    }
    scpi_result_data.buf_len = 0;
    return result;
}
