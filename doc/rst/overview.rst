.. _xmos_usb_device_library:

********
Overview
********

`xcore.ai` devices and selected `xcore-200` devices include an integrated USB transceiver.
The XUD library allows the implementation of both full-speed and high-speed USB 2.0 devices on
these devices.  ``lib_xud`` provides an identical API for all devices.

The library performs all of the low-level I/O operations required to meet
the USB 2.0 specification. This processing goes up to and includes the
transaction level. It removes all low-level timing requirements from the
application, allowing quick development of all manner of USB devices.

The XUD library runs in a single core with endpoint and application
cores communicating with it via a combination of channel communication
and shared memory variables.

One channel is required per IN or OUT endpoint. Endpoint 0 (the control
endpoint) requires two channels, one for each direction. Please note that
throughout this document the USB nomenclature is used: an OUT endpoint
is used to transfer data from the host to the device, an IN endpoint is
used when the host requests data from the device.

An example task diagram is shown in :numref:`figure_xud_overview`.  Circles
represent cores running with arrows depicting communication
channels between these cores. In this configuration there is one
core that deals with endpoint 0, which has both the input and output
channel for endpoint 0. IN endpoint 1 is dealt with by a second core,
and OUT endpoint 2 and IN endpoint 5 are dealt with by a third core.
Cores must be ready to communicate with the XUD library whenever the
host demands its attention. If not, the XUD library will NAK.

It is important to note that, for performance reasons, cores
communicate with the XUD library using both XC channels and shared
memory communication. Therefore, *all cores using the XUD library must
be on the same tile as the library itself*.

.. _figure_xud_overview:

.. figure:: images/xud_overview.*
   :width: 120mm
   :align: center

   XUD Overview

