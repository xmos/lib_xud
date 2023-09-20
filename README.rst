XMOS USB Device (XUD) Library
=============================

:Version: 2.2.4
:Vendor: XMOS


:Scope: General Use

Overview
........

lib_xud merges the existing sc_xud and lib_usb (a fork of sc_xud) and replaces them both. It includes an API that supports both previous libraries providing a unified and maintained library going forward.

The XMOS USB Device (XUD) library provides a low-level interface to USB.  lib_xud is a software defined, industry-standard, USB library
that allows you to control an USB bus via xCORE ports.

The library provides functionality to act as a USB *device* only.

This library is for use with xCORE-200 Series or xCORE-AI series devices only, previous generations of xCORE devices are no longer supported.

Note, at points lib_xud will run in "fast mode" this is a requirement to meet timing.

Features
........

 * USB 2.0 Full-speed (12Mbps) and High-speed (480Mbps)
 * Device mode
 * Bulk, control, interrupt and isochronous endpoint types supported

Known Issues
............
 
  * SOF tokens are not CRC checked on XS3 based devices (see tests/test_sof_badcrc)
  * Documentation not updated for removal of XS1 and addition of XS3 based devices

Software version and dependencies
.................................

The CHANGELOG contains information about the current and previous versions.
For a list of direct dependencies, look for DEPENDENT_MODULES in lib_xud/module_build_info.

Related Application Notes
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

Required Software (dependencies)
================================

  * None

Documentation
=============

You can find the documentation for this software in the /doc directory of the package.

Support
=======

This package is supported by XMOS Ltd. Issues can be raised against the software at: http://www.xmos.com/support

