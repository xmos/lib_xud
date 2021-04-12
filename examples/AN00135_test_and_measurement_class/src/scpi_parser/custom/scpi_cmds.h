// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef SCPI_DEF_H_
#define SCPI_DEF_H_

#ifdef  __cplusplus
extern "C" {
#endif

#define SCPI_RESULT_BUFFER_LENGTH 256

struct _scpi_results_t {
    char scpi_result_buffer[SCPI_RESULT_BUFFER_LENGTH];
    unsigned int buf_len;
};

typedef struct _scpi_results_t scpi_results_t;

/* Declare SCPI command callbacks */
scpi_result_t DMM_MeasureVoltageDcQ(scpi_t * context);

/* declare interface callbacks */
size_t scpi_app_write(scpi_t * context, const char * data, size_t len);


#ifdef  __cplusplus
}
#endif

#endif /* SCPI_DEF_H_ */
