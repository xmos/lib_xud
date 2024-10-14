|newpage|

.. _sec_basic_usage:

***********
Basic usage
***********

Basic use is termed to mean each endpoint runs in its own dedicated thread.
Multiple endpoints in a single thread are possible, please see :ref:`sec_advanced_usage`.

Operation is synchronous in nature: The endpoint tasks make calls to blocking functions and waits
for the transfer to complete before proceeding.

XUD IO task
===========

``XUD_Main()`` is the main task that interfaces with the USB transceiver.
It performs connection and handshaking on the USB bus as well as other bus-states such
as suspend and resume. It also handles passing packets to/from the various endpoints.

This function should be called directly from the top-level ``par`` statement in ``main()`` to
ensure that the XUD library is ready within the 100ms allowed by the USB specification (assuming a
bus-powered device).

.. doxygenfunction:: XUD_Main

Endpoint type tables
--------------------

The endpoint type tables are arrays of type ``XUD_EpType`` and are used to inform ``lib_xud``
about the endpoints in use.  This information is used to indicate the transfer-type of each endpoint
(bulk, control, isochronous or interrupt) as well as whether the endpoint wishes to be informed
about bus-resets (see `Status Reporting`_). Two tables are required, one for IN and one for OUT
endpoints.

Suitable values are provided in the ``XUD_EpTransferType`` `enum`:

    * ``XUD_EPTYPE_ISO``: Isochronous endpoint
    * ``XUD_EPTYPE_INT``: Interrupt endpoint
    * ``XUD_EPTYPE_BUL``: Bulk endpoint
    * ``XUD_EPTYPE_CTL``: Control endpoint
    * ``XUD_EPTYPE_DIS``: Disabled endpoint

OUT endpoint N will use index N of the output-endpoint-table, IN endpoint 0x8N will use index N
of the inpout-endpoint-table. Endpoint 0 must exist in both tables.

..note::

    Endpoints that are not used will ``NAK`` any traffic from the host.

``PwrConfig``
-------------

The ``PwrConfig`` parameter to ``XUD_Main()`` indicates if the device is bus or self-powered.

Valid values for this parameter are ``XUD_PWR_SELF`` and ``XUD_PWR_BUS``.

When ``XUD_PWR_SELF`` is used, ``XUD_Main()`` monitors the `VBUS` input for a valid voltage and
responds appropriately. The USB Specification states that the devices pull-ups must be disabled
when a valid `VBUS` is not present. This is important when submitting a device for compliance
testing since this is explicitly tested.

If the device is bus-powered ``XUD_PWR_BUS`` can be used since it is assumed that the device is not
powered up when `VBUS` is not present and therefore no voltage monitoring is required.  In this
configuration the `VBUS` input to the device/PHY need not be present.

``XUD_PWR_BUS`` can be used in order to run on a self-powered board without provision for `VBUS`
wiring to the PHY/device, but this is not advised and is not USB specification compliant.

VBUS monitoring
===============

For self-powered devices it is important that ``lib_xud`` is aware of the `VBUS` state.
This allows the device to disconnect its pull-up resistors from D+/D- and ensure the device does not
have any voltage on the D+/D- pins when `VBUS` is not present. Compliance testing specifically
checks for this in the `USB Back Voltage` test.

.. warning::

    Failure to conform to this requirement will lead to an uncompliant device and likely lead to
    interoperability issues.

USB-enabled `xcore-200` series devices have a dedicated `VBUS` pin which should be wired up as
per the data-sheet recommendations including over-voltage protection.

For increasing flexibility, `xcore.ai` series devices do not have a dedicated `VBUS` pin.
A generic IO port/pin should be used for this purpose (with appropriate external circuitry - see
data-sheet recommendations).

``lib_xud`` makes a call to a function ``XUD_HAL_GetVBusState()`` that which should be implemented
to match the target hardware. For example::

    on tile[XUD_TILE]: in port p_vbus = XS1_PORT_1P;

    unsigned int XUD_HAL_GetVBusState(void)
    {
        unsigned vBus;
        p_vbus :> vBus;
        return vBus;
    }

The function should return 1 if `VBUS` is present, otherwise 0. In the case of the example
above, the validity of `VBUS` is directly represented by the value on port 1P, however, this
may not be the case for all hardware implementations, it could be inverted or even require a read
from an external IO expander, for example.

.. note::

   `VBUS` need not be connected if the device is wholly powered by USB i.e. a bus powered device.

Data transfer
=============

Communication state between an endpoint client task and the XUD IO task is encapsulated in an
opaque type:

.. doxygentypedef:: XUD_ep

All client calls communicating with the XUD library pass in this type.
These data structures can be created at the start of execution of a client task with the following
call that takes as an argument the endpoint channel connected to the XUD library:

.. doxygenfunction:: XUD_InitEp

Endpoint data is sent/received using three main functions, ``XUD_SetBuffer()``, ``XUD_GetBuffer()``
and ``XUD_GetSetupBuffer()``.

These functions implement the low-level shared memory/channel communication with the ``XUD_Main()``
task.

These functions will automatically deal with any low-level complications required such as Packet ID
(PID) toggling etc.

``XUD_SetBuffer()``
-------------------

.. doxygenfunction:: XUD_SetBuffer

``XUD_GetBuffer()``
-------------------

.. doxygenfunction:: XUD_GetBuffer

``XUD_GetSetupBuffer()``
------------------------

.. doxygenfunction:: XUD_GetSetupBuffer

For user convenience these functions are wrapped up in functions that match commonly required
packet sequences:

``XUD_SetBuffer_EpMax()``
-------------------------

This function provides a similar function to ``XUD_SetBuffer`` function but it breaks the data up
in packets of a fixed maximum size. This is especially useful for control transfers where large
descriptors must be sent in typically 64 byte transactions.

.. doxygenfunction:: XUD_SetBuffer_EpMax

``XUD_DoGetRequest()``
----------------------

.. doxygenfunction:: XUD_DoGetRequest

``XUD_DoSetRequestStatus()``
----------------------------

.. doxygenfunction:: XUD_DoSetRequestStatus

Data transfer example
=====================

A simple endpoint task is shown below demonstrating basic data transfer to the host.

.. literalinclude:: basic_usage_data_example_xc


Status reporting
================

An endpoint can register for "status reporting" such that bus state can be known. This is achieved
by ORing ``XUD_STATUS_ENABLE`` into the relevant endpoint in the endpoint type table.

This means that endpoints are notified of USB bus resets (and therefore bus-speed changes). The
``lib_xud`` access functions discussed previously (``XUD_GetBuffer``, ``XUD_SetBuffer``, etc) return
``XUD_RES_RST`` if a USB bus reset is detected.

This reset notification is important if an endpoint task is expecting alternating IN and OUT
transactions. For example, consider the case where an endpoint is always expecting the sequence
OUT, IN, OUT (such as a control transfer or a request response protocol).
If an unplug/reset event was received after the first OUT, the host would return to sending the
initial OUT after a re-plug, whilst the endpoint task would hang trying to send a response the IN.
The endpoint needs to know of the bus reset in order to reset its state machine.

.. note::
   Endpoint 0 *requires* this functionality to be enabled  since it deals with bi-directional
   control transfers

This functionality is also important for high-speed devices, since it is not guaranteed that a host
will enumerate the device as a high-speed device, say if it's plugged via full-speed hub.

The device typically needs to know what bus-speed it is currently running at.

After a reset notification has been received, the endpoint must call the ``XUD_ResetEndpoint()``
function. This will return the current bus speed as a ``XUD_BusSpeed_t`` with the value
``XUD_SPEED_FS`` ;or ``XUD_SPEED_HS``.

``XUD_ResetEndpoint()``
-----------------------

.. doxygenfunction:: XUD_ResetEndpoint

.. _sec_status_reporting:

Status reporting example
========================

A simple endpoint task is shown below demonstrating basic data transfer to the host and bus status
inspection.

.. literalinclude:: basic_usage_status_example_xc

SOF channel
===========

An application can pass an optional channel-end to the ``c_sof`` parameter of ``XUD_Main()``.
This will cause a word of data to be output every time
the device receives a SOF (`Start Of Frame`) packet from the host.  This can be used for timing
information in audio devices etc.

If this functionality is not required ``null`` should be passed as the parameter.

.. note::
   If an optional channel-end is passed into ``XUD_Main()`` there must be a responsive task ready
   to receive SOF notifications otherwise the ``XUD_Main()`` task will be blocked attempting to
   send these messages leading to it being unresponsive to the host.

Halting
========

The USB specification requires the ability for an endpoint to send a `STALL` response to the host if
an endpoint is halted, or if control pipe request is not supported. ``lib_xud`` provides
various functions to support this.  In some cases it is convenient to use the ``XUD_ep`` whilst in
other cases it is easier to use the endpoint address. Functions to use either are provided.

``XUD_SetStall()``
------------------

.. doxygenfunction:: XUD_SetStall

``XUD_SetStallByAddr()``
------------------------

.. doxygenfunction:: XUD_SetStallByAddr

``XUD_ClearStall()``
--------------------

.. doxygenfunction:: XUD_ClearStall

``XUD_ClearStallByAddr()``
--------------------------

.. doxygenfunction:: XUD_ClearStallByAddr

.. _sec_test_modes:

USB test modes
==============

``lib_xud`` supports the required test modes for USB Compliance testing.

``lib_xud``  accepts commands from the endpoint 0 channels (in or out) to signal which test mode
to enter via the ``XUD_SetTestMode()`` function. The commands are based on the definitions
of the `Test Mode Selector Codes` in the USB 2.0 Specification Table 11-24.  The supported test
modes are summarised in :numref:`table_test_modes`.

.. _table_test_modes:

.. table:: Supported `Test Mode Selector Codes`
    :class: horizontal-borders vertical_borders

    +--------+-------------------------------------+
    | Value  | Test Mode Description               |
    +========+=====================================+
    | 1      | Test_J                              |
    +--------+-------------------------------------+
    | 2      | Test_K                              |
    +--------+-------------------------------------+
    | 3      | Test_SE0_NAK                        |
    +--------+-------------------------------------+
    | 4      | Test_Packet                         |
    +--------+-------------------------------------+

The passing other codes endpoints other than 0 to ``XUD_SetTestMode()`` could result in undefined
behaviour.

As per the USB 2.0 Specification a power cycle or reboot is required to exit the selected test mode.

``XUD_SetTestMode()``
---------------------

.. doxygenfunction:: XUD_SetTestMode
