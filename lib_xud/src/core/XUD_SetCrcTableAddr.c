// Copyright (c) 2011-2018, XMOS Ltd, All rights reserved
/** @file      XUD_SetCrcTableAddr.c
  * @author    Ross Owen, XMOS Limited
  */


/* Global table used to store complete valid CRC5 table */
/* TODO Should be char */
extern unsigned char crc5Table[2048];

/* Glocal table used to store valid CRCs for current address, all other address is this table are invalidated */
extern unsigned char crc5Table_Addr[2048];

/** XUD_SetCrcTableAddress
 * @brief      Copies CRCs from original valid table to the table we use.  Invalidates entries
 *             which correspnds to the wrong address
 * @param      addr  new device address
 * @return     void
 */
void XUD_SetCrcTableAddr(unsigned addr)
{
    unsigned index;

    /* Set whole table to invalid CRC */
    memset(crc5Table_Addr, 0xff, 2048);

    /* Copy over relevant entries */
    for(unsigned ep = 0; ep <= 0xF; ep++)
    {
        index = addr + (ep << 7);
        crc5Table_Addr[index] = crc5Table[index];
    }
}
