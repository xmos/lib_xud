// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};


int TestEp_Control(XUD_ep ep0_out, XUD_ep ep0_in, int epNum)
{
    unsigned int slength;
    unsigned int length;
    XUD_Result_t sres;
    XUD_Result_t res;

    /* Buffer for Setup data */
    unsigned char sbuffer[120];
    unsigned char buffer[120];

    for(int i = PKT_LENGTH_START; i <= PKT_LENGTH_END; i++)
    {
        unsafe
        {
            GenTxPacketBuffer(buffer, i, epNum);

            /* Wait for Setup data */
            sres = XUD_GetSetupBuffer(ep0_out, sbuffer, slength);

            res = XUD_DoGetRequest(ep0_out, ep0_in, buffer, i, i);

            /* Do some checking */
            if(slength != 8)
            {
                return FAIL_RX_DATAERROR;
            }

            if(res != XUD_RES_OKAY)
            {
                return FAIL_RX_BAD_RETURN_CODE;
            }

            if(sres != XUD_RES_OKAY)
            {
                return FAIL_RX_BAD_RETURN_CODE;
            }

            if(RxDataCheck(sbuffer, slength, epNum, 8))
            {
                return FAIL_RX_DATAERROR;
            }

        }
    }
    return 0;
}

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    XUD_ep c_ep0_out = XUD_InitEp(c_ep_out[0]);
    XUD_ep c_ep0_in  = XUD_InitEp(c_ep_in[0]);

    unsigned failed = TestEp_Control(c_ep0_out, c_ep0_in, 0);

    XUD_Kill(c_ep0_out);
    return failed;
}

