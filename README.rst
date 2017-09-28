XMOS USB Device (XUD) Library
=============================

:Maintainer: XMOS
:Description: Low-Level USB Driver Library

Overview
--------

lib_xud merges the old structure of sc_xud and the unmaintained lib_usb fork of sc_xud with the intention of replacing both.

The XMOS USB Device (XUD) library provides a low-level interface to USB.  lib_xud is a software defined, industry-standard, USB library
that allows you to control an USB bus via xCORE ports.

The library provides functionality to act as a USB *device* only.

This library is aimed primarily for use with xCORE U-Series or
the xCORE-200 Series devices but it does also support xCORE L-Series devices.

Features
........

 * USB 2.0 Full-speed (12Mbps) and High-speed (480Mbps) modes.
 * Device mode.
 * Bulk, control, interrupt and isochronous endpoint types supported.


Typical Resource Usage
......................

.. resusage::

  * - configuration: USB device (U series)
    - target: SLICEKIT-U16
    - flags: -DXUD_SERIES_SUPPORT=XUD_U_SERIES
    - globals:
    - locals: chan c_ep_out[1];chan c_ep_in[1];
    - fn: xud(c_ep_out, 1, c_ep_in, 1,
              null, XUD_SPEED_HS, XUD_PWR_SELF);
    - pins: 23 (internal)
    - ports: 11
  * - configuration: USB device (xCORE-200 series)
    - target: XCORE-200-EXPLORER
    - flags: -DXUD_SERIES_SUPPORT=XUD_X200_SERIES
    - globals:
    - locals: chan c_ep_out[1];chan c_ep_in[1];
    - fn: xud(c_ep_out, 1, c_ep_in, 1,
              null, XUD_SPEED_HS, XUD_PWR_SELF);
    - pins: 23 (internal)
    - ports: 11
  * - configuration: USB device (L series)
    - target: SLICEKIT-L16
    - flags: -DXUD_SERIES_SUPPORT=XUD_L_SERIES
    - globals:
    - locals: chan c_ep_out[1];chan c_ep_in[1];
    - fn: xud_l_series(c_ep_out, 1, c_ep_in, 1,
                       null, null, XUD_SPEED_HS, XUD_PWR_SELF);
    - pins: 13
    - ports: 8


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
   * AN00128 - USB Audio device class 
   * AN00129 - USB HID device class 
   * AN00130 - Extended USB HID class 
   * AN00131 - USB CDC-EDC device class 
   * AN00132 - USB Image device class 
