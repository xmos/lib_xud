USB Video Class Device
======================

Summary
-------

This application note shows how to create a USB device compliant to
the standard USB Video Class (UVC) on an XMOS multicore microcontroller.

The code associated with this application note provides an example of
using the XMOS USB Device Library (XUD) and associated USB class descriptors
to provide a framework for the creation of USB video devices like webcam, video player,
camcorders etc.

This example USB video class implementation provides a video camera device running over high
speed USB. It supports standard requests associated with the class. The application doesn't
connect a camera sensor device but emulates it by creating simple video data which is streamed
to the host PC. Any host software that supports viewing UVC compliant video capture devices can
be used to view the video streamed out of the XMOS device. This demonstrates the simple way in
which USB video devices can easily be deployed using an xCORE-USB device.

.. note::

    This application note provides a standard USB video class device and as a
    result does not require external drivers to run on Windows, macOS or Linux.

Required hardware
.................

This application note is designed to run on `XMOS xcore-200` or `xcore.ai` series devices.

The example code provided with the application has been implemented and tested
on the `XK-EVK-XU316` board but there is no dependency on this board and it can be
modified to run on any development board which uses an `xcore-200` or `xcore.ai` series device.

Prerequisites
.............

  - This document assumes familiarity with the `XMOS xcore` architecture, the Universal Serial Bus 2.0 Specification and related specifications, the XMOS tool chain and the xC language. Documentation related to these aspects which are not specific to this application note are linked to in the references appendix.

  - For the full API listing of the XMOS USB Device (XUD) Library please see the document XMOS USB Device (XUD) Library [#]_.

  .. [#] https://www.xmos.com/file/lib_xud

