USB HID Class
=============

Summary
-------

This application note shows how to create a USB device compliant to
the standard USB Human Interface Device (HID) class on an XMOS multicore 
microcontroller.

The code associated with this application note provides an example of
using the XMOS USB Device Library and associated USB class descriptors
to provide a framework for the creation of a USB HID.

The HID uses XMOS libraries to provide a simple mouse example running
over high speed USB. The code used in the application note
creates a device which supports the standard requests associated with this class
of USB devices.

The application operates as a simple mouse which when running moves the mouse
pointer on the host machine. This demonstrates the simple way in which PC
peripheral devices can easily be deployed using an xCORE device.

Note: This application note provides a standard USB HID class device and as a
result does not require drivers to run on Windows, Mac or Linux.

Required tools and libraries
............................

* xTIMEcomposer Tools - Version >= 15.0.0
* XMOS USB library - Version >= 2.0.0

Required hardware
.................

This application note is designed to run on an XMOS xCORE-200 or xCORE.AI series devices. 

The example code provided with this application note has been implemented and tested
on the xCORE EXPLORER board(s) but there are no dependencies on this board and it can be
modified to run on any development board which uses an xCORE-200 or xCORE.AI series device with USB functionality.

Prerequisites
.............

  - This document assumes familiarity with the XMOS xCORE architecture, the Universal Serial Bus 2.0 Specification (and related specifications, the XMOS tool chain and the xC language. Documentation related to these aspects which are not specific to this application note are linked to in the references appendix.

  - For descriptions of XMOS related terms found in this document please see the XMOS Glossary [#]_.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the document XMOS USB Device (XUD) Library [#]_.

  - For information on designing USB devices using the XUD library
      please see the XMOS USB Library Device Design Guide for reference [#]_.

  .. [#] http://www.xmos.com/published/glossary

  .. [#] http://www.xmos.com/published/xuddg

  .. [#] http://www.xmos.com/published/xmos-usb-device-design-guide

