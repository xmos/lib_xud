USB CDC-ECM Class for Ethernet over USB
=======================================

Summary
-------

This application note shows how to create a USB device compliant to
the standard USB Communications Device Class (CDC) and the Ethernet Control Model (ECM)
Subclass on an XMOS multicore microcontroller.

The code associated with this application note provides an example of
using the XMOS USB Device Library (XUD) and associated USB class descriptors
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

Note: This application note provides a standard USB CDC-ECM class device and as a 
result does not require external drivers to run on Linux and Mac. Windows doesn't support
USB ECM model natively and thus requires third party drivers.

Required tools and libraries
............................

* xTIMEcomposer Tools - Version >= 15.0.0
* XMOS USB library - Version >= 2.0.0

Required hardware
.................

This application note is designed to run on XMOS xCORE-200 or xCORE.AI series devices.

The example code provided with this application note has been implemented and tested
on the xCORE.AI EXPLORER board but there are no dependencies on this board
and it can be modified to run on any development board which uses an xCORE-200 or xCORE.AI series device.

Prerequisites
.............

  - This document assumes familiarity with the XMOS xCORE architecture, the Universal Serial Bus 2.0 Specification and related specifications, the XMOS tool chain and the xC language. Documentation related to these aspects which are not specific to this application note are linked to in the references appendix.

  - For descriptions of XMOS related terms found in this document please see the XMOS Glossary [#]_.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the document XMOS USB Device (XUD) Library [#]_.

  - For information on designing USB devices using the XUD library please see the XMOS USB Device Design Guide for reference [#]_.

  .. [#] http://www.xmos.com/published/glossary

  .. [#] http://www.xmos.com/published/xuddg

  .. [#] http://www.xmos.com/published/xmos-usb-device-design-guide
