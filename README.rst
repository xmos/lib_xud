XMOS USB Device (XUD) Library
=============================

Overview
--------

This library is currently in a pre-release state.

lib_xud merges the existing sc_xud and lib_usb (a fork of sc_xud) and replaces them both. It includes an API that supports both previous libraries providing a unified and maintained library going forward.

The XMOS USB Device (XUD) library provides a low-level interface to USB.  lib_xud is a software defined, industry-standard, USB library
that allows you to control an USB bus via xCORE ports.

The library provides functionality to act as a USB *device* only.

This library is for use with xCORE-200 Series or xCORE-AI series devices only, previous generations of xCORE devices are no longer supported.

Features
........

 * USB 2.0 Full-speed (12Mbps) and High-speed (480Mbps)
 * Device mode
 * Bulk, control, interrupt and isochronous endpoint types supported

Known Issues
............
 
  * Operation on xCORE-AI devices only supported at 700MHz


Typical Resource Usage
......................

.. resusage::

  * - configuration: USB device (xCORE-200 series)
    - target: XCORE-200-EXPLORER
    - flags: -DXUD_SERIES_SUPPORT=XUD_X200_SERIES
    - globals: XUD_EpType epTypeTableOut[1] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
               XUD_EpType epTypeTableIn[1] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
    - locals: chan c_ep_out[1];chan c_ep_in[1];
    - fn: XUD_Main(c_ep_out, 1, c_ep_in, 1,
                      null, epTypeTableOut, epTypeTableIn, 
                      null, null, -1 , XUD_SPEED_HS, XUD_PWR_BUS);
    - pins: 23 (internal)
    - ports: 11

  * - configuration: USB device (U series)
    - target: SLICEKIT-U16
    - flags: -DXUD_SERIES_SUPPORT=XUD_U_SERIES
    - globals: XUD_EpType epTypeTableOut[1] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
               XUD_EpType epTypeTableIn[1] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
    - locals: chan c_ep_out[1];chan c_ep_in[1];
    - fn: XUD_Main(c_ep_out, 1, c_ep_in, 1,
                      null, epTypeTableOut, epTypeTableIn, 
                      null, null, -1 , XUD_SPEED_HS, XUD_PWR_BUS);
    - pins: 23 (internal)
    - ports: 11

Software version and dependencies
.................................

.. libdeps::

Related application notes
.........................

The following application notes use this library:

.. sidebysidelist::

   * AN00125 - USB mass storage device class 
   * AN00126 - USB printer device class 
   * AN00127 - USB video device class 
   * AN00129 - USB HID device class 
   * AN00131 - USB CDC-EDC device class 
   * AN00132 - USB Image device class 
   * AN00124 - USB CDC VCOM device class
   * AN00135 - USB Test and Measurement device class
   * AN00136 - USB Vendor specific device
