USB CDC-ECM Class for Ethernet over USB
=======================================

Summary
-------

This application note shows how to create a USB device compliant to
the standard USB Communications Device Class (CDC) and the Ethernet Control Model (ECM)
Subclass on an `XMOS` device.

The code associated with this application note provides an example of
using the XMOS USB Device Library (``lib_xud``) and associated USB class descriptors
to provide a framework for the creation of a USB device emulating Ethernet.

This example USB CDC-ECM implementation provides an emulated Ethernet interface
running over high speed USB. It supports the standard requests associated with ECM model
of the USB CDC specification.

The demo application handles the Ethernet frames received from the USB endpoitns and hosts a
HTTP web server acting as another virtual network device. A standard web browser from host PC
can open the web page served from the USB device. The web page provides a statistics of
different packets like ICMP, TCP, UDP etc received through the Ethernet frames from the host PC.
This demonstrates a simple way in which Ethernet over USB applications can easily be deployed
using an xCORE-USB device.

The demo application code can be extended to bridge an actual Ethernet interface by adding MAC
and MII software layers. This enables you to create USB to Ethernet Adaptors using xCORE-USB
device.

.. note::

    his application note provides a standard USB CDC-ECM class device and as a
    result does not require external drivers to run on Linux and macOS. Windows doesn't support
    USB ECM model natively and thus requires third party drivers.

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

