Basic Usage
===========

This section outlines the basic usage of XUD and finishes with a worked
example of a USB Human Interface Device (HID) Class compliant mouse.
Basic use is termed to mean each endpoint runs in its own dedicated core.
Multiple endpoints in a single core are possible but currently beyond
the scope of this document.

XUD Core: ``XUD_Manager()``
-----------------------------

This function must be called as a core (normally from a top level
``par`` statement in ``main()``) around 100 ms after power up. This is
the main XUD task that interfaces with the ULPI transceiver. It
performs power-signalling/handshaking on the USB bus, and passes packets
on for the various endpoints.

.. doxygenfunction:: XUD_Manager

Endpoint Type Table 
~~~~~~~~~~~~~~~~~~~

The endpoint type table should take an array of ``XUD_EpType`` to inform XUD about endpoints being used.  This is mainly used to indicate the transfer-type of each endpoint (bulk, control, isochronous or interrupt) as well as whether the endpoint wishs to be informed about bus-resets (see :ref:`xud_status_reporting`).

Note, endpoints can also be marked as disabled.

Endpoints that are not used will NAK any traffic from the host.




EP Communication with ``XUD_Manager()``
---------------------------------------

Communication state between a core and the XUD library is encapsulated
in an opaque type:

.. doxygentypedef:: XUD_ep

All client calls communicating with the XUD library pass in this type.
These data structures can be created at the start of execution of a
client core with the following call that takes as an argument the
endpoint channel connected to the XUD library:

.. doxygenfunction:: XUD_InitEp

Endpoint data is sent/received using three main functions,
``XUD_SetData()``, ``XUD_GetData()`` and ``XUD_GetSetupData()``.

These assembly functions implement the low level shared memory/channel
communication with the ``XUD_Manager()`` core. For developer convenience
these calls are wrapped up by XC functions.

These functions will automatically deal with any low level complications required
such as Packet ID toggling etc.

``XUD_GetBuffer()``
~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_GetBuffer

``XUD_SetBuffer()``
~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetBuffer


``XUD_SetBuffer_EpMax()``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This function provides a similar function to that of the previously described
``XUD_SetBuffer`` function but it cuts the data up in packets of a fixed
maximum size. This is especially useful for control transfers where large 
descriptors must be sent in typically 64 byte transactions.

See ``XUD_SetBuffer`` for a description of the first, second and third parameter.

.. doxygenfunction:: XUD_SetBuffer_EpMax

``XUD_DoGetRequest()``
~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_DoGetRequest

``XUD_DoSetRequestStatus()``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_DoSetRequestStatus

``XUD_SetDevAddr()``
~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetDevAddr

.. _xud_status_reporting:

Status Reporting
~~~~~~~~~~~~~~~~

Status reporting on an endpoint can be enabled so that bus state is
known. This is achieved by ORing ``XUD_STATUS_ENABLE`` into the relevant
endpoint in the endpoint type table.

This means that endpoints are notified of USB bus resets (and
bus-speeds). The XUD access functions discussed previously
(``XUD_GetData``, ``XUD_SetData``, etc.) return less than 0 if
a USB bus reset is detected.

This reset notification is important if an endpoint core is expecting
alternating INs and OUTs. For example, consider the case where an
endpoint is always expecting the sequence OUT, IN, OUT (such as a control
transfer). If an unplug/reset event was received after the first OUT,
the host would return to sending the initial OUT after a replug, while
the endpoint would hang on the IN. The endpoint needs to know of the bus
reset in order to reset its state machine.

*Endpoint 0 therefore requires this functionality since it deals with
bi-directional control transfers.*

This is also important for high-speed devices, since it is not
guaranteed that the host will detect the device as a high-speed device.
The device therefore needs to know what speed it is running at.

After a reset notification has been received, the endpoint must call the
``XUD_ResetEndpoint()`` function. This will return the current bus
speed.

``XUD_ResetEndpoint()``
~~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_ResetEndpoint


``XUD_SetStall_In()``
~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetStall_In

``XUD_SetStall_Out()``
~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetStall_Out

``XUD_ClearStall_In()``
~~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_ClearStall_In

``XUD_ClearStall_Out()``
~~~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_ClearStall_Out

SOF Channel
-----------

An application can pass a channel-end to the ``c_sof`` parameter of 
``XUD_Manager()``.  This will cause a word of data to be output every time
the device receives a SOF from the host.  This can be used for timing
information for audio devices etc.  If this functionality is not required
``null`` should be passed as the parameter.  Please note, if a channel-end
is passed into ``XUD_Manager()`` there must be a responsive task ready to
receive SOF notifications since else the ``XUD_Manager()`` task will be
blocked attempting to send these messages.

.. _xud_usb_test_modes:

USB Test Modes
--------------

XUD supports the required test modes for USB Compliance testing. The
``XUD_Manager()`` task can take a channel-end argument for controlling the
test mode required.  ``null`` can be passed if this functionality is not required.  

XUD accepts a single word for from this channel to signal which test mode
to enter, these commands are based on the definitions of the Test Mode Selector
Codes in the USB 2.0 Specification Table 11-24.  The supported test modes are
summarised in the :ref:`table_test_modes`.

.. _table_test_modes:

.. table:: Supported Test Mode Selector Codes
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
    | 5      | Test_Force_Enable                   |
    +--------+-------------------------------------+

The use of other codes results in undefined behaviour.

As per the USB 2.0 specification a power cycle or reboot is required to exit the test mode.

