#ifdef XUD_SIM_RTL
int testmain()
#else
int main()
#endif
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
        {
#if defined(XUD_TEST_SPEED_FS)
            unsigned speed = XUD_SPEED_FS;
#elif defined(XUD_TEST_SPEED_HS)
            unsigned speed = XUD_SPEED_HS;
#endif
            
            XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                speed, XUD_PWR_BUS);
        }

		{
			unsigned fail = test_func(c_ep_out, c_ep_in);

#ifdef XUD_SIM_RTL
            /* Note, this test relies on checking at the host side */
            if(fail)
                TerminateFail(fail);
            else
                TerminatePass(fail);    
#endif
			
            unsafe{
                unsigned * unsafe p = &g_dummyThreadCount;
                *p = 0;
            }
            XUD_ep ep_out_0 = XUD_InitEp(c_ep_out[0]);
			XUD_Kill(ep_out_0);
			exit(0);
		}

        dummyThreads();
    }

    return 0;
}
