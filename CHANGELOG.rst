lib_xud Change Log
==================

1.2.0
-----

  * CHANGED: Use XMOS Public Licence Version 1

1.1.2
-----

  * CHANGED: Pin Python package versions
  * REMOVED: not necessary cpanfile

1.1.1
-----

  * RESOLVED:   Cases where disabling RxError caused firmware to crash
  * RESOLVED:   USB Disconnect on self-powered devices intermittently causing EP
    set to not-ready indefinitely

1.1.0
-----

  * RESOLVED:   Disabled erroneous handling of Rx Error line

1.0.0
-----

  * CHANGE:     Version for first major release.

0.2.0
-----

  * CHANGE:     Build files updated to support new "xcommon" behaviour in xwaf.

0.1.1
-----

  * RESOLVED:   Transmit timing fixes for U-series devices (introduced in sc_xud
    2.3.0)
  * RESOLVED:   Continuous suspend/resume notifications when host disconnected
    (introduced in sc_xud 2.4.2, #11813)
  * RESOLVED:   Exception raised in GET_STATUS request when null pointer passed
    for high-speed configuration descriptor

0.1.0
-----

  * CHANGE:     Fork from sc_xud to lib_xud
  * CHANGE:     Documentation updates


Legacy release history
----------------------

Note: Forked from sc_xud at this point.


2.6.0
-----
    * RESOLVED    Issue referenced as #11813 in 2.4.2 for XS1 devices

2.5.0
-----
    * RESOLVED:   xCORE-200 USB phy parameters tuned for optimal Tx performance resulting
                  in much improved TX eye diagram and compliance test results

2.4.2
-----
    * CHANGE:     VBUS connection to xCORE-200 no longer required when using XUD_PWR_BUS i.e.
                  for bus-powered devices. This removes the need to any protection circuitry and
                  allows for a reduced BOM.
                  Note, VBUS should still be present for self powered devices in order to pass USB
                  compliance tests.
    * RESOLVED:   Device might hang during resume if host follows resume signality with activity
                  after a time close to specified minimum of 1.33us (#11813)

2.4.1
-----
    * RESOLVED:   Initialisation failure on U-series devices

2.4.0
-----
    * RESOLVED:   Intermittent initialisation issues with xCORE-200
    * RESOLVED:   SETUP transaction data CRC not properly checked
    * RESOLVED:   RxError line from phy handled
    * RESOLVED:   Isochronous IN endpoints now send an 0-length packet if not ready rather than
                  an (invalid) NAK.
    * RESOLVED:   Receive of short packets sometimes prematurely ended
    * RESOLVED:   Data PID not reset to DATA0 in ClearStallByAddr() (used on ClearFeature(HALT)
                  request from host) (#17092)

2.3.2
-----
    * CHANGE:     Interrupts disabled during any access to usb_tile. Allows greater reliability
                  if user suspend/resume functions enabled interrupts e.g. for role-switch

2.3.1
-----
    * RESOLVED:   (Minor) XUD_ResetEpStateByAddr() could operate on corresponding OUT endpoint
                  instead of the desired IN endpoint address as passed into the function (and
                  vice versa). Re-introduced into 2.3.0 due to manual merge with lib_usb.

2.3.0
-----
    * ADDED:      Support for XCORE-200 (libxud_x200.a)
    * CHANGE:     Compatibility fixes for XMOS toolset version 14 (dual-issue support etc)

2.2.4
-----
    * RESOLVED:   (Minor) Potential for lock-up when waiting for USB clock on startup. This is is
                  avoided by enabling port buffering on the USB clock port. Affects L/G series only.

2.2.3
------
    * RESOLVED:   (Minor) XUD_ResetEpStateByAddr() could operate on corresponding OUT endpoint
                  instead of the desired IN endpoint address as passed into the function (and
                  vice versa)

2.2.2
-----
    * CHANGE:     Header file comment clarification only

  * Changes to dependencies:

    - sc_usb: 1.0.3rc0 -> 1.0.4alpha0

      + ADDED:      Structs for Audio Class 2.0 Mixer and Extension Units

2.2.1
-----
    * RESOLVED:   Slight optimisations (long jumps replaced with short) to aid inter-packet gaps.

2.2.0
-----
    * CHANGE:     Timer usage optimisation - usage reduced by one.
    * CHANGE:     OTG Flags register explicitly cleared at start up - useful if previously running
                  in host mode after a soft-reboot.

2.1.1
-----
    * ADDED:      Warning emitted when number of cores is greater than 6

2.1.0
-----
    * CHANGE:     XUD no longer takes a additional chanend parameter for enabling USB test-modes.
                  Test-modes are now enabled via a XUD_SetTestMode() function using a chanend
                  relating to Endpoint 0. This change was made to reduce chanend usage only.

2.0.1
-----
    * RESOLVED:   (Minor) Error when building module_xud in xTimeComposer due to invalid project
                  files.

2.0.0
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
    * CHANGE:     XUD_BusSpeed type renamed to XUD_BusSpeed_t in line with naming conventions
    * CHANGE:     XUD_SetData_Select now takes a reference to XUD_Result_t instead an int
    * CHANGE:     XUD_GetData_Select now takes an additional XUD_Result_t parameter by reference
    * CHANGE:     XUD_GetData_Select now returns XUD_RES_ERR instead of a 0 length on packet error
                  (e.g. PID sequence error).
    * CHANGE:     XUD_SetDevAddr now returns XUD_Result_t

  * Changes to dependencies:

    - sc_usb: 1.0.2beta1 -> 1.0.3rc0

      + CHANGE:     Various descriptor structures added, particularly for Audio Class
      + CHANGE:     Added ComposeSetupBuffer() for creating a buffer from a USB_Setup_Packet_t
      + CHANGE:     Various function prototypes now using macros from xccompat.h such that then can be

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

