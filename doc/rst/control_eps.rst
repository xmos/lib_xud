
|newpage|

.. _sec_control_eps:

*****************
Control Endpoints
*****************

``lib_xud`` provides helper functions that provide a set of standard functionality to aid the
creation of USB devices.

Control transfers are typically used for command and status operations. They are essential to set
up a USB device with all enumeration functions being performed using Control transfers. Control
transfers are characterised by the use of a `SETUP` transaction.

USB devices must provide an implementation of a control endpoint at endpoint 0.
Endpoint 0 must deal with enumeration and configuration requests from the host. Many enumeration
requests are compulsory and common to all devices, with most of them being requests for mandatory
descriptors (Configuration, Device, String, etc).

Since these requests are common across most (if not all) devices, some useful functions are
provided to deal with them.

Helper Functions
================

Firstly, the function ``USB_GetSetupPacket()`` is provided. This makes a call to the low-level
`XUD` function ``XUD_GetSetupBuffer()`` with the 8 byte `Setup` packet which it parses into a
``USB_SetupPacket_t`` structure for further inspection. The ``USB_SetupPacket_t`` structure passed
by reference to ``USB_GetSetupPacket()`` is populated by the function.

At this point the request is in a good state to be parsed by endpoint 0. Please see Universal
Serial Bus 2.0 specification for full details of Setup packet and request structure.

A ``USB_StandardRequests()`` function provides a bare-minimum implementation of the mandatory
requests required to be implemented by a USB device.
The function inspects this ``USB_SetupPacket_t`` structure and includes a minimum implementation
of the Standard Device requests. The rest of this section documents the requests handled and lists
the basic functionality associated with the request.

It is not intended that this replace a good knowledge of the requests required, since
``USB_StandardRequests()`` has no knowledge about the specific class that is implemented, and hence
does not guarantee a fully USB compliant device.

Each request could well be required to be over-ridden for a device implementation. For example,a
USB Audio device could well require a specialised version of `SET_INTERFACE` since this could mean
that audio streaming will commence imminently.

The ``USB_StandardRequests()`` function takes as parameters arrays representing the device
descriptor, configuration descriptor, and a string table as well as a ``USB_SetupPacket_t`` and
the current bus-speed.

.. note::

   ``USB_StandardRequests()`` takes two references for device and configuration descriptors - this
   allows for different functionality based on bus-speed. ``USB_StandardRequests()`` forms valid
   `Device Qualifier` and `Other Speed Configuration` descriptors from these arrays.

``USB_SetupPacket_t``
---------------------

This structure closely matches the structure defined in the USB 2.0 Specification:

.. literalinclude:: ../../lib_xud/api/xud_std_requests.h
   :start-at: typedef struct USB_SetupPacket
   :end-at: } USB_SetupPacket_t

``USB_GetSetupPacket()``
------------------------

.. doxygenfunction:: USB_GetSetupPacket

``USB_StandardRequests()``
--------------------------

This function takes a populated ``USB_SetupPacket_t`` structure as an argument.

.. doxygenfunction:: USB_StandardRequests

This section now details the actual requests handled by this function.
If parsing the request does not result in a match, the request is not handled, the Endpoint is
marked “Halted” (Using ``XUD_SetStall_Out()`` and ``XUD_SetStall_In()``) and the function returns
``XUD_RES_ERR``. The function returns ``XUD_RES_OKAY`` if a request was handled without error
(See also :ref:`sec_status_reporting`).


``USB_StandardRequests()``: Standard Device Requests
----------------------------------------------------

The ``USB_StandardRequests()`` function  handles the following `Standard Device Requests`:

* ``SET_ADDRESS``: The device address is set in XUD (using ``XUD_SetDevAddr()``).

* ``SET_CONFIGURATION``: A global variable is updated with the given configuration value.

* ``GET_STATUS``:  The status of the device is returned. This uses the device Configuration descriptor to return if the device is bus powered or not.

* ``SET_CONFIGURATION``: A global variable is returned with the current configuration last set by ``SET_CONFIGURATION``.

* ``GET_DESCRIPTOR``: Returns the relevant descriptors. Note, some changes of returned descriptor will occur based on the current bus speed the device is running.

  * ``DEVICE``
  * ``CONFIGURATION``
  * ``DEVICE_QUALIFIER``
  * ``OTHER_SPEED_CONFIGURATION``
  * ``STRING``

In addition the following test mode requests are dealt with (with the correct test mode set in XUD):

* ``SET_FEATURE``

  * ``TEST_J``
  * ``TEST_K``
  * ``TEST_SE0_NAK``
  * ``TEST_PACKET``
  * ``FORCE_ENABLE``

``USB_StandardRequests()``: Standard Interface Requests
-------------------------------------------------------

The ``USB_StandardRequests()`` function  handles the following Standard Interface Requests:

* ``SET_INTERFACE`` : A global variable is maintained for each interface. This is updated by a SET_INTERFACE. Some basic range checking is included using the value `numInterfaces` from the Configuration Descriptor.
* ``GET_INTERFACE``: Returns the value written by ``SET_INTERFACE``.

``USB_StandardRequests()``: Standard Endpoint Requests
--------------------------------------------------------

The ``USB_StandardRequests()`` function handles the following Standard Endpoint Requests:

* ``SET_FEATURE``
* ``CLEAR_FEATURE``
* ``GET_STATUS``

.. _sec_msos_support:

MSOS 2.0 Support
================

``lib_xud`` provides support for the Microsoft OS 2.0 Descriptors (MSOS 2.0) specification. This allows for
automatic driver installation on Windows hosts for devices that support this feature.

.. note:: 
   
   MSOS 2.0 descriptors are only supported in C code, not XC. This is due to structure packing requirements.
   The following functions are available if the application Endpoint0 function is written in C.
   However, XC applications can still make use of MSOS 2.0 descriptors by implementing
   a simple wrapper. See :c:func:`XUD_Init_Ep0_Msos_Descriptors` for more details.

A detailed explanation of MSOS 2.0 descriptors is beyond the scope of this documentation.
Please see the official Microsoft documentation for more details. Also, see the application note 
`AN00136 Example USB Vendor Specific Device <https://www.xmos.com/file/an00136>`_ and the examples 
in ``lib_xua`` for use of this feature.

The MSOS 2.0 descriptors are retrieved via requests over Endpoint0, and need some simple preparation before enumeration.

.. doxygenfunction:: XUD_Update_Guid_In_Msos_Desc

.. doxygenfunction:: XUD_GetBosDescriptor

.. doxygenfunction:: XUD_GetMsosDescriptor

MSOS 2.0 Configuration
----------------------

There are defines provided to aid the construction and access to the MSOS 2.0 descriptors.

See :c:macro:`XUD_WINUSB_DEVICE_INTERFACE_GUID_CONTROL` and :c:macro:`XUD_REQUEST_GET_MSOS_DESCRIPTOR` for more details.

MSOS 2.0 Example Wrapper
------------------------

A simple example wrapper function is provided to aid XC applications in implementing MSOS 2.0 support.

.. doxygenfunction:: XUD_Init_Ep0_Msos_Descriptors

Control Endpoint Example
========================

The code listing below shows a simple example of a endpoint 0 implementation showing the use of
``USB_SetupPacket_t``, ``USB_SetSetupPacket()`` and ``USBStandardRequests()``:

.. literalinclude:: control_ep_example_xc

.. note::

    For conciseness the declarations of the arrays representing the device and configuration
    descriptors and the string table are not shown.
