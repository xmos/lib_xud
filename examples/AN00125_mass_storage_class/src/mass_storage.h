// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef MASS_STORAGE_H_
#define MASS_STORAGE_H_

#define CBW_SHORT_PACKET_SIZE    0x1F        //(31)
#define CBW_SIGNATURE            0x43425355
#define CSW_SIGNATURE            0x53425355
#define CBW_FLAGS_DATA_IN        0x80

#define CSW_SHORT_PACKET_SIZE    0x0D   // (13)

#define TEST_UNIT_READY_CMD            0x00
#define REQUEST_SENSE_CMD              0x03
#define INQUIRY_CMD                    0x12
#define MODE_SELECT_6_CMD              0x15
#define MODE_SENSE_6_CMD               0x1A
#define START_STOP_CMD                 0x1B
#define RECEIVE_DIAGNOSTIC_RESULT_CMD  0x1C
#define MEDIUM_REMOVAL_CMD             0x1E
#define READ_FORMAT_CAPACITY_CMD       0x23
#define READ_CAPACITY_CMD              0x25
#define READ_10_CMD                    0x28
#define WRITE_10_CMD                   0x2A
#define VERIFY_CMD                     0x2F
#define MODE_SENSE_10_CMD              0x5A
#define READ_CAPACITY_16_CMD           0x9E

#define CSW_STATUS_CMD_PASSED    0    //
#define CSW_STATUS_CMD_FAILED    1    //
#define CSW_STATUS_PHASE_ERR     2    //

#define STATUS_GOOD              0
#define STATUS_CHECK_CONDITION   2

#define MASS_STORAGE_BLOCKLENGTH   512
#define FLASH_PARTITION_SIZE       (65536 * 1) // Boot Partition size
#define FORMATTED_MEDIA            2
#define NO_CARTRIDGE_IN_DRIVE      3

#define DETECT_AS_FLOPPY           0 //Enable(1) this to detect the device as Floppy
#if DETECT_AS_FLOPPY
#define FLOPPY_DISK_SIZE           0xB40
#endif
/** Function that communicates with the host over the two endpoints that
 * mass storage requires, implementing the mass storage protocol.
 *
 * \param chan_ep1_out  channel end for the OUT endpoint - from XUD
 * \param chan_ep1_in   channel end for the IN endpoint - from XUD
 * \param writeProtect  Set to 1 to set the file system to be write protected.
 */
void massStorageClass(chanend chan_ep1_out, chanend chan_ep1_in, int writeProtect);

/** Call back function to initialise the other three call backs below.
 * Called once on startup. This function should be provided by the caller
 * of this module.
 */
void massStorageInit();

/** Call back function to read a block of data. This function should be
 * provided by the caller of this module. It is called every time a block
 * of data is read. This function should read MASS_STORAGE_BLOCKLENGTH bytes.
 *
 * \param blockNr    the block number to read from flash (or other backing store)
 * \param buffer     array to write the read data into.
 *
 */
int massStorageRead(unsigned int blockNr, unsigned char buffer[]);

/** Call back function to write a block of data. This function should be
 * provided by the caller of this module. It is called every time a block
 * of data is to be written. This function should write
 * MASS_STORAGE_BLOCKLENGTH bytes.
 *
 * \param blockNr    the block number to write to flash (or other backing store)
 * \param buffer     array to read the read data from.
 *
 */
int massStorageWrite(unsigned int blockNr, unsigned char buffer[]);

/** Call back function that computes the size of the flash. This function
 * should be provided by the caller of this module. This function should
 * return the number of blocks that can be stored.
 */
int massStorageSize();
#endif /* MASS_STORAGE_H_ */
