USB HID Class
=============

Summary
-------

This application note shows how to create a USB device compliant to the standard USB Human
Interface Device (HID) class on an `XMOS` device.

The code associated with this application note provides an example of using the XMOS USB Device
Library (``lib_xud``) and associated USB class descriptors to provide a framework for the creation
of a USB HID.

The HID uses `XMOS` libraries to provide a simple mouse example running over high speed USB. The
code used in the application note creates a device which supports the standard requests associated
with this class of USB devices.

The application operates as a simple mouse which when running moves the mouse pointer on the host
machine. This demonstrates the simple way in which PC peripheral devices can easily be deployed
using an `xcore` device.

.. note::

    This application note provides a standard USB HID class device and as a
    result does not require drivers to run on Windows, macOS or Linux.


Required hardware
.................

This application note is designed to run on `XMOS xcore-200` or `xcore.ai` series devices.

The example code provided with the application has been implemented and tested
on the `XK-EVK-XU316` board but there is no dependency on this board and it can be
modified to run on any development board which uses an `xcore-200` or `xcore.ai` series device.

Prerequisites
.............

  - This document assumes familiarity with the `XMOS xcore` architecture, the Universal Serial Bus
    2.0 Specification (and related specifications, the `XMOS` tool chain and the xC language.
    Documentation related to these aspects which are not specific to this application note are
    linked to in the references appendix.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the document XMOS USB
    Device (XUD) Library [#]_.

  .. [#] https://www.xmos.com/file/lib_xud

