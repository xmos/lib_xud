/**
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2013
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the
 * copyright notice above.
 *
 **/

#include "hid_mouse_demo.h"
#include "xud.h"

#if (USE_XSCOPE == 1)
void xscope_user_init(void) {
    xscope_register(0, 0, "", 0, "");
    xscope_config_io(XSCOPE_IO_BASIC);
}
#endif

#define XUD_EP_COUNT_OUT   1
#define XUD_EP_COUNT_IN    2

/* Prototype for Endpoint0 function in endpoint0.xc */
void Endpoint0(/*tileref * unsafe usbtile, */chanend c_ep0_out, chanend c_ep0_in);

/* Endpoint type tables - informs XUD what the transfer types for each Endpoint in use and also
 * if the endpoint wishes to be informed of USB bus resets
 */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL};

#if (XUD_SERIES_SUPPORT == XUD_U_SERIES) || (XUD_SERIES_SUPPORT == XUD_X200_SERIES)
  /* USB Reset not required for U series - pass null to XUD */
  #define p_usb_rst null
  #define clk_usb_rst null
#else
  /* USB reset port declarations for L series */
  on USB_TILE: out port p_usb_rst   = PORT_USB_RESET;
  on USB_TILE: clock    clk_usb_rst = XS1_CLKBLK_3;
#endif

/* Global report buffer, global since used by Endpoint0 core */
unsigned char g_reportBuffer[] = {0, 0, 0, 0};

#ifdef ADC
  #if (XUD_SERIES_SUPPORT == XUD_L_SERIES)
    #error NO ADC ON L-SERIES
  #endif

  #include <xs1_su.h>
  #include "usb_tile_support.h"

  /* Port for ADC triggering */
  on USB_TILE: out port p_adc_trig = PORT_ADC_TRIGGER;
#endif

#ifdef ADC

#if (U16 == 1)
#define BITS 5          // Overall precision
#define DEAD_ZONE 2     // Ensure that the mouse is stable when the joystick is not used
#else
#define BITS 8          // Overall precision
#define DEAD_ZONE 0     // Ensure that the mouse is stable when the joystick is not used
#endif

#define SENSITIVITY 1   // Sensitivity range 0 - 9

#define SHIFT  (32 - BITS)
#define MASK   ((1 << BITS) - 1)
#define OFFSET (1 << (BITS - 1))

/*
 * This function responds to the HID requests - it moves the pointers x axis based on ADC input
 */
void hid_mouse(chanend c_ep_hid, chanend c_adc)
{
    int initialDone = 0;
    int initialX = 0;
    int initialY = 0;

    /* Initialise the XUD endpoint */
    XUD_ep ep_hid = XUD_InitEp(c_ep_hid);

    /* Configure and enable the ADC in the U device */
    adc_config_t adc_config = { { 0, 0, 0, 0, 0, 0, 0, 0 }, 0, 0, 0 };

    if (U16)
    {
        adc_config.input_enable[2] = 1;
        adc_config.input_enable[3] = 1;
        adc_config.samples_per_packet = 2;
    }
    else
    {
        adc_config.input_enable[0] = 1;
        adc_config.samples_per_packet = 1;
    }
    adc_config.bits_per_sample = ADC_32_BPS;
    adc_config.calibration_mode = 0;

    adc_enable(usb_tile, c_adc, p_adc_trig, adc_config);

    while (1)
    {
        unsigned data[2];
        int x;
        int y;

        /* Initialise the HID report buffer */
        g_reportBuffer[1] = 0;
        g_reportBuffer[2] = 0;

        /* Get ADC input */
        adc_trigger_packet(p_adc_trig, adc_config);
        adc_read_packet(c_adc, adc_config, data);
        x = data[0];
        if (U16)
            y = data[1];

        /* Move horizontal axis of pointer based on ADC val (absolute) */
        x = ((x >> SHIFT) & MASK) - OFFSET - initialX;
        if (x > DEAD_ZONE)
            g_reportBuffer[1] = (x - DEAD_ZONE)/(10 - SENSITIVITY);
        else if (x < -DEAD_ZONE)
            g_reportBuffer[1] = (x + DEAD_ZONE)/(10 - SENSITIVITY);

        if (U16)
        {
            /* Move vertical axis of pointer based on ADC val (absolute) */
            y = ((y >> SHIFT) & MASK) - OFFSET - initialY;
            if (y > DEAD_ZONE)
                g_reportBuffer[2] = (y - DEAD_ZONE)/(10 - SENSITIVITY);
            else if (y < -DEAD_ZONE)
                g_reportBuffer[2] = (y + DEAD_ZONE)/(10 - SENSITIVITY);

            /* Only do initial offset on U16 with relative mode */
            if (!initialDone)
            {
                initialX = x;
                initialY = y;
                initialDone = 1;
            }
        }

        /* Send the buffer off to the host.  Note this will return when complete */
        XUD_SetBuffer(ep_hid, g_reportBuffer, 4);
    }
}

#else // ADC
/*
 * This function responds to the HID requests - it draws a square using the mouse moving 40 pixels
 * in each direction in sequence every 100 requests.
 */
void hid_mouse(chanend chan_ep_hid, chanend ?c_adc)
{
    int counter = 0;
    int state = 0;

    XUD_ep ep_hid = XUD_InitEp(chan_ep_hid);

    while (1)
    {
        int x;
        g_reportBuffer[1] = 0;
        g_reportBuffer[2] = 0;

        /* Move the pointer around in a square (relative) */
        counter++;
        if (counter >= 500)
        {
            counter = 0;
            if (state == 0)
            {
                g_reportBuffer[1] = 40;
                g_reportBuffer[2] = 0;
                state+=1;
            }
            else if (state == 1)
            {
                g_reportBuffer[1] = 0;
                g_reportBuffer[2] = 40;
                state+=1;
            }
            else if (state == 2)
            {
                g_reportBuffer[1] = -40;
                g_reportBuffer[2] = 0;
                state+=1;
            }
            else if (state == 3)
            {
                g_reportBuffer[1] = 0;
                g_reportBuffer[2] = -40;
                state = 0;
            }
        }

        /* Send the buffer off to the host.  Note this will return when complete */
        XUD_SetBuffer(ep_hid, g_reportBuffer, 4);
    }
}
#endif // ADC

#if (U16 == 1)
#define PWR_MODE XUD_PWR_SELF
#else
#define PWR_MODE XUD_PWR_BUS
#endif

unsafe
{
    tileref * unsafe usbtile = &usb_tile;
}

/*
 * The main function runs three cores: the XUD manager, Endpoint 0, and a HID endpoint. An array of
 * channels is used for both IN and OUT endpoints, endpoint zero requires both, HID requires just an
 * IN endpoint to send HID reports to the host.
 */
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
#ifdef ADC
    chan c_adc;
#else
#define c_adc null
#endif

    par
    {
        on USB_TILE: XUD_Manager(/*usbtile*/ c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk_usb_rst, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        on USB_TILE: Endpoint0(/*usbtile*/ c_ep_out[0], c_ep_in[0]);

        on USB_TILE: hid_mouse(c_ep_in[1], c_adc);

#ifdef ADC
        xs1_su_adc_service(c_adc);
#endif
    }

    return 0;
}
