// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

unsigned char g_rxDataCheck[7] = {0, 0, 0, 0, 0, 0, 0};
unsigned char g_txDataCheck[5] = {0,0,0,0,0,};
unsigned g_txLength[5] = {0,0,0,0,0};

unsafe
{
    unsigned char volatile * unsafe g_rxDataCheck_ = g_rxDataCheck;
    unsigned char volatile * unsafe g_txDataCheck_ = g_txDataCheck;
}

void exit(int);

#ifndef PKT_COUNT
#define PKT_COUNT           10
#endif

#ifndef INITIAL_PKT_LENGTH
#define INITIAL_PKT_LENGTH  10
#endif


#pragma unsafe arrays
XUD_Result_t SendTxPacket(XUD_ep ep, int length, int epNum)
{
    unsigned char buffer[1024];

    for (int i = 0; i < length; i++)
    {
        buffer[i] = g_txDataCheck[epNum]++;
    }

    return XUD_SetBuffer(ep, buffer, length);
}

#pragma unsafe arrays
XUD_Result_t SendControlPacket(XUD_ep ep, int length, int epNum)
{
    unsigned char buffer[1024];

    for (int i = 0; i < length; i++)
    {
        buffer[i] = g_txDataCheck[epNum]++;
    }

    return XUD_SetControlBuffer(ep, buffer, length);
}



#pragma unsafe arrays
int TestEp_Bulk_Tx(chanend c_in1, int epNum1, int die)
{
    XUD_ep ep_in1  = XUD_InitEp(c_in1);
    
    unsigned char buffer[PKT_COUNT][1024];

    int counter = 0;
    int length = INITIAL_PKT_LENGTH;

    for(int i = 0; i< PKT_COUNT; i++)
    {
        for(int j = 0; j < length; j++)
        {
            buffer[i][j] = counter++;
        }
        length++;
    }

    length = INITIAL_PKT_LENGTH;

#pragma loop unroll
    for(int i = 0; i < PKT_COUNT; i++)
    {
        XUD_SetBuffer(ep_in1, buffer[i], length++);
    }


    if(die)
        exit(0);
    else
        while(1);
}



#define FAIL_RX_DATAERROR   0
#define FAIL_RX_LENERROR    1
#define FAIL_RX_EXPECTED_CTL 2
#define FAIL_RX_BAD_RETURN_CODE 3

unsigned fail(int x)
{
    switch(x)
    {
        case FAIL_RX_DATAERROR:
		    printstr("\nXCORE: ### FAIL ### : XCORE RX Data Error\n");
            break;

        case FAIL_RX_LENERROR:
		    printstr("\nXCORE: ### FAIL ### : XCORE RX Length Error\n");
            break;

        case FAIL_RX_EXPECTED_CTL:
            printstr("\nXCORE: ### FAIL ### : Expected a setup\n");
            break;
        
        case FAIL_RX_BAD_RETURN_CODE:
            printstr("\nXCORE: ### FAIL ### : Unexpcected return code\n");
            break;

    }

    exit(1);
}

#pragma unsafe arrays
unsafe int RxDataCheck(unsigned char b[], int l, int epNum)
{
    for (int i = 0; i < l; i++)
    {
        unsigned char y;
        //read_byte_via_xc_ptr_indexed(y, p_rxDataCheck, epNum);
        if(b[i] != g_rxDataCheck_[epNum])
        {
            printstr("#### Mismatch on EP.. \n");
            //printint(epNum); 
            //printstr(". Got:");
            //printhex(b[i]);
            //printstr(" Expected:");
            //printhexln(g_rxDataCheck[epNum]);
            //printintln(l); // Packet length
            printf("### Mismatch on EP: %d. Got %d, Expected %d\n", epNum, b[i], g_rxDataCheck[epNum]);
            return 1;
    
        }

        g_rxDataCheck_[epNum]++;
    }

    return 0;
}

#pragma unsafe arrays
int TestEp_Bulk_Rx(chanend c_out1, int epNum1)
{
    // TODO check rx lengths
    unsigned int length[PKT_COUNT];
    //XUD_Result_t res;

    XUD_ep ep_out1 = XUD_InitEp(c_out1);

    /* Buffer for Setup data */
    unsigned char buffer[PKT_COUNT][1024];

    /* Receive a bunch of packets quickly, then check them */
#pragma loop unroll
    for(int i = 0; i < PKT_COUNT; i++)
    {
        XUD_GetBuffer(ep_out1, buffer[i], length[i]);
    }
#pragma loop unroll
    for(int i = 0; i < PKT_COUNT; i++)
    {
        unsafe
        {
            RxDataCheck(buffer[i], length[i], epNum1);       
        }
    }

    exit(0);
}
