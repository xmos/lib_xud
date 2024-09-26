USB Image Device Class
======================

Summary
-------

This application note shows how to create a USB device compliant to the standard USB still image
capture device class on an `XMOS xcore` device.

The code associated with this application note provides an example of
using the `XMOS` USB Device Library (XUD) and associated USB class descriptors to provide a
framework for image acquisition over high speed USB using an XMOS device. The code used in the
application note creates a still image capture device and supports the transactions between the USB
ost and the device compliant to PIMA 15740 Picture Transfer Protocol.

Commands for image capture are sent from a host application to the device. The example running on
the `xcore` in turn responds to these commands. It also generates the appropriate image and
transfers to the host. The host application stores the received data in an image file format.

.. note::

    The software accompanying this application note, we have used the open source ``libusb`` and
    ``ImageMagick`` host libraries.

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

