Basic Example HS Device: USB HID device
=======================================

This section contains a full worked example of a HID device. Note, this
is provided as a simple example, not a full HID Mouse reference design.

The example code in this document is intended for XS1-U8 family processors.
The code would be very similar for an XS1-L processor (with external ULPI
transceiver), with only the declarations and call to ``XUD_Manager()`` being
different.

Declarations
------------

::

    #include <xs1.h>

    #include "xud.h"
    #include "usb.h"

    #define XUD_EP_COUNT_OUT  1
    #define XUD_EP_COUNT_IN   2

    /* Endpoint type tables */
    XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {
        XUD_EPTYPE_CTL | XUD_STATUS_ENABLE
    };
    XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] = {
        XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_BUL
    };

Main program
------------

The main function creates three tasks: the XUD manager, endpoint
0, and HID. An array of channels is used for both in and out endpoints,
endpoint 0 requires both, HID is just an IN endpoint for the mouse data to the host.

::

    int main() 
    {
        chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
        par {
            XUD_Manager(c_ep_out, XUD_EP_COUNT_OUT,
                        c_ep_in, XUD_EP_COUNT_IN,
                        null, epTypeTableOut, epTypeTableIn,
                        null, null, null, XUD_SPEED_HS, null);  
            Endpoint0(c_ep_out[0], c_ep_in[0]);
            hid_mouse(c_ep_in[1]);
        }
        return 0;
    }

Since we do not require SOF notifications ``null`` is passed into the ``c_sof``
parameter.  ``XUD_SPEED_HS`` is passed for the ``desiredSpeed`` parameter as we
wish to run as a high-speed device.  Test mode support is not important for this
example to ``null`` is also passed to the ``c_usb_testmode`` parameter.

HID response function
---------------------

This function responds to the HID requests—it draws a square using the
mouse moving 40 pixels in each direction in sequence every 100 requests.
Change this function to feed other data back (for example based on user
input). It demonstrates the use of ``XUD_SetBuffer``.

::

    void hid_mouse(chanend c_ep1) {
        char buffer[] = {0, 0, 0, 0};
        int counter = 0;
        int state = 0;
       
        XUD_ep ep = XUD_Init_Ep(c_ep1);
        
        counter = 0;
        while(1) {
            counter++;
            if(counter == 100) {
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
performs IN transactions.  Since it's behaviour is not modified based on
bus speed the mouse cursor will move more slowly when connected via a
full-speed port.  Ideally the device would either modify its required
polling rate in its descriptors (`'bInterval`` in the endpoint descriptor)
or the counter value it is using in the ``hid_mouse()`` function. 

Should processing take longer that the host IN polls, the ``XUD_Manager``
core will simply NAK the host.  The ``XUD_SetBuffer()`` function will
return when the packet transmission is complete.

.. _sec_hid_ex_descriptors:

Standard Descriptors
--------------------

The ``USB_StandardRequests()`` function expects descriptors be declared as
arrays of characters.  Descriptors are looked at in depth in this section.

Device Descriptor
~~~~~~~~~~~~~~~~~
The device descriptor contains basic information about the device. This
descriptor is the first descriptor the host reads during its enumeration
process and it includes information that enables the host to further
interrogate the device. The descriptor includes information on the descriptor
itself, the device (USB version, vendor ID etc.), its configurations and
any classes the device implements.

For the HID Mouse example this descriptor looks like the following:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* Device Descriptor 
    :end-before: };

Device Qualifier Descriptor
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Devices which support both full and high-speeds must implement a device
qualifier descriptor. The device qualifier descriptor defines how fields
of a high speed device’s descriptor would look if that device is
run at a different speed. If a high-speed device is running currently at
full/high speed, fields of this descriptor reflect how device descriptor
fields would look if speed was changed to high/full. Please refer to
section 9.6.2 of the USB 2.0 specification for further details.

For a full-speed only device this is not required.

Typically a device qualifier descriptor is derived mechanically from the
device descriptor.  The ``USB_StandardRequest`` function will build a
device qualifier from the device descriptors passed to it based on the
speed the device is currently running at.

Configuration Descriptor
~~~~~~~~~~~~~~~~~~~~~~~~

The configuration descriptor contains the devices features and abilities.
This descriptor includes Interface and Endpoint Descriptors. Every device
must have at least one configuration, in our example there is only one
configuration. The configuration descriptor is presented below:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* Configuration Descriptor 
    :end-before: };

Other Speed Configuration Descriptor
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A other speed configuration for similar reasons as the device qualifier
descriptor. The ``USB_StandardRequests()`` function generates this
descriptor from the Configuration Descriptors passed to it based on
the bus speed it is currently running at.  For the HID mouse example
we used the same configuration Descriptors if running on full-speed
or high-speed.

String Descriptors 
~~~~~~~~~~~~~~~~~~
An array of strings supplies all the strings that are referenced from
the descriptors (using fields such as ‘iInterface’, ‘iProduct’ etc.).
String 0 is the language descriptor, and is interpreted as “no string
supplied” when used as an index value.  The ``USB_StandardRequests()``
function deals with requests for strings using the table of strings
passed to it.  The string table for the HID mouse example is shown below:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* String table 
    :end-before: };

Note that the ``null`` values and length ``0`` is passed for the full-speed
descriptors, this means that the same descriptors will be used whether the
device is running in full or high-speed.

Application and Class Specific Requests 
---------------------------------------

Although the ``USB_StandardRequests()`` function deals with many of the
requests the device is required to handle in order to be properly enumerated
by a host, typically a USB device will have Class (or Application) specific
requests that must be handled.

In the case of the HID mouse there are three mandatory requests that must be handled:

    - ``GET_DESCRIPTOR``

        - ``HID``    Return the HID descriptor

        - ``REPORT`` Return the HID report descriptor

    - ``GET_REPORT`` Return the HID report data

Please refer to the HID Specification and related documentation for full
details of all HID requests.

The HID report descriptor informs the hosts of the contents of the HID reports
that it will be sending to the host periodically. For a mouse this could include
X/Y axis values, button presses etc. Tools for building these descriptors are
available for download on the usb.org website.

The HID report descriptor for the HID mouse example is shown below:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* HID Report Descriptor
    :end-before: };

The request for this descriptor (and the other required requests) should be
implemented before making the call to ``USB_StandardRequests()``. The programmer
may decide not to make a call to ``USB_StandardRequests`` if the request is
fully handled.  It is possible the programmer may choose to implement some
functionality for a request, then allow ``USB_StandardRequests()`` to finalize.

The complete code listing for the main endpoint 0 task is show below:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* Endpoint 0 Task
    :end-before: //:


The skeleton ``HidInterfaceClassRequests()`` function deals with any
outstanding HID requests. See the USB HID Specification for full request
details:

.. literalinclude:: sc_usb_device/app_example_hid_mouse/src/endpoint0.xc
    :start-after: /* HID Class Requests
    :end-before: /* Endpoint 0 Task

If the HID request is not handles, the function returns 1.  This results in
``USB_StandardRequests()`` being called, and eventually the endpoint being
STALLed to indicate an unknown request.

