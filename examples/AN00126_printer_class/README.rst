USB Printer Device Class
========================

Summary
-------

This application note shows how to create a USB device compliant to
the standard USB printer device class on an XMOS multicore microcontroller.

The code associated with this application note provides an example of
using the XMOS USB Device Library (XUD) and associated USB class descriptors
to provide a framework for the creation of a USB printer device.

The printer framework uses XMOS libraries to provide a unidirectional printer
device example over high speed USB. The code used in the application note
creates a device which supports the receiving of data from the USB host
in order to demonstrate how to build a USB printer interface on an XMOS
device.

Text files can be printed from the USB host and the text will be sent back to the host via 
debug output from the xCORE device demonstrating the operation of 
the USB printer device in this application.

Note: This application note provides a standard USB Printer Class Device and as a result 
does not require drivers to run on Windows, Mac or Linux.

Required tools and libraries
............................

* xTIMEcomposer Tools - Version >= 15.0.0
* XMOS USB library - Version >= 2.0.0
* XMOS debug printing library - Version >= 2.0.0

Required hardware
.................

This application note is designed to run on an XMOS xCORE-200 or xCORE.AI series device. 

The example code provided with the application has been implemented and tested
on the xCORE.AI EXPLORER board but there is no dependency on this board and it can be
modified to run on any development board which uses an xCORE-200 or xCORE.AI series device.

Prerequisites
.............

  - This document assumes familiarity with the XMOS xCORE architecture, the Universal Serial Bus 2.0 Specification (and related specifications, the XMOS tool chain and the xC language. Documentation related to these aspects which are not specific to this application note are linked to in the references appendix.

  - For descriptions of XMOS related terms found in this document please see the XMOS Glossary [#]_.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the the document XMOS USB Device (XUD) Library [#]_.

  - For information on designing USB devices using the XUD library please see the XMOS USB Device Design Guide for reference [#]_.

.. [#] http://www.xmos.com/published/glossary

.. [#] http://www.xmos.com/published/xuddg

.. [#] http://www.xmos.com/published/xmos-usb-device-design-guide

