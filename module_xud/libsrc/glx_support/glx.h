

#define MYID   0x0000
#define GLXID  0x0001
#define PLL_CTRL_VAL ((1<<23) | (499<<8) | (2<<0))
void glx_link_setup(unsigned myid, unsigned glxid);
void glx_link_setup_with(unsigned myid, unsigned glxid, unsigned link_setup_val);
int write_glx_periph_word(unsigned destId, unsigned periphAddress, unsigned destRegAddr, unsigned data);
void read_sswitch_reg_verify(unsigned coreid, unsigned reg, unsigned &data, unsigned failval);
void write_sswitch_reg_verify(unsigned coreid, unsigned reg, unsigned data, unsigned failval);
