USB Mass Storage Device Class
=============================

Summary
-------

This application note shows how to create a USB device compliant to the standard 
USB mass storage device class on an XMOS multicore microcontroller.

The code associated with this application note provides an example of using the 
XMOS Device Library and associated USB class descriptors to provide a framework for the 
creation of a USB mass storage device.

The mass storage framework uses XMOS libraries to provide a bidirectional 
mass storage device example over high speed USB. 

Note: This application note provides a standard USB Mass Storage Device Class which 
addresses Bulk-Only Transport (BOT) or Bulk/Bulk/Bulk (BBB) specification and as a 
result does not require drivers to run on Windows, Linux or Mac.

The Peripheral Device Type (PDT) supported in this application note is SCSI (Small Computer 
System Interface) Block Command (SBC) Direct-access device (e.g., UHD (Ultra High Definition) 
Floppy disk). This example application uses the on-board serial flash M25P16 as its memory device.

Required tools and libraries
............................

* xTIMEcomposer Tools - Version >= 15.0.0
* XMOS USB Device Library - Version >= 2.0.0

Required hardware
.................

This application note is designed to run on an XMOS xCORE-200 or xCORE.AI series device. 

The example code provided with the application has been implemented and tested
on the xCORE.AI EXPLORER board but there is no dependency on this board and it can be modified to run on any development board 
which uses an xCORE-200 or xCORE.AI series device.

Prerequisites
.............

  - This document assumes familiarity with the XMOS xCORE architecture, the Universal Serial Bus 2.0 Specification (and related specifications), the XMOS tool chain and the xC language. Documentation related to these aspects which are not specific to this application note are linked to in the references appendix.

  - For descriptions of XMOS related terms found in this document please see the XMOS Glossary [#]_.

  - For the full API listing of the XMOS USB Device (XUD) Library please see thedocument XMOS USB Device (XUD) Library [#]_.

  - For information on designing USB devices using the XUD library please see the XMOS USB Device Design Guide for reference [#]_.

  .. [#] http://www.xmos.com/published/glossary

  .. [#] http://www.xmos.com/published/xuddg

  .. [#] http://www.xmos.com/published/xmos-usb-device-design-guide
