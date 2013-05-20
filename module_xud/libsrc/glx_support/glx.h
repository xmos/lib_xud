#ifndef _glx_h_
#define _glx_h_

int write_glx_periph_word(unsigned destId, unsigned periphAddress, unsigned destRegAddr, unsigned data);
int read_glx_periph_word(unsigned dest_id, unsigned periph_addr, unsigned dest_reg_addr, unsigned &rd_data);
int read_glx_periph_reg(unsigned dest_id, unsigned periph_addr, unsigned dest_reg_addr, unsigned bad_format, unsigned data_size, char buf[]);
int write_glx_periph_reg(unsigned dest_id, unsigned periph_addr, unsigned dest_reg_addr, unsigned bad_packet, unsigned data_size, char buf[]);
void read_sswitch_reg_verify(unsigned coreid, unsigned reg, unsigned &data, unsigned failval);
void write_sswitch_reg_verify(unsigned coreid, unsigned reg, unsigned data, unsigned failval);

#endif // _glx_h_
