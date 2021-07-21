XMOS USB Device (XUD) Library
=============================

Overview
--------

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
 
  * Operation on XS3 based devices only supported at 700MHz
  * SOF tokens are not CRC checked on XS3 based devices (see tests/test_sof_badcrc)

Software version and dependencies
.................................

The CHANGELOG contains information about the current and previous versions.
For a list of direct dependencies, look for DEPENDENT_MODULES in lib_xud/module_build_info.

Related application notes
.........................

The following application notes use this library:

   * AN00125 - USB mass storage device class 
   * AN00126 - USB printer device class 
   * AN00127 - USB video device class 
   * AN00129 - USB HID device class 
   * AN00131 - USB CDC-EDC device class 
   * AN00132 - USB Image device class 
   * AN00124 - USB CDC VCOM device class
   * AN00135 - USB Test and Measurement device class
   * AN00136 - USB Vendor specific device
