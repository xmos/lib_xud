/*
 * Test the use of the ExampleTestbench. Test that the value 0 and 1 can be sent
 * in both directions between the ports.
 *
 * NOTE: The src/testbenches/ExampleTestbench must have been compiled for this to run without error.
 *
 */
#include <xs1.h>
#include <print.h>
#include "xud.h"
#include "platform.h"
#include "test.h"

#define XUD_EP_COUNT_OUT   2
#define XUD_EP_COUNT_IN    2

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};

/* USB Port declarations */
on stdcore[0]: out port p_usb_rst = XS1_PORT_1A;
on stdcore[0]: clock    clk       = XS1_CLKBLK_3;

on stdcore[0] : out port p_test = XS1_PORT_1I;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in, chanend ?c_usb_test);

char reportBuffer[] = {0, 0, 0, 0};

/*
 * This function responds to the HID requests - it draws a square using the mouse moving 40 pixels
 * in each direction in sequence every 100 requests.
 */
void hid(chanend chan_ep1) 
{
    int counter = 0;
    int state = 0;
    
    XUD_ep c_ep1 = XUD_Init_Ep(chan_ep1);
   
    counter = 0;
    while(1) 
    {
        counter++;
        if(counter == 400) 
        {
            if(state == 0) 
            {
                reportBuffer[1] = 40;
                reportBuffer[2] = 0; 
                state+=1;
            } 
            else if(state == 1) 
            {
                reportBuffer[1] = 0;
                reportBuffer[2] = 40;
                state+=1;
            } 
            else if(state == 2) 
            {
                reportBuffer[1] = -40;
                reportBuffer[2] = 0; 
                state+=1;
            } 
            else if(state == 3) 
            {
                reportBuffer[1] = 0;
                reportBuffer[2] = -40;
                state = 0;
            }
            counter = 0;
        } 
        else 
        {
            reportBuffer[1] = 0;
            reportBuffer[2] = 0; 
        }

        if (XUD_SetBuffer(c_ep1, reportBuffer, 4) < 0)
        {
            XUD_ResetEndpoint(c_ep1, null);
        }
    }
}


void TestEp(chanend chan_ep) 
{
    unsigned char buffer[1024];

    XUD_ep ep = XUD_Init_Ep(chan_ep);
   
    XUD_GetBuffer(ep, buffer);

    printstrln("Done");
}



#define USB_CORE 0
int main() 
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par 
    {
        
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
#if (TEST_CRC_BAD) || (TEST_ACK)
        on stdcore[USB_CORE]: TestEp(c_ep_out[1]);
#endif
    }

    return 0;
}
