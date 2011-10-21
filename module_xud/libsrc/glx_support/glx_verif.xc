// Tom Hunt : 19/10/10
#include <xs1.h>
#include <xa1_registers.h>
#include <platform.h>

extern void     TerminateFail(signed int);
extern void     TerminatePass(signed int);
extern int write_glx_periph_reg(unsigned dest_id, unsigned periph_addr, unsigned dest_reg_addr, unsigned bad_packet, unsigned data_size, char buf[]);
extern int read_glx_periph_reg(unsigned dest_id, unsigned periph_addr, unsigned dest_reg_addr, unsigned bad_format, unsigned data_size, char buf[]);
extern int read_glx_periph_word(unsigned dest_id, unsigned periph_addr, unsigned dest_reg_addr, unsigned &re_word);

//Functions to verify that the read and writes succeed
void read_sswitch_reg_verify(unsigned coreid, unsigned reg, unsigned &data, unsigned failval) {
   if (!read_sswitch_reg(coreid, reg, data)) {
      TerminateFail(failval);
   }
}
void read_sswitch_reg_nack_verify(unsigned coreid, unsigned reg, unsigned &data, unsigned failval) {
   if (read_sswitch_reg(coreid, reg, data)) {
      TerminateFail(failval);
   }
}

void write_sswitch_reg_verify(unsigned coreid, unsigned reg, unsigned data, unsigned failval) {
   if (!write_sswitch_reg(coreid, reg, data)) {
      TerminateFail(failval);
   }
}

void write_sswitch_reg_nack_verify(unsigned coreid, unsigned reg, unsigned data, unsigned failval) {
   if (write_sswitch_reg(coreid, reg, data)) {
      TerminateFail(failval);
   }
}

void set_verif_step(unsigned coreid, char step) {
   //Sets deep sleep to step
   char write[1];
   write[0] = step;
   write_glx_periph_reg(coreid, XS1_GLX_PERIPH_SCTH_ID, 0xff, 0, 1, write);
}

void check_verif_step(unsigned coreid, char step) {
   //Checks if deep sleep is equal to step
   char rdata[1];
   unsigned ret;
   read_glx_periph_reg(coreid, XS1_GLX_PERIPH_SCTH_ID, 0xff, 0, 1, rdata);
   if (rdata[0] != step) {
      ret = step | 0xf0;
      TerminateFail(ret);
   }
}

void get_verif_step(unsigned coreid, char &step) {
   //Returns deep sleep value
   char rdata[1];
   read_glx_periph_reg(coreid, XS1_GLX_PERIPH_SCTH_ID, 0xff, 0, 1, rdata);
   step = rdata[0];
}

void verif_cfg_reg_val (unsigned glxid, unsigned reg, unsigned mask, unsigned exp_val, unsigned failval) {

   unsigned rdata;

   read_sswitch_reg_verify(glxid, reg, rdata, (0xd000 | failval)); 
   rdata = rdata & mask;
   if(rdata != exp_val) { TerminateFail(0xe000 | failval); }

}

void verif_periph_reg_val (unsigned glxid, unsigned periph_addr, unsigned reg, unsigned mask, unsigned exp_val, unsigned failval) {

   unsigned rdata;

   read_glx_periph_word(glxid, periph_addr, reg, rdata); 
   rdata = rdata & mask;
   if(rdata != exp_val) { TerminateFail(0xe000 | failval); }

}
