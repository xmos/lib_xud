USB Test and Measurement Device
===============================

Summary
-------

This application note shows how to create a USB Test and Measurement class device on a `XMOS xcore`
device.

The code associated with this application note uses the XMOS USB Device Library (``lib_xud``) and
associated USB class descriptors to create a standard USB test and measurement class (USBTMC) device
running over high speed USB. The code supports the minimal standard requests associated with this
class of USB devices.

The application demonstrates VISA compliant USBTMC client host software (such as NI LabVIEW, NI MAX,
pyUsbtmc etc.) request test and measurement data using a subset of SCPI commands implemented on
the `xcore` device.
The application also integrates an open source SCPI library and thus provides a framework
to simple implementation of the required SCPI commands.

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

