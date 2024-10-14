
|newpage|

.. _sec_example:

*******************
Example application
*******************

This section contains a fully worked example of implementing a USB mouse device compliant to the
`Human Interface Device (HID) Class <https://usb.org/document-library/device-class-definition-hid-111>`_
mouse device.

The application operates as a simple mouse which when running moves the mouse pointer on the host
machine. This demonstrates the simple way in which PC peripheral devices can easily be deployed
using an `xcore` device.

.. note::

    This application note provides a standard USB HID class device and as a result does not require
    drivers to run on Windows, macOS or Linux.

The full source for this application is provided along side the ``lib_xud`` software download in the
`examples/app_hid_house` directory.

.. note::

    The example code provides implementations in C and XC. This section concentrates on the XC
    version.

Required hardware
=================

This application note is designed to run on `XMOS xcore-200` or `xcore.ai` series devices.

The example code provided has been implemented and tested on the `XK-EVK-XU316` board but there
is no dependency on this board and it can be modified to run on any development board which uses
an `xcore-200` or `xcore.ai` series device.

Declarations
============

.. literalinclude:: ../../examples/app_hid_mouse/src/main.xc
   :start-at: #include
   :end-at: epTypeTableIn

``main()``
==========

The ``main()`` function creates three tasks: the XUD Io task, endpoint 0, and a task for handling
the HID endpoint.
An array of channels is used for both IN and OUT endpoints, endpoint 0 requires both, the HID
task simply implements an IN endpoint sending mouse data to the host.

.. literalinclude:: ../../examples/app_hid_mouse/src/main.xc
   :start-at: int main()
   :end-at: //

Since this example does not require `SOF` notifications ``null`` is passed into the ``c_sof``
parameter. ``XUD_SPEED_HS`` is passed for the ``desiredSpeed`` parameter such that the device
attempts to run as a high-speed device.

HID endpoint task
=================

This function responds to the HID requests - it moves the mouse cursor in square by moving 40
pixels in each direction in sequence every 100 requests using a basic state-machine. This function
could be easily changed to feed other data back (for example based on user input).

.. literalinclude:: ../../examples/app_hid_mouse/src/main.xc
   :start-at: void hid_mouse
   :end-at: //

Note, this endpoint does not receive or check for status data. It always performs IN transactions.
Since it’s behaviour is not modified based on bus speed the mouse cursor will move more slowly
when connected via a full-speed port. Ideally the device would either modify its required polling
rate in its descriptors (`bInterval` in the endpoint descriptor) or the counter value it is using
in the ``hid_mouse()`` function.

Should processing take longer that the host IN polls, the ``XUD_Main()`` task will simply `NAK` the
host. The ``XUD_SetBuffer()`` function will return when the packet transmission is complete.

Device descriptors
==================

The ``USB_StandardRequests()`` function expects descriptors to be declared as arrays of characters.
Descriptors are looked at in depth in this section.

.. note::

    ``null`` values and length 0 are passed for the full-speed descriptors, this means that the
    same descriptors will be used whether the device is running in full or high-speed.

Device descriptor
-----------------
The device descriptor contains basic information about the device. This descriptor is the first
descriptor the host reads during its enumeration process and it includes information that enables
the host to further interrogate the device. The descriptor includes information on the descriptor
itself, the device (USB version, vendor ID etc.), its configurations and any classes the device
implements. For the HID Mouse example this descriptor looks like the following:

.. literalinclude:: ../../examples/app_hid_mouse/src/hid_descs.h
   :start-at: devDesc[]
   :end-at: };

Device qualifier descriptor
---------------------------

Devices which support both full and high-speeds must implement a device qualifier descriptor. The
device qualifier descriptor defines how fields of a high speed device’s descriptor would look if
that device is run at a different speed. If a high-speed device is running currently at full/high
speed, fields of this descriptor reflect how device descriptor fields would look if speed was
changed to high/full. Please refer to section 9.6.2 of the USB 2.0 specification for further details.

For a full-speed only device this is not required.

Typically a device qualifier descriptor is derived mechanically from the device descriptor. The
``USB_StandardRequest()`` function will build a device qualifier from the device descriptors passed
to it based on the speed the device is currently running at.

Configuration descriptor
------------------------

The configuration descriptor contains the devices features and abilities. This descriptor includes
Interface and Endpoint Descriptors. Every device must have at least one configuration, in this
example there is only one configuration. The configuration descriptor is presented below:

.. literalinclude:: ../../examples/app_hid_mouse/src/hid_descs.h
   :start-at: cfgDesc[]
   :end-at: };

Other Speed Configuration descriptor
------------------------------------

An Other Speed Configuration descriptor is used for similar reasons as the Device Qualifier
descriptor. The ``USB_StandardRequests()`` function generates this descriptor from the
Configuration descriptors passed to it based on the bus speed it is currently running at.
For the HID mouse example the same Configuration descriptors are uses regardless of bus-speed
(i.e. full-speed or high-speed).

String descriptors
------------------

An array of strings supplies all the strings that are referenced from the descriptors (using fields
such as ‘iInterface’, ‘iProduct’ etc.). The string at index 0 must always contain the *Language ID
Descriptor*. This descriptor indicates the languages that the device supports for string descriptors.

The ``USB_StandardRequests()`` function deals with requests for strings using the table of strings
passed to it. It handles the conversion of the raw strings to valid USB string descriptors.

The string table for the HID mouse example is shown below:

.. literalinclude:: ../../examples/app_hid_mouse/src/hid_descs.h
   :start-at: stringDescriptors[]
   :end-at: };

Application and class specific requests
=======================================

Although the ``USB_StandardRequests()`` function deals with many of the requests the device is
required to handle in order to be properly enumerated by a host, typically a USB device will have
Class (or Application) specific requests that must be handled.

In the case of the HID mouse there are three mandatory requests that must be handled:

    * ``GET_DESCRIPTOR``

        * ``HID``: Return the HID descriptor
        * ``REPORT``: Return the HID report descriptor
        * ``GET_REPORT``: Return the HID report data

See the HID Class Specification and related documentation for full details of all HID requests.

The HID report descriptor informs the host of the contents of the HID reports that the device
sending to the host periodically. For a mouse this could include X/Y axis values, button presses
etc. A `tool <https://usb.org/document-library/hid-descriptor-tool>`_ for building these descriptors
is available for download on the `usb.org <https://www.usb.org>`_ website.

The HID report descriptor for the HID mouse example is shown below:

.. literalinclude:: ../../examples/app_hid_mouse/src/hid_descs.h
   :start-at: hidReportDescriptor[]
   :end-at: };

The request for this descriptor (and the other required requests) should be implemented before
making the call to ``USB_StandardRequests()``.
The programmer may decide not to make a call to ``USB_StandardRequests`` if the request is fully
handled. It is possible the programmer may choose to implement some functionality for a request,
then allow ``USB_StandardRequests()`` to finalise.

The complete code listing for the main endpoint 0 task is shown below:

.. literalinclude:: ../../examples/app_hid_mouse/src/endpoint0.xc
   :start-at: Endpoint0(
   :end-at: /* Endpoint0

The skeleton ``HidInterfaceClassRequests()`` function deals with any outstanding HID requests. See
the USB HID Specification for full request details:

.. literalinclude:: ../../examples/app_hid_mouse/src/endpoint0.xc
   :start-at: HidInterfaceClassRequests(
   :end-at: /* HidInterfaceClassRequests

If the HID request is not handled, the function returns ``XUD_RES_ERR``. This results in
``USB_StandardRequests()`` being called, and eventually the endpoint responding
to the host with a `STALL` to indicate an unsupported request.
