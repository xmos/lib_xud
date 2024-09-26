USB CDC Class as Virtual Serial Port
====================================

Summary
-------

This application note shows how to create a USB device compliant to
the standard USB Communications Device Class (CDC) on an `XMOS` device.

The code associated with this application note provides an example of
using the `XMOS` USB Device Library (XUD) and associated USB class descriptors
to provide a framework for the creation of a USB CDC device that implements
Abstract Control Model (ACM).

This example USB CDC ACM implementation provides a Virtual Serial port
running over high speed USB. The Virtual Serial port supports the
standard requests associated with ACM model of the class.

A serial terminal program from host PC connects to virtual serial port and
interacts with the application. This basic application demo implements a loopback
of characters from the terminal to the `XMOS` device and back to the terminal.
This application demo code demonstrates a simple way in which USB CDC class
devices can easily be deployed using an `xcore-200` or `xcore.ai` device.

Note: This application note provides a standard USB CDC class device and as a
result does not require external drivers to run on Windows, macOS or Linux.

Required hardware
.................

This application note is designed to run on an `XMOS xcore-200` or `xcore.ai` series devices.

The example code provided with the application has been implemented and tested
on the `XK-EVK-XU316` board but there is no dependancy on this board
and it can be modified to run on any development board which uses an `xcore-200` or `xcore.ai`
series device.

Prerequisites
.............

  - This document assumes familiarity with the `XMOS xcore` architecture, the Universal Serial Bus
    2.0 Specification and related specifications, the `XMOS` tool chain and the xC language.
    Documentation related to these aspects which are not specific to this application note are
    linked to in the references appendix.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the document XMOS USB
    Device (XUD) Library [#]_.

  .. [#] https://www.xmos.com/file/lib_xud

