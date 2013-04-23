XMOS USB Device (XUD) Library
=============================

.. TODO 
.. Test modes
.. Describe descriptor modification based on speed
.. Differnt mouse speed FS/HS

Introduction
============

This document details the use of the XMOS USB Device (XUD) Library, which enables the development of USB 2.0 devices on the XMOS XS-1 architecture.

This document describes the structure of the library, its basic use, and
resources required. A worked example that uses the XUD library is shown:
a USB Human Interface Device (HID) Class compliant mouse The full source
code for the example can be downloaded from the XMOS website.

This document assumes familiarity with the XMOS XS-1 architecture, the
Universal Serial Bus 2.0 Specification (and related specifications),
the XMOS tool chain and XC language.

Overview
========

The XUD library allows the implementation of both full-speed and high-speed USB 2.0 devices on both XS1-L and XS1-U device families.

For the XS1-L family the implementation requires the use of an external ULPI transceiver such as the SMSC USB33XX range.  The XS1-U familiy includes an integrated USB transceiver. 
Two libraries, with identical interfaces, are provided, one of XS1-L and one for XS1-U series of processor

The library performs all the low-level I/O operations required to meet
the USB 2.0 specification. This processing goes up to and includes the
transaction level. It removes all low-level timing requirements from the
application, allowing quick prototyping of all manner of USB devices.

The XUD library runs in a single core with endpoint and application
threads communicating with it via a combination of channel communication
and shared memory variables.

There is one channel per IN or OUT endpoint. Endpoint 0 (the control
endpoint) requires two channels, one for each direction. Note, that
throughout this document the USB nomenclature is used: an OUT endpoint
is used to transfer data from the host to the device, an IN endpoint is
used when the host requests data from the device.

An example task diagram is shown  [figure:thread-diagram]. Circles
represent cores running on the XS1 with arrows depicting communication
channels between these threads. In this configuration there is one
thread that deals with endpoint 0, which has both the input and output
channel for endpoint 0. IN endpoint 1 is dealt with by a second core,
and OUT endpoint 2 and IN endpoint 5 are dealt with by a third core.
Threads must be ready to communicate with the XUD library whenever the
host demands its attention. If not, the XUD library will NAK.

Itis important to note that, for performance reasons, threads
communicate with the XUD library using both XC channels and shared
memory communication. Therefore, *all threads using the XUD library must
be on the same tile as the library itself*.

.. figure:: images/xud_overview.*

    XUD Overview

File Arrangement
================

The following list gives a brief description of the files that make up
the XUD layer:

README
    XUD README file

EULA
    End User License Agreement

LICENSING
    Licensing information

include/xud.h
    User defines and functions for the XUD library

lib/libxud_l.a
    Library for XS1-L series processors 

lib/libxud_u.a
    Library for XS1-U series processors

src/XUD_EpFunctions.xc
    Functions that control the XUD library

src/XUD_EpFuncs.S
    Assembler stubs of access functions

src/XUD_UIFM_Ports.xc
    Definition of port mapping

Resource Usage
==============

The XUD library requires the resources described in the following
sections.

Ports/Pins
----------

XS1-L Family
............

The ports used for the physical connection to the external ULPI transceiver must
be connected as shown in :ref:`table_xud_ulpi_required_pin_port`.

.. _table_xud_ulpi_required_pin_port:

.. table:: ULPI required pin/port connections
    :class: horizontal-borders vertical_borders

    +------+-------+------+-------+---------------------+
    | Pin  | Port                 | Signal              |
    |      +-------+------+-------+---------------------+
    |      | 1b    | 4b   | 8b    |                     |
    +======+=======+======+=======+=====================+
    | XD12 | P1E0  |              | ULPI_STP            |
    +------+-------+------+-------+---------------------+
    | XD13 | P1F0  |              | ULPI_NXT            |
    +------+-------+------+-------+---------------------+
    | XD14 |       | P4C0 | P8B0  | ULPI_DATA[7:0]      |
    +------+       +------+-------+                     |
    | XD15 |       | P4C1 | P8B1  |                     |
    +------+       +------+-------+                     |
    | XD16 |       | P4D0 | P8B2  |                     |
    +------+       +------+-------+                     |
    | XD17 |       | P4D1 | P8B3  |                     |
    +------+       +------+-------+                     |
    | XD18 |       | P4D2 | P8B4  |                     |
    +------+       +------+-------+                     |
    | XD19 |       | P4D3 | P8B5  |                     |
    +------+       +------+-------+                     |
    | XD20 |       | P4C2 | P8B6  |                     |
    +------+       +------+-------+                     |
    | XD21 |       | P4C3 | P8B7  |                     |
    +------+-------+------+-------+---------------------+
    | XD22 | P1G0  |              | ULPI_DIR            |
    +------+-------+------+-------+---------------------+
    | XD23 | P1H0  |              | ULPI_CLK            |
    +------+-------+------+-------+---------------------+
    | XD24 | P1I0  |              | ULPI_RST_N          |
    +------+-------+------+-------+---------------------+

In addition some ports are used internally when the XUD library is in
operation, for example pins 2-9, 26-33 and 37-43 on an L1 device should
not be used. 

Please refer the device datasheet for further information on which ports are available.

XS1-U Series Processors
.......................

The XS1-U series of processors has an integrated USB transceiver.  Some ports are used to commuicate with the USB tranceiver inside the XS1-U packages.  These ports/pins should not be used when USB functionality is enabled.  The ports/pins are shown in :ref:`table_xud_u_required_pin_port`.

.. _table_xud_u_required_pin_port:

.. table:: XS1-U required pin/port connections
    :class: horizontal-borders vertical_borders

    +------+-------+------+-------+-------+--------+
    | Pin  | Port                                  |                
    |      +-------+------+-------+-------+--------+
    |      | 1b    | 4b   | 8b    | 16b   | 32b    |                    
    +======+=======+======+=======+=======+========+
    | XD02 |       | P4A0 | P8A0  | P16A0 | P32A20 |
    +------+-------+------+-------+-------+--------+
    | XD03 |       | P4A1 | P8A1  | P16A1 | P32A21 |
    +------+-------+------+-------+-------+--------+
    | XD04 |       | P4B0 | P8A2  | P16A2 | P32A22 |
    +------+-------+------+-------+-------+--------+
    | XD05 |       | P4B1 | P8A3  | P16A3 | P32A23 |
    +------+-------+------+-------+-------+--------+
    | XD06 |       | P4B2 | P8A4  | P16A4 | P32A24 |
    +------+-------+------+-------+-------+--------+
    | XD07 |       | P4B3 | P8A5  | P16A5 | P32A25 |
    +------+-------+------+-------+-------+--------+
    | XD08 |       | P4A2 | P8A6  | P16A6 | P32A26 |
    +------+-------+------+-------+-------+--------+
    | XD09 |       | P4A3 | P8A7  | P16A7 | P32A27 |
    +------+-------+------+-------+-------+--------+
    | XD23 | P1H0  |                               |
    +------+-------+------+-------+-------+--------+
    | XD25 | P1J0  |                               | 
    +------+-------+------+-------+-------+--------+
    | XD26 |       | P4E0 | P8C0  | P16B0 |        |
    +------+-------+------+-------+-------+--------+
    | XD27 |       | P4E1 | P8C1  | P16B1 |        |
    +------+-------+------+-------+-------+--------+
    | XD28 |       | P4F0 | P8C2  | P16B2 |        |
    +------+-------+------+-------+-------+--------+
    | XD29 |       | P4F1 | P8C3  | P16B3 |        |
    +------+-------+------+-------+-------+--------+
    | XD30 |       | P4F2 | P8C4  | P16B4 |        |
    +------+-------+------+-------+-------+--------+
    | XD31 |       | P4F3 | P8C5  | P16B5 |        |
    +------+-------+------+-------+-------+--------+
    | XD32 |       | P4E2 | P8C6  | P16B6 |        |
    +------+-------+------+-------+-------+--------+
    | XD33 |       | P4E3 | P8C7  | P16B7 |        |
    +------+-------+------+-------+-------+--------+
    | XD34 | P1K0  |                               |
    +------+-------+------+-------+-------+--------+
    | XD36 | P1M0  |      | P8D0  | P16B8 |        |
    +------+-------+------+-------+-------+--------+
    | XD37 | P1N0  |      | P8C1  | P16B1 |        |
    +------+-------+------+-------+-------+--------+
    | XD38 | P1O0  |      | P8C2  | P16B2 |        |
    +------+-------+------+-------+-------+--------+
    | XD39 | P1P0  |      | P8C3  | P16B3 |        |
    +------+-------+------+-------+-------+--------+


Core Speed
------------

Due to I/O requirements the library requires a guaranteed MIPS rate to
ensure correct operation. This means that core count restrictions must
be observed. The XUD core must run at at least 80 MIPS.

This means that for an XS1 running at 400MHz there should be no more
than five threads executing at any one time that USB is being used. For
a 500MHz device no more than six threads shall execute at any one time.

This restriction is only a requirement on the tile on which the XUD core is running. 
For example, a different tile on an L16 device is unaffected by this restriction.

Clock Blocks
------------

XS1-L Family
..............

The Library uses one clock block - clock block  0 - and configures this clock block to be
clocked from the 60MHz clock from the ULPI transceiver. The ports it
uses are in turn clocked from the clock block.

Since clock block 0 is the default for all ports when enabled it is
important that if a port is not required to be clocked from this 60MHz
clock, then it is configured to use another clock block.

XS1-U Family
............

The Library uses two clock-blocks (clock blocks 4 and 5).  These are clocked from the USB clock.


Timers
------

Internally the XUD library allocates and uses four timers.

Memory
------

The library requires around 9 Kbytes of memory, of which around 6 Kbytes
is code or initialized variables that must be stored in either OTP or
Flash.

Basic Usage
===========

This section outlines the basic usage of XUD and finishes with a worked
example of a USB Human Interface Device (HID) Class compliant mouse.
Basic use is termed to mean each endpoint runs in its own dedicated core.
Multiple endpoints in a single thread is possible but currently beyond
the scope of this document.

When building, the preprocessor macro ``USB_CORE`` should be defined as
the core number to which the USB phy is attached. On single core
applications, the option ``-DUSB_CORE=0`` can be passed to the compiler.
In multi core systems, you should check which core is used for the USB
code.

XUD Core: ``XUD_Manager()``
-----------------------------

This function must be called as a core (normally from a top level
``par`` statement in ``main()``) around 100 ms after power up. This is
the main XUD task that interfaces with the ULPI transceiver. It
performs power-signalling/handshaking on the USB bus, and passes packets
on for the various endpoints.

.. doxygenfunction:: XUD_Manager

EP Communication with ``XUD_Manager()``
---------------------------------------

Communication state between a thread and the XUD library is encapsulated
in an opaque type:

.. doxygentypedef:: XUD_ep

All client calls communicating with the XUD library pass in this type.
These data structures can be created at the start of execution of a
client core with the following call that takes as an argument the
endpoint channel connected to the XUD library:

.. doxygenfunction:: XUD_Init_Ep

Endpoint data is sent/received using three main functions,
``XUD_SetData()``. ``XUD_GetData()`` and ``XUD_GetSetupData()``.

These assembly functions implement the low level shared memory/channel
communication with the ``XUD_Manager()`` thread. For developer
convenience these calls are wrapped up by XC functions. It is rare that
a developer would need to call the assembly access functions directly.

These functions will automatically deal with any low level complications required
such Packet ID toggling etc.

``XUD_GetBuffer()``
~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_GetBuffer

``XUD_SetBuffer()``
~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetBuffer


``XUD_SetBuffer_EpMax()``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This function provides a similar function to that of the previously described ``XUD_SetBuffer`` functionnubut it cuts the data up in packets of a fixed maximum size. This is especially useful for control transfers where large descriptors must be sent in typically 64 byte transactions.

See ``XUD_SetBuffer`` for a description of the first, second and third parameter.

::

    int retVal = XUD_SetBuffer_EpMax(
                     XUD_ep ep_in,
                     unsigned char buffer[], 
                     unsigned datalength,
                     unsigned epMax,

-  ``unsigned epMax`` The maximum packet size in bytes.

The function returns 0 on success (see also Status Reporting)

``XUD_DoGetRequest()``
~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_DoGetRequest

``XUD_DoSetRequestStatus()``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_DoSetRequestStatus

``XUD_SetDevAddr()``
~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetDevAddr

Status Reporting
~~~~~~~~~~~~~~~~

Status reporting on an endpoint can be enabled so that bus state is
known. This is achieved by ORing ``XUD_STATUS_ENABLE`` into the relevant
endpoint in the endpoint type table.

This means that endpoints are notified of USB bus resets (and
bus-speeds). The XUD access functions discussed previously
(``XUD_GetData``, ``XUD_SetData`` etc)return less than 0 if a USB bus reset is 
detected.

This reset notification is important if an endpoint thread is expecting
alternating INs and OUTs. For example, consider the case where a
endpoint is always expecting the sequence OUT, IN, OUT (such a control
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
~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetStall_In

``XUD_SetStall_Out()``
~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_SetStall_Out

``XUD_ClearStall_In()``
~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_ClearStall_In

``XUD_ClearStall_Out()``
~~~~~~~~~~~~~~~~~~~~

.. doxygenfunction:: XUD_ClearStall_Out

SOF Channel
-----------

An application can pass a channel-end to the ``c_sof`` parameter of ``XUD_Manager()``.  This will cause a word of data to be output everytime the device receives a SOF from the host.  This can be used for timing information for audio devices etc.  If this functionality is not required ``null`` should be passed as the parameter.  Please note, if a channel-end is passed into ``XUD_Manager()`` there must be a reposive task ready to receive SOF notifications since else the ``XUD_Manager()`` task will be blocked attempting to send these messages.

USB Test Modes
--------------

XUD supports the required tests modes for 

As per the USB 2.0 specification a power cycle or reboot is required to exit the test mode.



Standard Requests and Endpoint 0
================================

The previous sections dealt with main user functions in ``xud.h`` used to control and interract with the XUD library.  A USB device can be programmed using the above functions alone, however, to aid development some additional functions (that are essentially wrappers for the above) are provided.

Endpoint 0 must deal with enumeration and configuration requests from the host. 
Many enumeration requests are compulsory and common to all devices, most of them being requests for mandatory descriptors (Configuration, Device, String etc).  Since these requests are common across most (if not all) devices, a some useful functions are provided to deal with them. Although not
strictly part of the XUD library and supporting files, their use is so fundamental to a USB device that they are covered in this document.

Firstly, the function ``USB_GetSetupPacket()`` is provided.  This makes a call to the standard XUD function ``XUD_GetSetupBuffer()`` from the 8 byte Setup packet and parses it into a SetupPacket structure for further inspection (A SetupPacket structure is passed by reference into the ``USB_GetSetupPacket()`` call, which is populated by the function).  This struture closely matches the structure defined in the USB 2.0 Specification:


.. literalinclude:: sc_usb/module_usb_shared/src/usb.h
    :start-after: \brief   Typedef for setup
    :end-before: #endif

At this point the request is in a reasonable state to be parsed by endpoint 0.  Please see Universal Serial Bus 2.0 specification for full details of setup packet and request structure.

.. doxygenfunction:: USB_GetSetupPacket

Note, this function can return -1 to indicate a bus-reset condition.


A ``USB_StandardRequests()`` function is given to provide a bare-minimum implementaiton  of the mandatory requests required to be implented by a USB device.  It is not intended that this replace a good knowledge of the requests required, since the implentation does not guarenatee a fully USB compliance device.  Each request could well be required to be over-ridden for many device implementations.  For example, a USB Audio device could well require a specialised version of ``SET_INTERFACE`` since this could mean that audio will be streamed imminantly.

Please see Universal Serial Bus 2.0 spec for full details of these requests.

This function takes a populated ``USB_SetupPacket_t`` structure as an argument. 

.. doxygenfunction:: XUD_StandardRequests

The function inspects this SetupPacket structure and includes a minimum implentation of the Standard Device requests.  The requests handled as well as listing of the basic functinality associated with the request can be found below:

Standard Device Requests
~~~~~~~~~~~~~~~~~~~~~~~~

- ``SET_ADDRESS``

    - The device address is set in XUD (using ``XUD_SetDevAddr()``)

- ``SET_CONFIGURATION``
    
    - A global variable is updated with the given configuration value
    
- ``GET_STATUS``
    
    - The status of the device is returned. This uses the device Configuration descriptor to return if the device is bus powered or not. 

-  ``SET_CONFIGURATION``

    - A global variable is returned with the current configuration last set by ``SET_CONFIGURATION``

-  ``GET_DESCRIPTOR``

    - Returns the relevant descriptors. See ::ref:`sec_hid_ex_descriptors` for further details.  Note, some changes of returned descirptor will occur based on the current bus speed the device is running, again see ::ref:`sec_hid_ex_descriptors` for details.

        -  ``DEVICE``

        -  ``CONFIGURATION``
    
        -  ``DEVICE_QUALIFIER``

        -  ``OTHER_SPEED_CONFIGURATION``

        -  ``STRING``




In addition the following test mode requests are dealt with (with the correct test mode set in XUD):   
   
- ``SET_FEATURE``
    - ``TEST_J``
    - ``TEST_K``
    - ``TEST_SE0_NAK``
    - ``TEST_PACKET``
    - ``FORCE_ENABLE``

Standard Interface Requests
~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``SET_INTERFACE``

    - A global variable is maintained for each interfaces, this is updated by a ``SET_INTERFACE``.  Some basic range checking is included using the value ``numInterfaces`` from the ConfigurationDescriptor.  

- ``GET_INTERFACE``

    - Returns the value written by ``SET_INTERFACE``

Standard Endpoint Requests
~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``SET_FEATURE``

- ``CLEAR_FEATURE``

- ``GET_STATUS``


If parsing the Request does not result in a match, the request is not handled, the Endpoint is marked "Halted" (Using ``SetStall_Out()`` and ``SetStall_In()``) and the function returns 1.  The function returns 0 if a request was handled without error (See also
Status Reporting).

Minimal Endpoint 0 Implementation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Typically the minimal code for endpoint 0 makes a call to call ``USB_GetSetupPacket()``, parses the SetupPacket for any class/applicaton specific requests. Then makes a call to ``USB_StandardRequests()`` eg:   

::

    USB_GetSetupPacker(ep0_out, ep0_in, sp);

    switch(sp.bmRequestType.Type) 
    {
        case BM_REQTYPE_TYPE_CLASS:

            switch(sp.bmRequestType.Receipient)
            {
                case BM_REQTYPE_RECIP_INTER:
         
                    // Optional class specific requests.
                    break;

                ...
            }

            break;

        ...

    }

    USB_StandardRequests(ep0_out, ep0_in, devDesc, devDescLen, ..., );

Note, the example code above ignores any bus reset.

The code above could also over-ride any of the requests handled in ``USB_StandardRequests()`` for custom functionality.

Note, custom class code should be inserted before ``USB_StandardRequests()`` is called since if ``USB_StandardRequests()`` cannot handle a request it marks the Endpoint stalled to indicate to the host that the Request is not supported byt the device.


Basic Example HS Device: USB HID device
=======================================

This section contains a full worked example of a HID device. Note, this
is provided as a simple example, not a full HID Mouse reference design.

The example code in this document is intended for XS1-U8 family processors.  The code would be very similar for an XS1-L processor (with external ULPI transceiver), with only the declarations and call to ``XUD_Manager()`` being different.

Declarations
------------

::

    #include <xs1.h>

    #include "xud.h"
    #include "usb.h"

    #define XUD_EP_COUNT_OUT  1
    #define XUD_EP_COUNT_IN   2

    /* Endpoint type tables */
    XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
    XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL};

Main program
------------

The main function creates three tasks: the XUD manager, endpoint
0, and HID. An array of channels is used for both in and out endpoints,
endpoint 0 requires both, HID is just an IN endpoint for the mouse data to the host.

::

    int main() 
    {
        chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];
        par {
            XUD_Manager(c_ep_out, EP_COUNT_OUT,
                        c_ep_in, EP_COUNT_IN,
                        null, epTypeTableOut, epTypeTableIn,
                        null, null, null, XUD_SPEED_HS, null);  
            Endpoint0( c_ep_out[0], c_ep_in[0]);
            hid_mouse(c_ep_in[1]);
        }
        return 0;
    }

Since we do not require SOF notifications ``null`` is passed into the ``c_sof`` parameter.  ``XUD_SPEED_HS`` is passed for the ``desiredSpeed`` parameter as we wish to run as a high-speed device.

HID response function
---------------------

This function responds to the HID requests—it draws a square using the
mouse moving 40 pixels in each direction in sequence every 100 requests.
Change this function to feed other data back (for example based on user
input). It demonstrates the use of ``XUD_SetBuffer``.

::

    void hid(chanend c_ep1) {
        char buffer[] = {0, 0, 0, 0};
        int counter = 0;
        int state = 0;
       
        XUD_ep ep = XUD_Init_Ep(c_ep1);
        
        counter = 0;
        while(1) {
            counter++;
            if(counter == 400) {
                if(state == 0) {
                    buffer[1] = 40;
                    buffer[2] = 0; 
                    state+=1;
                } else if(state == 1) {
                    buffer[1] = 0;
                    buffer[2] = 40;
                    state+=1;
                } else if(state == 2) {
                    buffer[1] = -40;
                    buffer[2] = 0; 
                    state+=1;
                } else if(state == 3) {
                    buffer[1] = 0;
                    buffer[2] = -40;
                    state = 0;
                }
                counter = 0;
            } else {
                buffer[1] = 0;
                buffer[2] = 0; 
            }

            XUD_SetBuffer(c_ep, buffer, 4) < 0;
        }
    }

Note, this endpoint does not receive or check for status data. It always
performs IN transactions and its behavior would not change dependant on
bus speed, so this is safe.

Should processing take longer that the host IN polls, the ``XUD_Manager``
thread will simply NAK the host.  The ``XUD_SetBuffer()`` function will return when the packet 
transmission is complete.

Standard Descriptors
--------------------
.. _sec_hid_ex_descriptors:

The ``USB_StandardRequests()`` function expects descriptors be declared as arrays of characters.  Descriptors are look at in depth in this section.

Device Descriptor
~~~~~~~~~~~~~~~~~
The device descriptor contains basic information about the device.  This desciptor is the first descriptor the host reads during its eumumeration process and it includes information that enables the host to interogate further the device.\The descriptor includes information on the desciptor itself, the device (USB version, vendor ID etc), its configurations and any classes the device implements.

For the HID Mouse example this descriptor looks like the following:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* Device Descriptor 
    :end-before: };

Device Qualifier Descriptor
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Devices which support both full and high-speeds must implement a device qualifier descriptor.
The device qualifier descriptor defines how fields of a high speed device’s device descriptor would look if that device is run at a different speed. If a high-speed device is running currently at full/high speed, fields of this descriptor reflect how device descriptor fields would look if speed was changed to high/full. Please refer to section 9.6.2 of the USB 2.0 specification for further details.

For a full-speed only device this is not required.

Typically a device qualifier descriptor is derived mechanically from the device descriptor.  The ``XUD_StandardRequest`` function will build a device qualifier from the device desriptors passed to it based on the speed the device is currently running at.

Configuration Descriptor
~~~~~~~~~~~~~~~~~~~~~~~

The configuration descriptor contains the devices features and abilities.  This descirptor includes Interface and Endpoint Descriptors. Every device must have atleast one configuration, in our example there is only one configuration.  The configuration descriptor is presented below:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* Configuration Descriptor 
    :end-before: };

Other Speed Configuration Descriptor
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A other speed configuration for similar reasons as the device qualifier
descriptor.  The ``USB_StandardRequests()`` function generates this descriptor from the Configuration Descriptors passed to it based on the bus speed it is currentl running at.  For the HID mouse example we used the same configuration Descriptors if running on full-speed or high-speed.

String Descriptors 
~~~~~~~~~~~~~~~~~~
An array of strings supplies all the strings that are referenced from
the descriptors (using fields such as ‘iInterace’, ‘iProduct’ etc).
String 0 is the language descriptor, and is interpreted as “no string
supplied” when used as an index value.  The ``USB_StandardRequests()`` function deals with requests for strings using the table of strings passed to it.  The string table for the HID mouse example is shown below:



.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* String table 
    :end-before: };

Application and Class Specific Requests 
---------------------------------------

Although the ``USB_StandardRequests()`` function deals with many of the requests the device is required to handle in order to be properly enumerated by a host, typically an USB device will have Class (or Application) specific requests that must be handled.

In the case of the HID mouse there are three mandatory Requests that must be handled:

    - ``GET_DESCRIPTOR``

        - ``HID``    Return the HID descriptor

        - ``REPORT`` Return the HID report descriptor

    - ``GET_REPORT`` Return the HID report data

Please refer to the HID Specification and related documentation for full details of all HID requests.

The HID report descriptor informs the hosts of the contents of the HID reports that it will be sending to the host periodically.For a mouse this could include X/Y axis values, button presses etc.  Tools for building these descriptors are available for download on the usb.org website.

The HID report descriptor for the HID mouse example is shown below:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* HID Report Descriptor
    :end-before: };

The request for this descriptor (and the other required requests) should be implemented before making the a call to ``USB_StandardRequests()``.  The programmer may decide not to make a call to ``USB_StandardRequests`` if the request is fully handled.  It is possible the pogrammer may choose to implement some functionality for a request, then allow ``USB_StandardRequests()`` to finalise.

The complete code listing for the main endpoint 0 task is show below:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* Endpoint 0 Task
    :end-before: }// 


The skeleton HidInterfaceClassRequests() function deals with any
outstanding HID requests. See the USB HID Specification for full request
details:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* HID Class Requests
    :end-before: /* Endpoint 0 Task

If the HID request is not handles, the function returns 1.  This results in ``USB_StandardRequests()`` being called, and eventually the endpoint being STALLed to indicate an unknown request.


XUD API
=======

XUD user functions and types are documented here.

.. doxygenenum:: XUD_EpType

.. doxygenfunction:: XUD_GetData
.. doxygenfunction:: XUD_GetSetupData
.. doxygenfunction:: XUD_SetData

.. doxygenfunction:: XUD_Manager


.. doxygenfunction:: XUD_GetBuffer
.. doxygenfunction:: XUD_GetSetupBuffer
.. doxygenfunction:: XUD_SetBuffer
.. doxygenfunction:: XUD_SetBuffer_EpMan


.. doxygenfunction:: XUD_DoGetRequest
.. doxygenfunction:: XUD_DoSetRequestStatus

.. doxygenfunction:: XUD_SetDevAddr

.. doxygenfunction:: XUD_InitEp
.. doxygenfunction:: XUD_ResetEndpoint

.. doxygenfunction:: XUD_SetStall_Out
.. doxygenfunction:: XUD_SetStall_In
.. doxygenfunction:: XUD_ClearStall_Out
.. doxygenfunction:: XUD_ClearStall_In



Document Version History
========================

.. _table_xud_release_history:

.. table:: Version History
    :class: horizontal-borders vertical_borders

    +------------+---------+----------------------------------------------------------+
    | Date       | Version | Comment                                                  |
    +============+=========+==========================================================+
    | 2013-04-23 | 1.1     | API updates and changes to Standard Request handling     |
    +------------+---------+----------------------------------------------------------+
    | 2011-01-06 | 1.0     | Updates for API changes                                  |
    +------------+---------+----------------------------------------------------------+
    | 2010-07-22 | 1.0b    | Beta Release                                             |
    +------------+---------+----------------------------------------------------------+
