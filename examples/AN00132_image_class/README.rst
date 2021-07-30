USB Image Device Class
======================

Summary
-------

This application note shows how to create a USB device compliant to the standard USB still image capture device class on an XMOS multicore microcontroller. 

The code associated with this application note provides an example of
using the XMOS USB Device Library (XUD) and associated USB class descriptors
to provide a framework for image acquisition over high speed USB using an XMOS device. The code used in the application note creates a still image capture device and supports the transactions between the USB host and the device compliant to PIMA 15740 Picture Transfer Protocol. 

Commands for image capture are sent from a host application to the device. The example running on the xCORE in turn responds to these commands. It also generates the appropriate image and transfers to the host. The host application stores the received data in an image file format.

*Note*:  For the example in this application note, we have used the open source ``libusb`` and ``ImageMagick`` host libraries. 


Required tools and libraries
............................

* xTIMEcomposer Tools - Version >= 15.0.0
* XMOS USB Device Library - Version >= 2.0.0

Required hardware
.................

This application note is designed to run on an XMOS xCORE.AI or xCORE-200 series device. 
The example code provided with the application has been implemented and tested
on the xCORE.AI EXPLORER Board but there is no dependency on this board and it can be
modified to run on any development board which uses an xCORE-200 or xCORE.AI series device.

Prerequisites
.............

  - This document assumes familiarity with the XMOS xCORE architecture, the Universal Serial Bus 2.0 specification, the XMOS tool chain and the xC language. Please see the references in the appendix.

  - For descriptions of XMOS related terms found in this document please see the XMOS Glossary [#]_.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the document XMOS USB Device (XUD) Library [#]_.

  - For information on designing USB devices using the XUD library please see the XMOS USB Device Design Guide [#]_.

.. [#] http://www.xmos.com/published/glossary

.. [#] http://www.xmos.com/published/xuddg

.. [#] http://www.xmos.com/published/xmos-usb-device-design-guide

