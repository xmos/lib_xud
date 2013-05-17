#include "xud.h"

in port p_usb_clk  = PORT_USB_CLK;
in port flag0_port = PORT_USB_FLAG0;
in port flag1_port = PORT_USB_FLAG1;
in port flag2_port = PORT_USB_FLAG2;

#if defined(XUD_ON_U_SERIES)
  out buffered port:32 p_usb_txd = PORT_USB_TXD;
  in  buffered port:32 p_usb_rxd = PORT_USB_RXD;
  out port tx_readyout           = PORT_USB_TX_READYOUT;
  in port tx_readyin             = PORT_USB_TX_READYIN;
  in port rx_rdy                 = PORT_USB_RX_READY;
  
  on USB_TILE: clock tx_usb_clk  = XS1_CLKBLK_5;
  on USB_TILE: clock rx_usb_clk  = XS1_CLKBLK_4;

#elif defined(XUD_ON_L_SERIES)
  out port reg_write_port = PORT_USB_REG_WRITE;
  in  port reg_read_port  = PORT_USB_REG_READ;
  out port p_usb_txd      = PORT_USB_TXD;
  port p_usb_rxd          = PORT_USB_RXD;
#else
  #error Neither XUD_ON_U_SERIES or XUD_ON_L_SERIES defined
#endif

