sc_xud Change Log
=================

2.0.0 (UNRELEASED)
-----
    * CHANGE:     All XUD functions now return XUD_Result_t. Functions that previously returned 
                  a buffer length (e.g. XUD_GetBuffer) now require a length param (passed by 
                  reference.
    * CHANGE:     Endpoint ready flags are now reset on bus-reset (if XUD_STATUS_ENABLE used). This
                  means an endpoint can avoid sending/receiving stale data after a bus-reset.
    * CHANGE:     Reset notifications are now longer hand-shaken back to XUD_Manager in 
                  XUD_ResetEndpoint. This reduces the possibility of an Endpoint breaking timing 
                  of USB handshake signalling through bad code. XUD functions now check reseting flag
                  to avoid race condition.
    * CHANGE:     XUD_SetReady_In now implemented using XUD_SetReady_InPtr (previously was duplicated
                  code.
    * CHANGE:     XUD_ResetEndpoint now in XC. Previously was an ASM wrapper.
    * CHANGE:     Modifications to xud.h including the use of macros from xccompat.h such that it
                  can be included from .c files.

1.0.3
-----
    * RESOLVED:   (Minor) ULPI data-lines driven hard low and XMOS pull-up on STP line disabled
                  before taking the USB phy out of reset. Previously the phy could clock in
                  erroneous data before the XMOS ULPI interface was initialised causing potential
                  connection issues on initial startup. This affects L/G series libraries only.
    * RESOLVED:   (Minor) Fixes to improve memory usage such as adding missing resource usage
                  symbols/elimination blocks to assembly file and inlining support functions where
                  appropriate.
    * RESOLVED:   (Minor) Moved to using supplied tools support for communicating with the USB tile
                  rather than custom implementation (affects U-series lib only).

  * Changes to dependencies:

    - sc_usb: 1.0.1beta1 -> 1.0.2beta1

      + ADDED:   USB_BMREQ_D2H_VENDOR_DEV and USB_BMREQ_D2H_VENDOR_DEV defines for vendor device requests
_
1.0.2
-----
    * ADDED:      Re-instated support for G devices (xud_g library)

1.0.1
-----
    * CHANGE:     Power signalling state machines simplified in order to reduce memory usage
    * RESOLVED:   (Minor) Reduced delay before transmitting k-chirp for high-speed mode, this
                  improves high-speed handshake reliability on some hosts
    * RESOLVED:   (Major) Resolved a compatibility issue with Intel USB 3.0 xHCI host
                  controllers relating to tight inter-packet timing resulting in packet loss

1.0.0
-----
    * Initial stand-alone release
