USB Vendor Specific Device
==========================

Summary
-------

This application note shows how to create a vendor specific USB device 
which is on an XMOS multicore microcontroller.

The code associated with this application note provides an example of
using the XMOS USB Device Library and associated USB class descriptors
to provide a framework for the creation of a USB vendor specific device.

This example uses XMOS libraries to provide a simple USB bulk transfer
device running over high speed USB. The code used in the application note
creates a device which supports the standard requests associated with this 
class of USB devices.

The application operates as a simple data transfer device which can transmit
and receive buffers between a USB host and XMOS based USB device.
This demonstrates the simple way in which custom USB devices can easily be 
deployed using an xCORE device.

Note: This application note provides a custom USB class device as an example 
and requires a driver to run on windows. For this example we have used
the open source libusb host library and windows driver to allow the demo
device to be used from the host machine. On other host platforms supported
by this application example a host driver is not required to interact with libusb.

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

  - This document assumes familiarity with the XMOS xCORE architecture, the Universal Serial Bus 2.0 Specification (and related specifications, the XMOS tool chain and the xC language. Documentation related to these aspects which are not specific to this application note are linked to in the references appendix.

  - For descriptions of XMOS related terms found in this document please see
    the XMOS Glossary [#]_.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the document XMOS USB Device (XUD) Library [#]_. 

  - For information on designing USB devices using the XUD library please see 
    the XMOS USB Device Design Guide for reference [#]_. 

.. [#] http://www.xmos.com/published/glossary

.. [#] http://www.xmos.com/published/xuddg
    
.. [#] http://www.xmos.com/published/xmos-usb-device-design-guide

