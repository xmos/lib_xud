// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <platform.h>
#include <xclib.h>
#include <string.h>
#include <xassert.h>
#include "xud_device.h"
#include "mass_storage.h"
#include "debug_print.h"
//Flash_Functions_start
#include "flashlib.h"

on tile[0]: fl_SPIPorts spiPort = {
    XS1_PORT_1A,
        XS1_PORT_1B,
        XS1_PORT_1C,
        XS1_PORT_1D,
        XS1_CLKBLK_1
};

fl_DeviceSpec flashSpec[1] = {FL_DEVICE_NUMONYX_M25P16}; // Equivalent of Micron M25P16

int pagesPerBlock_g = 0;
int bytesPerPage_g = 0;
unsigned char pageBuffer_g[MASS_STORAGE_BLOCKLENGTH];

void massStorageInit() {
    fl_connectToDevice(spiPort, flashSpec, 1);
        fl_setBootPartitionSize(FLASH_PARTITION_SIZE);
        bytesPerPage_g = fl_getPageSize();
        pagesPerBlock_g = (MASS_STORAGE_BLOCKLENGTH / bytesPerPage_g);
}

int massStorageWrite(unsigned int blockNr, unsigned char buffer[]) {
    for(int i = 0; i < pagesPerBlock_g; i++) {
        for(int j = 0; j < bytesPerPage_g; j++) {
            pageBuffer_g[j] = buffer[i * bytesPerPage_g + j];
        }
        fl_writeDataPage(blockNr * pagesPerBlock_g + i, buffer);
    }
    return 0;
}

int massStorageRead(unsigned int blockNr, unsigned char buffer[]) {
    for(int i = 0; i < pagesPerBlock_g; i++) {
        fl_readDataPage(blockNr * pagesPerBlock_g + i, pageBuffer_g);
            for(int j = 0; j < bytesPerPage_g; j++) {
                buffer[i * bytesPerPage_g + j] = pageBuffer_g[j];
            }
    }
    return 0;
}

int massStorageSize() {
#if DETECT_AS_FLOPPY
    return FLOPPY_DISK_SIZE;
#else
        int x = fl_getNumDataPages();
        return x / pagesPerBlock_g;
#endif
}
//Flash_Functions_end
static unsigned char inquiryAnswer[36] = {
    0x00,               // Peripheral Device Type (PDT) - SBC Direct-access device
        0x80,               // Removable Medium Bit is Set
        0x02,               // Version
        0x02,               // Obsolete[7:6],NORMACA[5],HISUP[4],Response Data Format[3:0]
        0x1f,               // Additional Length
        0x73,               // SCCS[7],ACC[6],TPGS[5:4],3PC[3],Reserved[2:1],PROTECT[0]
        0x6d,               // BQUE[7],ENCSERV[6],VS[5],MULTIP[4],MCHNGR[3],Obsolete[2:1],ADDR16[0]
        0x69,               // Obsolete[7:6],WBUS116[5],SYNC[4],LINKED[3],Obsolete[2],CMDQUE[1],VS[0]
        'X', 'M', 'O', 'S', 'L', 'T', 'D', 0, // Vendor Identification
        'F', 'l', 'a', 's', 'h', ' ', 'D', 'i', 's', 'k', 0, ' ', ' ', ' ', ' ', ' ', // Product Identification
        '0', '.', '1', '0'  // Product Revision Level
};

static unsigned char modeSenseAnswer[4] = {
    0x04, 0x00, 0x10, 0x00
};

//Reference: http://www.usb.org/developers/docs/devclass_docs/usb_msc_boot_1.0.pdf
static unsigned char requestSenseAnswer[18] = {
    0x70,   // Error Code
        0x00,   // Segment Number (Reserved)
        0x02,   // ILI, Sense Key
        0x00, 0x00, 0x00, 0x00, // Information
        0x0A,   // Additional Sense Length (n-7), i.e. 17-7
        0x00, 0x00, 0x00, 0x00, // Command Specific Information
        0x3A,   // Additional Sense Code
        0x00,   // Additional Sense Qualifier (optional)
        0x00, 0x00, 0x00, 0x00  // Reserved
};

static unsigned char blockBuffer[MASS_STORAGE_BLOCKLENGTH];

/* This function receives the mass storage endpoint transfers from the host */
void massStorageClass(chanend chan_ep1_out,chanend chan_ep1_in, int writeProtect)
{
    unsigned char commandBlock[CBW_SHORT_PACKET_SIZE];
        unsigned char commandStatus[CSW_SHORT_PACKET_SIZE];
        unsigned host_transfer_length = 0;
        int readCapacity[8];
        int readLength, readAddress;
        int dCBWSignature = 0, bCBWDataTransferLength = 0;
        int bmCBWFlags = 0, bCBWLUN = 0, bCBWCBLength = 0;
        int Operation_Code = 0;
        XUD_Result_t result;
        int ready = 1;

        debug_printf("USB Mass Storage class demo started\n");

        /* Load some default CSW to reduce response time delay */
        memset(commandStatus,0,CSW_SHORT_PACKET_SIZE);
        /* Signature helps identify this data packet as a CSW */
        (commandStatus, int[])[0] = byterev(CSW_SIGNATURE);

        /* Initialise the XUD endpoints */
        XUD_ep ep1_out = XUD_InitEp(chan_ep1_out);
    XUD_ep ep1_in  = XUD_InitEp(chan_ep1_in);

#if !DETECT_AS_FLOPPY
    massStorageInit();
#endif

    while(1)
    {
        unsigned char bCSWStatus = CSW_STATUS_CMD_PASSED;
        // Get Command Block Wrapper (CBW)
        if(XUD_RES_OKAY == (result = XUD_GetBuffer(ep1_out, (commandBlock, char[CBW_SHORT_PACKET_SIZE]), host_transfer_length)) )
        {
            /* The CBW shall start on a packet boundary and shall end as a short packet
             * with exactly 31 (0x1F) bytes transferred
             */
            assert(host_transfer_length == CBW_SHORT_PACKET_SIZE);
                /* verify Signature - that helps identify this packet as a CBW */
                dCBWSignature = commandBlock[0] | commandBlock[1] << 8 |
                commandBlock[2] << 16 | commandBlock[3] << 24;
                assert(dCBWSignature == CBW_SIGNATURE);

                bCBWDataTransferLength = commandBlock[8] | commandBlock[9]<<8 |
                commandBlock[10] << 16 | commandBlock[11] << 24;

                bmCBWFlags = commandBlock[12]; bCBWLUN = (commandBlock[13] & 0x0F);
                assert(bCBWCBLength = (commandBlock[14] & 0x1F) <= 16);
                Operation_Code = commandBlock[15];

                switch(Operation_Code)
                {
                    case TEST_UNIT_READY_CMD: // Test unit ready:
                        bCSWStatus = ready ? CSW_STATUS_CMD_PASSED : CSW_STATUS_CMD_FAILED;
                            break;

                    case REQUEST_SENSE_CMD: // Request sense
                            requestSenseAnswer[2] = ready ? STATUS_GOOD : STATUS_CHECK_CONDITION;
                                result = XUD_SetBuffer(ep1_in, requestSenseAnswer, sizeof(requestSenseAnswer));
                                break;

                    case INQUIRY_CMD: // Inquiry
                                result = XUD_SetBuffer(ep1_in, inquiryAnswer, sizeof(inquiryAnswer));
                                    break;

                    case START_STOP_CMD: // start/stop
                                    ready = ((commandBlock[19] >> 1) & 1) == 0;
                                        break;

                    case MODE_SENSE_6_CMD:  // Mode sense (6)
                    case MODE_SENSE_10_CMD: // Mode sense (10) // For Mac OSX
                                        if (writeProtect) modeSenseAnswer[2] |= 0x80;

                                                result = XUD_SetBuffer(ep1_in, modeSenseAnswer, sizeof(modeSenseAnswer));
                                                break;


                    case MEDIUM_REMOVAL_CMD: // Medium removal
                                                break;

                    case RECEIVE_DIAGNOSTIC_RESULT_CMD:
                                                       memset(readCapacity,0x0000,sizeof(readCapacity));
                                                           result = XUD_SetBuffer(ep1_in, (readCapacity, unsigned char[8]), 32);
                                                           break;

                    case READ_FORMAT_CAPACITY_CMD: // Read Format capacity (UFI Command Spec)
                                                           readCapacity[0] = byterev(8);
                                                               readCapacity[1] = byterev(massStorageSize());
                                                               readCapacity[2] = byterev(MASS_STORAGE_BLOCKLENGTH) | (DETECT_AS_FLOPPY ? NO_CARTRIDGE_IN_DRIVE : FORMATTED_MEDIA);
                                                               result = XUD_SetBuffer(ep1_in, (readCapacity, unsigned char[8]), 12);
                                                               break;

                    case READ_CAPACITY_CMD: // Read capacity
                                                               readCapacity[0] = byterev(massStorageSize()-1);
                                                                   readCapacity[1] = byterev(MASS_STORAGE_BLOCKLENGTH);
                                                                   result = XUD_SetBuffer(ep1_in, (readCapacity, unsigned char[8]), 8);
                                                                   break;

                    case READ_CAPACITY_16_CMD:
                                              memset(readCapacity,0x0000,sizeof(readCapacity));
                                                  readCapacity[1] = byterev(massStorageSize()-1);
                                                  readCapacity[2] = byterev(MASS_STORAGE_BLOCKLENGTH);
                                                  result = XUD_SetBuffer(ep1_in, (readCapacity, unsigned char[8]), 32);
                                                  break;

                    case READ_10_CMD: // Read (10)
                                                  readLength = commandBlock[22] << 8 | commandBlock[23];
                                                      readAddress = commandBlock[17] << 24 | commandBlock[18] << 16 |
                                                      commandBlock[19] << 8 | commandBlock[20];
                                                      for(int i = 0; i < readLength ; i++) {
                                                          bCSWStatus |= massStorageRead(readAddress, blockBuffer);
                                                              result = XUD_SetBuffer(ep1_in, blockBuffer, MASS_STORAGE_BLOCKLENGTH);
                                                              readAddress++; }
                                                              break;

                    case WRITE_10_CMD: // Write
                                                              readLength = commandBlock[22] << 8 | commandBlock[23];
                                                                  readAddress = commandBlock[17] << 24 | commandBlock[18] << 16 |
                                                                  commandBlock[19] << 8 | commandBlock[20];
                                                                  for(int i = 0; i < readLength ; i++) {
                                                                      result = XUD_GetBuffer(ep1_out, (blockBuffer, char[128 * 4]),host_transfer_length);
                                                                          bCSWStatus |= massStorageWrite(readAddress, blockBuffer);
                                                                          readAddress++; }
                                                                          break;

                    default:
                            debug_printf("Invalid Operation Code Received : 0x%x\n",Operation_Code);
                                bCSWStatus = CSW_STATUS_CMD_FAILED;
                                break;
                }
        }

            /* Check for result, if it is found as XUD_RES_RST, then reset Endpoints */
            if(result == XUD_RES_RST) {
                XUD_ResetEndpoint(ep1_out,ep1_in);
                    break;
            }

            /* Setup Command Status Wrapper (CSW). The CSW shall start on a packet boundry
             * and shall end as a short packet with exactly 13 (0x0D) bytes transferred */
            /* The device shall echo the contents of dCBWTag back to the host in the dCSWTag */
            commandStatus[4] = commandBlock[4];
            commandStatus[5] = commandBlock[5];
            commandStatus[6] = commandBlock[6];
            commandStatus[7] = commandBlock[7];
            commandStatus[12] = bCSWStatus;

            if(XUD_RES_RST == XUD_SetBuffer(ep1_in, commandStatus, CSW_SHORT_PACKET_SIZE))
                XUD_ResetEndpoint(ep1_out,ep1_in);

    } //while(1)
} // END of massStorageClass
