// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/**
 * @brief  Implementation of SCPI command callbacks
 *
 */

#include <string.h>
#include "scpi/scpi.h"
#include "scpi_cmds.h"
#include "print.h"

scpi_results_t scpi_result_data;

#define DUMMY_MEAS_RESULT_VAL   10

scpi_result_t DMM_MeasureVoltageDcQ(scpi_t * context) {
    scpi_number_t param1, param2;
    char bf[15];
    // read first parameter if present
    if (!SCPI_ParamNumber(context, &param1, false)) {
        // do something, if parameter not present
    }

    // read second paraeter if present
    if (!SCPI_ParamNumber(context, &param2, false)) {
        // do something, if parameter not present
    }

    SCPI_NumberToStr(context, &param1, bf, 15);
    SCPI_NumberToStr(context, &param2, bf, 15);
    SCPI_ResultInt(context, DUMMY_MEAS_RESULT_VAL);
    return SCPI_RES_OK;
}

size_t scpi_app_write(scpi_t * context, const char * data, size_t len) {
    (void) context;
    strncpy((const char*)&scpi_result_data.scpi_result_buffer[scpi_result_data.buf_len], data, len);
    scpi_result_data.buf_len += len;
    return 0;
}

