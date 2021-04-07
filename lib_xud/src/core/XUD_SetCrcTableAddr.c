// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** @file      XUD_SetCrcTableAddr.c
  * @author    Ross Owen, XMOS Limited
  */

#ifdef ARCH_G

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
    int index, i, j;

    /* Addresses 0 - 0x7F */
    for (i = 0; i <= 0x7F; i++)
    {
        /* EPs 0 - 0xF */
        for(j = 0; j <= 0xF; j++)
        {
            index = i + (j<<7);
            if(i == addr)
            {
                crc5Table_Addr[index] = crc5Table[index];
            }
            else
            {
                /* Invalid CRC */
                crc5Table_Addr[index] = 0xff;
            }
        }
    }
}
#endif
