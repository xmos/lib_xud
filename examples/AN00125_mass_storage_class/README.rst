USB Mass Storage Device Class
=============================

Summary
-------

This application note shows how to create a USB device compliant to the standard
USB mass storage device class on an `xmos xcore.ai` device.

The code associated with this application note provides an example of using the
`XMOS` Device Library and associated USB class descriptors to provide a framework for the
creation of a USB mass storage device.

The mass storage framework uses XMOS libraries to provide a bidirectional
mass storage device example over high speed USB.

Note: This application note provides a standard USB Mass Storage Device Class which
addresses Bulk-Only Transport (BOT) or Bulk/Bulk/Bulk (BBB) specification and as a
result does not require drivers to run on Windows, Linux or Mac.

The Peripheral Device Type (PDT) supported in this application note is SCSI (Small Computer
System Interface) Block Command (SBC) Direct-access device (e.g., UHD (Ultra High Definition)
Floppy disk). This example application uses the on-board serial flash M25P16 as its memory device.

Required hardware
.................

This application note is designed to run on an `XMOS xcore-200` or `xcore.ai` series device.

The example code provided with the application has been implemented and tested
on the `XK-EVK-XU316` board but there is no dependency on this board and it can be modified to
run on any development board which uses an `xcore-200` or `xcore.ai` series device.

Prerequisites
.............

  - This document assumes familiarity with the `XMOS xcore` architecture, the Universal Serial
    Bus 2.0 Specification (and related specifications), the `XMOS` tool chain and the xC language.
    Documentation related to these aspects which are not specific to this application note are linked to in the references appendix.

  - For the full API listing of the XMOS USB Device (XUD) Library please see thedocument XMOS USB Device (XUD) Library [#]_.

  .. [#] https://www.xmos.com/file/lib_xud

