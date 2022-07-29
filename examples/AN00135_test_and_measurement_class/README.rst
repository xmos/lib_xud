USB Test and Measurement Device
===============================

Summary
-------

This application note shows how to create a USB Test and Measurement class 
device on an XMOS multicore microcontroller.

The code associated with this application note uses the XMOS USB Device Library 
and associated USB class descriptors to create a standard USB test and 
measurement class (USBTMC) device running over high speed USB. The code supports 
the minimal standard requests associated with this class of USB devices.

The application demonstrates VISA compliant USBTMC client host software (such as 
NI LabVIEW, NI MAX, pyUsbtmc etc.) request test and measurement data using a subset of 
SCPI commands implemented on xCORE device. 
The application also integrates an open source SCPI library and thus provides a framework 
to implement the needed SCPI commands easily on a USBTMC xCORE device.

Required tools and libraries
............................

* xTIMEcomposer Tools - Version >= 15.0.0
* XMOS USB library - Version >= 2.0.0

Required hardware
.................

This application note is designed to run on an XMOS xCORE-200 or xCORE.AI series devices. 

The example code provided with the application note has been implemented and tested
on the xCORE EXPLORER board(s) but there are no dependencies on this board and it can be
modified to run on any development board which uses an xCORE-200 or xCORE.AI series device with USB functionality.

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

