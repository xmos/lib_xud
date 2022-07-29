// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef SCPI_PARSER_WRAPPER_H_
#define SCPI_PARSER_WRAPPER_H_

#include <xccompat.h>

void SCPI_initialize_parser(void);
#ifndef __XC__
int SCPI_get_cmd(unsigned char *cmd, unsigned *scpi_cmd_len, unsigned char *scpi_cmd);
int SCPI_parse_cmd(unsigned char *cmd, unsigned cmd_len, unsigned char *buf, unsigned *len);
#else
int SCPI_get_cmd(NULLABLE_ARRAY_OF(unsigned char, cmd), REFERENCE_PARAM(unsigned, scpi_cmd_len), NULLABLE_ARRAY_OF(unsigned char, scpi_cmd));
int SCPI_parse_cmd(NULLABLE_ARRAY_OF(unsigned char, cmd), unsigned cmd_len, NULLABLE_ARRAY_OF(unsigned char, result_buffer), REFERENCE_PARAM(unsigned, len));
#endif


#endif /* SCPI_PARSER_WRAPPER_H_ */
