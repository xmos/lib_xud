/** @file      XUD_GetDone.c
  * @author    Matt Fyles, XMOS Limited
  * @version   1v0
  */

extern int XUD_USB_Done;

int XUD_GetDone() {
  return XUD_USB_Done;
}


