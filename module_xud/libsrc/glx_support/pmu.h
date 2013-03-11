// routines for bit banging the pmu test interface via the xlink

#ifndef _PMU_H
#define _PMU_H

#include <xs1.h>
#include <xa1_registers.h>
#include <platform.h>
#include <print.h>

#define DIN_MASK 0xffffffef 
#define CLK_MASK 0xfffffff7
#define DOUT_MASK 0x00000100

extern int write_sswitch_reg_noresp(unsigned coreid, unsigned reg, unsigned data);

// Function to bit bash writing to the pmu test registers through 
// the XS1_GLX_CFG_PMU_TEST_MODE_ADRS
unsigned write_data_bit (unsigned glxid, unsigned curr_val, unsigned bit)
{
  unsigned wdata;
  unsigned new_curr_val;
  // set the data bit to be 0 and or it with the current value to only get 
  // the data bit in the register set
  wdata = (curr_val & DIN_MASK) | bit;    
  write_sswitch_reg(glxid,XS1_GLX_CFG_PMU_TEST_MODE_ADRS,wdata);

  //printstr("4c\n");

  new_curr_val = wdata;
  // write a 1 to the clock
  wdata = new_curr_val | ~(CLK_MASK);
  write_sswitch_reg(glxid,XS1_GLX_CFG_PMU_TEST_MODE_ADRS,wdata);

  //printstr("4d\n");
  new_curr_val = wdata;
  // write a 0 to the clock
  wdata = new_curr_val & CLK_MASK;
  write_sswitch_reg(glxid,XS1_GLX_CFG_PMU_TEST_MODE_ADRS,wdata);

  //printstr("4e\n");
  new_curr_val = wdata;
  
  return new_curr_val;
  
}

void write_pmu_register ( unsigned glxid, unsigned pmu_add, unsigned pmu_data)
{
  
  int bc;
  unsigned bit;
  unsigned curr_val;
  
  read_sswitch_reg(glxid, XS1_GLX_CFG_PMU_TEST_MODE_ADRS, curr_val);

  //printstr("4a\n");

  // [0]   PMU_TEST_EN - set to 1 to be driven from this register
  // [1]   CC_TEST_EN
  // [2]   CC_TEST_RSTB
  // [3]   CC_TEST_CLK
  // [4]   CC_TEST_DATAIN
  // [5]   CC_TEST_GPIN
  // [7:6] Reserved
  // [8]   CC_TEST_DATAOUT
  // [9]   CC_TEST_STAT_1
  // [10]  CC_TEST_STAT_2
  // [19:11] Reserved
  // [31:20] ADC_DOUT[11:0]

  // For each bit need to write the data to CC_TEST_DATAIN and then write a 1 to the clock, then a 0 to the clock
  // bits 0-11 are the addresss
  for (bc=11;bc>=0;bc--) {
    // make the bottom bit of bit the data to be written
    bit = (pmu_add >> bc) & 0x00000001;
    // shift it to be the 4th bit (din)
    bit = bit << 4;
    curr_val = write_data_bit(glxid, curr_val,bit);
  }

  

  //printstr("4b\n");

  // bit 12 is always 1 for a write 
  curr_val = write_data_bit(glxid, curr_val,(0x1<<4));
  // bits 13-15 are always 0
  for (bc=0;bc<3;bc++) {
    curr_val = write_data_bit(glxid, curr_val,(0x0<<4));
  }
  // bits 16 - 23 are write data
  for (bc=7;bc>=0;bc--) {
    bit = (pmu_data >> bc) & 0x00000001;
    // shift it to be the 4th bit (din)
    bit = bit << 4;
    curr_val = write_data_bit(glxid, curr_val,bit);    
  }  
  // bits 24 - 31 are padded with 0
  for (bc=0;bc<8;bc++) {
    curr_val = write_data_bit(glxid, curr_val,(0x0<<4));
  }
  
}

unsigned read_pmu_register ( unsigned glxid, unsigned pmu_add)
{
  
  int bc;
  unsigned bit;
  unsigned tmp_rdata; 
  unsigned curr_val;
  unsigned pmu_rdata;
  
  pmu_rdata = 0;
  read_sswitch_reg(glxid, XS1_GLX_CFG_PMU_TEST_MODE_ADRS, curr_val);

  // [0]   PMU_TEST_EN - set to 1 to be driven from this register
  // [1]   CC_TEST_EN
  // [2]   CC_TEST_RSTB
  // [3]   CC_TEST_CLK
  // [4]   CC_TEST_DATAIN
  // [5]   CC_TEST_GPIN
  // [7:6] Reserved
  // [8]   CC_TEST_DATAOUT
  // [9]   CC_TEST_STAT_1
  // [10]  CC_TEST_STAT_2
  // [19:11] Reserved
  // [31:20] ADC_DOUT[11:0]

  // For each bit need to write the data to CC_TEST_DATAIN and then write a 1 to the clock, then a 0 to the clock
  // bits 0-11 are the addresss
  for (bc=11;bc>=0;bc--) {
    // make the bottom bit of bit the data to be written
    bit = (pmu_add >> bc) & 0x00000001;
    // shift it to be the 4th bit (din)
    bit = bit << 4;
    curr_val = write_data_bit(glxid, curr_val,bit);
  }
  // bit 12 is always 1 for a write 
  curr_val = write_data_bit(glxid, curr_val,(0x0<<4));
  // bits 13-15 are always 0
  for (bc=0;bc<3;bc++) {
    curr_val = write_data_bit(glxid, curr_val,(0x0<<4));
  }
  // bits 16 - 23 are read data, need to write 0's and then create the 8 bit read data by reading the 
  // register and masking the dataout bit
  for (bc=7;bc>=0;bc--) {
    bit = (0x00 >> bc) & 0x00000001;
    // shift it to be the 4th bit (din)
    bit = bit << 4;
    curr_val = write_data_bit(glxid, curr_val,bit);
    read_sswitch_reg(glxid, XS1_GLX_CFG_PMU_TEST_MODE_ADRS, tmp_rdata);
    tmp_rdata = (tmp_rdata & DOUT_MASK) >> 8;
    pmu_rdata = pmu_rdata | (tmp_rdata << bc);
    
    
  }  
  // bits 24 - 31 are padded with 0
  for (bc=0;bc<8;bc++) {
    curr_val = write_data_bit(glxid, curr_val,(0x0<<4));
  }

  return pmu_rdata;

}

void enable_reads_to_gti_pmu_register (unsigned glxid)
{
  
  unsigned pmu_add = 0x21;
  unsigned pmu_data = 0x01;
  write_pmu_register ( glxid, pmu_add, pmu_data);

}

#endif
