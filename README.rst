:orphan:

###########################
lib_xud: USB Device Library
###########################

:vendor: XMOS
:version: 3.0.1
:scope: General Use
:description: USB device library
:category: General Purpose
:keywords: USB, HID
:devices: xcore.ai, xcore-200

*******
Summary
*******

The XMOS USB Device (XUD) library provides a low-level interface to USB.  `lib_xud` is a software
defined, industry-standard, USB library that allows you to control an USB bus via `xcore` ports.

The library provides functionality to act as a USB *device* only.

********
Features
********

* USB 2.0 Full-speed (12Mbps) and High-speed (480Mbps)
* Device mode
* Bulk, control, interrupt and isochronous endpoint types supported
* A complete worked example of a HID mouse

************
Known issues
************

* SOF tokens are not CRC checked on XS3 based devices (see tests/test_sof_badcrc) (#99)

****************
Development repo
****************

* `lib_xud <https://www.github.com/xmos/lib_xud>`_

**************
Required tools
**************

* XMOS XTC Tools: 15.3.1

*********************************
Required libraries (dependencies)
*********************************

* None

*************************
Related application notes
*************************

The following application notes use this library:

* `AN00124 - USB CDC Class as Virtual Serial Port <https://www.xmos.com/application-notes/an00124>`_
* `AN00125 - USB Mass Storage Device Class <https://www.xmos.com/application-notes/an00125>`_
* `AN00127 - USB Video Class Device <https://www.xmos.com/application-notes/an00127>`_
* `AN00131 - USB CDC-ECM Class for Ethernet over USB <https://www.xmos.com/application-notes/an00131>`_
* `AN00136 - Example USB Vendor Specific Device <https://www.xmos.com/application-notes/an00136>`_

*******
Support
*******

This package is supported by XMOS Ltd. Issues can be raised against the software at:
http://www.xmos.com/support

