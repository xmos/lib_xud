// Copyright 2019-2023 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include "xud.h"

#include "XUD_HAL.h"

#ifdef __XS2A__
#include "xs1_to_glx.h"
#include "xs2_su_registers.h"
#include "XUD_USBTile_Support.h"
extern in port flag0_port;
extern in port flag1_port;
extern in port flag2_port;
extern buffered in port:32 p_usb_clk;
#else
extern in port flag0_port; /* For XS3: RXA  or DP */
extern in port flag1_port; /* For XS3: RXE  or DM */
extern buffered in port:32 p_usb_clk;
void XUD_SetCrcTableAddr(unsigned addr);
unsigned XtlSelFromMhz(unsigned m)
{   // NOCOVER
    switch(m) //NOCOVER
    {
        case 10:
            return 0b000;
        case 12:
            return 0b001;
        case 25:
            return 0b010;
        case 30:
            return 0b011;
        case 19: /*.2*/
            return 0b100;
        case 24:
            return 0b101;
        case 27:
            return 0b110;
        case 40:
            return 0b111;
        default:
            /* Panic */
            while(1); //NOCOVER
            break;
    }

    return 0b000;
}
#endif
extern clock rx_usb_clk;

unsigned int XUD_EnableUsbPortMux();

void XUD_HAL_EnableUsb(unsigned pwrConfig)
{
    /* For xCORE-200 enable USB port muxing before enabling phy etc */
    XUD_EnableUsbPortMux(); //setps(XS1_PS_XCORE_CTRL0, UIFM_MODE);

#ifndef XUD_SIM_XSIM

#ifdef __XS2A__
    /* Enable the USB clock */
    write_sswitch_reg(get_tile_id(USB_TILE_REF), XS1_SU_CFG_RST_MISC_NUM, ( 1 << XS1_SU_CFG_USB_CLK_EN_SHIFT));

    /* Now reset the phy */
    write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_PHY_CONTROL_NUM,  0); //(0<<XS1_UIFM_PHY_CONTROL_FORCERESET));

    /* Keep usb clock active, enter active mode */
    write_sswitch_reg(get_tile_id(USB_TILE_REF), XS1_SU_CFG_RST_MISC_NUM, (1 << XS1_SU_CFG_USB_CLK_EN_SHIFT) | (1<<XS1_SU_CFG_USB_EN_SHIFT)  );

    /* Clear OTG control reg - incase we were running as host previously.. */
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_OTG_CONTROL_NUM, 0);
#else
    unsigned d = 0;

    /* Enable wphy and take out of reset */
    read_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG2_NUM, d);
    d = XS1_USB_PHY_CFG2_PONRST_SET(d, 1);
    d = XS1_USB_PHY_CFG2_UTMI_RESET_SET(d, 0);
    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG2_NUM, d);

    /* Setup clocking appropriately */
    read_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG0_NUM, d);
    unsigned xtlselVal = XtlSelFromMhz(XUD_OSC_MHZ);
    d = XS1_USB_PHY_CFG0_XTLSEL_SET(d, xtlselVal);
    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG0_NUM, d);
#endif

    /* Wait for USB clock (typically 1ms after reset) */
    p_usb_clk when pinseq(1) :> int _;
    p_usb_clk when pinseq(0) :> int _;
    p_usb_clk when pinseq(1) :> int _;
    p_usb_clk when pinseq(0) :> int _;

#ifdef __XS2A__
    /* Some extra settings are required for proper operation on XS2A */
    #define XS1_UIFM_USB_PHY_EXT_CTRL_REG 0x50
    #define XS1_UIFM_USB_PHY_EXT_CTRL_VBUSVLDEXT_MASK 0x4

    /* Remove requirement for VBUS in bus-powered mode */
    if(pwrConfig == XUD_PWR_BUS)
    {
        write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_UIFM_USB_PHY_EXT_CTRL_REG, XS1_UIFM_USB_PHY_EXT_CTRL_VBUSVLDEXTSEL_MASK | XS1_UIFM_USB_PHY_EXT_CTRL_VBUSVLDEXT_MASK);
    }

    #define PHYTUNEREGVAL 0x0093B264
    #define XS1_UIFM_USB_PHY_TUNE_REG 0x4c
    /* Phy Tuning parameters */
    /* OTG TUNE: 3b'100
     * TXFSLSTUNE: 4b'1001
     * TXVREFTUNE:4b'1001 -- +1.25% adjustment in HS DC voltage level
     * BIASTUNE: 1b'0
     * COMDISTUNE:3b'011 -- -1.5% adjustment from default (disconnect threshold adjustment)
     * SQRXTUNE:3b'010 -- +5% adjustment from default (Squelch Threshold)
     * TXRISETUNE: 1b'0
     * TXPREEMPHASISTUNE:1b'1 -- enabled (default is disabled)
     * TXHSXVTUNE: 2b'11
     */
    write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_UIFM_USB_PHY_TUNE_REG, PHYTUNEREGVAL);

    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_CONTROL_NUM, (1<<XS1_SU_UIFM_IFM_CONTROL_DECODELINESTATE_SHIFT));
#endif

#endif
}

void XUD_HAL_EnterMode_PeripheralFullSpeed()
{
#ifdef __XS2A__
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM,
        (1<<XS1_SU_UIFM_FUNC_CONTROL_XCVRSELECT_SHIFT) | (1<<XS1_SU_UIFM_FUNC_CONTROL_TERMSELECT_SHIFT));
#else
    unsigned d = 0;
    d = XS1_USB_PHY_CFG0_UTMI_XCVRSELECT_SET(d, 1);
    d = XS1_USB_PHY_CFG0_UTMI_TERMSELECT_SET(d, 1);
    d = XS1_USB_PHY_CFG0_UTMI_OPMODE_SET(d, 0);
    d = XS1_USB_PHY_CFG0_DMPULLDOWN_SET(d, 0);
    d = XS1_USB_PHY_CFG0_DPPULLDOWN_SET(d, 0);

    d = XS1_USB_PHY_CFG0_UTMI_SUSPENDM_SET(d, 1);
    d = XS1_USB_PHY_CFG0_TXBITSTUFF_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_PLL_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_LPM_ALIVE_SET(d, 0);
    d = XS1_USB_PHY_CFG0_IDPAD_EN_SET(d, 0);

    unsigned xtlSelVal = XtlSelFromMhz(XUD_OSC_MHZ);
    d = XS1_USB_PHY_CFG0_XTLSEL_SET(d, xtlSelVal);

    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG0_NUM, d);
#endif
}

void XUD_HAL_EnterMode_PeripheralChirp()
{
#ifdef __XS2A__
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0b1010);
#else
    unsigned d = 0;
    d = XS1_USB_PHY_CFG0_UTMI_XCVRSELECT_SET(d, 0);
    d = XS1_USB_PHY_CFG0_UTMI_TERMSELECT_SET(d, 1);
    d = XS1_USB_PHY_CFG0_UTMI_OPMODE_SET(d, 0b10);
    d = XS1_USB_PHY_CFG0_DMPULLDOWN_SET(d, 0);
    d = XS1_USB_PHY_CFG0_DPPULLDOWN_SET(d, 0);

    d = XS1_USB_PHY_CFG0_UTMI_SUSPENDM_SET(d, 1);
    d = XS1_USB_PHY_CFG0_TXBITSTUFF_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_PLL_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_LPM_ALIVE_SET(d, 0);
    d = XS1_USB_PHY_CFG0_IDPAD_EN_SET(d, 0);

    unsigned xtlselVal = XtlSelFromMhz(XUD_OSC_MHZ);
    d = XS1_USB_PHY_CFG0_XTLSEL_SET(d, xtlselVal);
    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG0_NUM, d);
#endif
}

void XUD_HAL_EnterMode_PeripheralHighSpeed()
{
#ifdef __XS2A__
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0b0000);
#else
    unsigned d = 0;
    d = XS1_USB_PHY_CFG0_UTMI_XCVRSELECT_SET(d, 0); // HS
    d = XS1_USB_PHY_CFG0_UTMI_TERMSELECT_SET(d, 0); // HS
    d = XS1_USB_PHY_CFG0_UTMI_OPMODE_SET(d, 0b00);  // Normal operation
    d = XS1_USB_PHY_CFG0_DMPULLDOWN_SET(d, 0);
    d = XS1_USB_PHY_CFG0_DPPULLDOWN_SET(d, 0);

    d = XS1_USB_PHY_CFG0_UTMI_SUSPENDM_SET(d, 1);
    d = XS1_USB_PHY_CFG0_TXBITSTUFF_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_PLL_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_LPM_ALIVE_SET(d, 0);
    d = XS1_USB_PHY_CFG0_IDPAD_EN_SET(d, 0);

    unsigned xtlselVal = XtlSelFromMhz(XUD_OSC_MHZ);
    d = XS1_USB_PHY_CFG0_XTLSEL_SET(d, xtlselVal);
    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG0_NUM, d);
#endif
}

#ifdef __XS2A__
/* Special case for XSA when exiting resume back to HS - breaks standard HAL API */
unsafe chanend c;
void XUD_HAL_EnterMode_PeripheralHighSpeed_Start()
{
    unsafe
    {
        asm("getr %0, 2" : "=r"(c)); // XS1_RES_TYPE_CHANEND=2 (no inline assembly immediate operands in xC)
        write_periph_word_two_part_start((chanend)c, USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM,  XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0);
    }
}
void XUD_HAL_EnterMode_PeripheralHighSpeed_Complete()
{
    unsafe
    {
        write_periph_word_two_part_end((chanend)c, 0);
        asm("freer res[%0]" :: "r"(c));
    }
}
#endif

void XUD_HAL_EnterMode_PeripheralTestJTestK()
{ // NOCOVER
#ifdef __XS2A__
    write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_FUNC_CONTROL_NUM, 0b1000);
#else
  /* From ULPI Specification Revsion 1.1, table 41
     * XcvrSelect:  00b
     * TermSelect:  0b
     * OpMode:      10b
     * DpPullDown   0b
     * DmPullDown:  0b
     */
    unsigned d = 0;
    d = XS1_USB_PHY_CFG0_UTMI_XCVRSELECT_SET(d, 0);
    d = XS1_USB_PHY_CFG0_UTMI_TERMSELECT_SET(d, 0);
    d = XS1_USB_PHY_CFG0_UTMI_OPMODE_SET(d, 2);
    d = XS1_USB_PHY_CFG0_DMPULLDOWN_SET(d, 0);
    d = XS1_USB_PHY_CFG0_DPPULLDOWN_SET(d, 0);

    d = XS1_USB_PHY_CFG0_UTMI_SUSPENDM_SET(d, 1);
    d = XS1_USB_PHY_CFG0_TXBITSTUFF_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_PLL_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_LPM_ALIVE_SET(d, 0);
    d = XS1_USB_PHY_CFG0_IDPAD_EN_SET(d, 0);

    unsigned xtlSelVal = XtlSelFromMhz(XUD_OSC_MHZ);
    d = XS1_USB_PHY_CFG0_XTLSEL_SET(d, xtlSelVal);

    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG0_NUM, d); // NOCOVER
#endif
}

void XUD_HAL_EnterMode_TristateDrivers()
{ // NOCOVER
#ifdef __XS2A__
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 4);
#else
    /* From ULPI Specification Revsion 1.1, table 41
     * XcvrSelect:  XXb
     * TermSelect:  Xb
     * OpMode:      01b
     * DpPullDown   Xb
     * DmPullDown:  Xb
     */
    unsigned d = 0;
    d = XS1_USB_PHY_CFG0_UTMI_XCVRSELECT_SET(d, 0);
    d = XS1_USB_PHY_CFG0_UTMI_TERMSELECT_SET(d, 0);
    d = XS1_USB_PHY_CFG0_UTMI_OPMODE_SET(d, 1);
    d = XS1_USB_PHY_CFG0_DMPULLDOWN_SET(d, 0);
    d = XS1_USB_PHY_CFG0_DPPULLDOWN_SET(d, 0);

    d = XS1_USB_PHY_CFG0_UTMI_SUSPENDM_SET(d, 1);
    d = XS1_USB_PHY_CFG0_TXBITSTUFF_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_PLL_EN_SET(d, 1);
    d = XS1_USB_PHY_CFG0_LPM_ALIVE_SET(d, 0);
    d = XS1_USB_PHY_CFG0_IDPAD_EN_SET(d, 0);

    unsigned xtlSelVal = XtlSelFromMhz(XUD_OSC_MHZ);
    d = XS1_USB_PHY_CFG0_XTLSEL_SET(d, xtlSelVal);

    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_PHY_CFG0_NUM, d); //NOCOVER
#endif
}


void XUD_HAL_Mode_Signalling()
{
    /* Reset port to use XS1_CLKBLK_REF (from rx_usb_clk) */
    set_port_use_on(flag1_port);

#ifdef __XS2A__
    /* For XS2 we invert VALID_TOKEN port for data-transfer mode, so undo this for signalling */
  	set_port_no_inv(flag2_port);

    write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_MASK_NUM,
        ((1<<XS1_UIFM_IFM_FLAGS_SE0_SHIFT)<<16)
        | ((1<<XS1_UIFM_IFM_FLAGS_K_SHIFT)<<8)
        | (1 << XS1_UIFM_IFM_FLAGS_J_SHIFT));
#else
    unsigned d = 0;
    d = XS1_USB_SHIM_CFG_FLAG_MODE_SET(d, 1);
    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_SHIM_CFG_NUM, d);
#endif
}

void XUD_HAL_Mode_DataTransfer()
{
    configure_in_port(flag1_port, rx_usb_clk);
    set_pad_delay(flag1_port, 2);

#ifdef __XS2A__
    /* Set UIFM to CHECK TOKENS mode and enable LINESTATE_DECODE
     * NOTE: Need to do this every iteration since CHKTOK would break power signaling */
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_CONTROL_NUM,
            (1<<XS1_SU_UIFM_IFM_CONTROL_DOTOKENS_SHIFT)
            | (1<< XS1_SU_UIFM_IFM_CONTROL_CHECKTOKENS_SHIFT)
            | (1<< XS1_SU_UIFM_IFM_CONTROL_DECODELINESTATE_SHIFT)
            | (1<< XS1_SU_UIFM_IFM_CONTROL_SOFISTOKEN_SHIFT));

    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_MASK_NUM,
            ((1<<XS1_SU_UIFM_IFM_FLAGS_RXERROR_SHIFT)
             | ((1<<XS1_SU_UIFM_IFM_FLAGS_RXACTIVE_SHIFT)<<8)
             | ((1<<XS1_SU_UIFM_IFM_FLAGS_NEWTOKEN_SHIFT)<<16)));

    /* Flag 2 (VALID_TOKEN) port is inverted as an optimisation (having a zero is useful) */
  	set_port_inv(flag2_port);
#else
    unsigned d = 0;
    d = XS1_USB_SHIM_CFG_FLAG_MODE_SET(d, 0);
    write_sswitch_reg(get_local_tile_id(), XS1_SSWITCH_USB_SHIM_CFG_NUM, d);
#endif
}

/* In full-speed and low-speed mode, LineState(0) always reflects DP and LineState(1) reflects DM */
/* Note, this port ordering is the opposite of what might be expected - but linestate is swapped in the USB shim */
#define dp_port flag0_port      // DP: LINESTATE[0]
#define dm_port flag1_port      // DM: LINESTATE[1]

{unsigned, unsigned} LineStateToLines(XUD_LineState_t ls)
{
    return {ls & 1, (ls >> 1) & 1};
}

static inline XUD_LineState_t LinesToLineState(unsigned dp, unsigned dm)
{
    return (XUD_LineState_t) (dp & 1) | ((dm & 1)<< 1);
}

/* TODO pass structure  */
XUD_LineState_t XUD_HAL_GetLineState(/*XUD_HAL_t &xudHal*/)
{
#ifdef __XS2A__
    unsigned j, k, se0;
    flag0_port :> j;
    flag1_port :> k;
    flag2_port :> se0;

    if(j)
        return XUD_LINESTATE_HS_J_FS_K;
    if(k)
        return XUD_LINESTATE_HS_K_FS_J;
    if(se0)
        return XUD_LINESTATE_SE0;

    return XUD_LINESTATE_SE1;
#else
    unsigned dp, dm;
    dp_port :> dp;
    dm_port :> dm;
    return LinesToLineState(dp, dm);
#endif
}

// TODO debounce?
unsigned XUD_HAL_WaitForLineStateChange(XUD_LineState_t &currentLs, unsigned timeout)
{
    unsigned time;
    timer t;

    if (timeout != null)
        t :> time;

#ifdef __XS2A__
    unsigned se0 = currentLs == XUD_LINESTATE_SE0;
    unsigned j = currentLs == XUD_LINESTATE_HS_J_FS_K;
    unsigned k = currentLs == XUD_LINESTATE_HS_K_FS_J;

    /* Wait for a change on any flag port */
    select
    {
        case flag0_port when pinsneq(j) :> void:
            break;
        case flag1_port when pinsneq(k) :> void:
            break;
        case flag2_port when pinsneq(se0) :> void:
            break;
        case timeout != null => t when timerafter(time + timeout) :> int _:
            return 1;
    }

    /* Read current line state - two lines may have change e.g k/j to SE0 */
    currentLs = XUD_HAL_GetLineState();
    return 0;
#else
    unsigned dp, dm;

    /* Look up line values from linestate */
    {dp, dm} = LineStateToLines(currentLs);

    /* Wait for change */
    select
    {
        case dp_port when pinsneq(dp) :> dp:
            dm_port :> dm; //Both might have changed!
            break;
        case dm_port when pinsneq(dm) :> dm:
            dp_port :> dp; //Both might have changed!
            break;
        case timeout != null => t when timerafter(time + timeout) :> int _:
            return 1;
    }

    /* Return new linestate */
    currentLs = LinesToLineState(dp, dm);
    return 0;
#endif
}

void XUD_HAL_SetDeviceAddress(unsigned char address)
{
#ifdef __XS2A__
    write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_DEVICE_ADDRESS_NUM, address);
#else
    XUD_SetCrcTableAddr(address);
#endif
}

/* Note, this is called from XUA_HAL.c (weak symbol) */
unsigned int XUD_HAL_GetVBusState_(void)
{
#ifdef __XS2A__
    unsigned int x;
    read_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_OTG_FLAGS_NUM, x);
    return x & (1 << XS1_UIFM_OTG_FLAGS_SESSVLDB_SHIFT);
#else
    return 1u;
#endif
}

