// Copyright (c) 2016-2019, XMOS Ltd, All rights reserved

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

#define XUD_Manager XUD_Main

typedef enum t_runMode
{
    RUNMODE_LOOP,
    RUNMODE_DIE
} t_runMode;


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

#if 0
// NEW API - WIP
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
#endif


#pragma unsafe arrays
int TestEp_Tx(chanend c_in[], int epNum1, unsigned start, unsigned end, t_runMode runMode)
{
    XUD_ep ep_in  = XUD_InitEp(c_in[epNum1]);
    
    unsigned char buffer[PKT_COUNT][1024];

    int counter = 0;
    int length = start;

    /* Prepare packets */
    for(int i = 0; i <= (end-start); i++)
    {
        for(int j = 0; j < length; j++)
        {
            buffer[i][j] = counter++;
        }
        length++;
    }

#pragma loop unroll
    length = start;
    for(int i = 0; i <= (end - start); i++)
    {
        XUD_SetBuffer(ep_in, buffer[i], length++);
    }

    if(runMode == RUNMODE_DIE)
        return 0;
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
int RxDataCheck(unsigned char b[], int l, int epNum)
{
    for (int i = 0; i < l; i++)
    {
        unsigned char y;
        //read_byte_via_xc_ptr_indexed(y, p_rxDataCheck, epNum);
        if(b[i] != g_rxDataCheck[epNum])
        {
            printstr("#### Mismatch on EP: ");
            printint(epNum); 
            printstr(". Got:");
            printhex(b[i]);
            printstr(" Expected:");
            printhexln(g_rxDataCheck[epNum]);
            //printintln(l); // Packet length
            return 1;
        }

        g_rxDataCheck[epNum]++;
    }

    return 0;
}

#pragma unsafe arrays
int TestEp_Rx(chanend c_out[], int epNum, int start, int end)
{
    // TODO check rx lengths
    unsigned int length[PKT_COUNT];
    //XUD_Result_t res;

    XUD_ep ep_out1 = XUD_InitEp(c_out[epNum]);

    /* Buffer for Setup data */
    unsigned char buffer[PKT_COUNT][1024];

    /* Receive a bunch of packets quickly, then check them */
#pragma loop unroll
    for(int i = 0; i <= (end-start); i++)
    {
        XUD_GetBuffer(ep_out1, buffer[i], length[i]);
    }
#pragma loop unroll
    for(int i = 0; i <= (end-start); i++)
    {
        unsafe
        {
            RxDataCheck(buffer[i], length[i], epNum);       
        }
    }
}

#if 0
int TestEp_Rx(chanend c_out[], int epNum, unsigned start, unsigned end)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out_0 = XUD_InitEp(c_out[0]);
    XUD_ep ep_out = XUD_InitEp(c_out[epNum]);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    for(int i = start; i <= end; i++)
    {    
        XUD_GetBuffer(ep_out, buffer, length);

        if(length != i)
        {
            printintln(length);
            fail(FAIL_RX_LENERROR);
        }

        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

    }

    XUD_Kill(ep_out_0);
    exit(0);
}
#endif
