
.. _sec_programming:

*****************
Programming Guide
*****************

This section provides information on how to create an basic application using the ``lib_xud``.

Includes
========

The application needs to include the header file `xud.h`.

Declarations
============

Arrays representinge end endpoint types for both IN and OUT endpoints should be declared. These must
each include one for endpoint 0, for example::

    /* Endpoint type tables */
    XUD_EpType epTypeTableOut[] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
    XUD_EpType epTypeTableIn[] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE , XUD_EPTYPE_BUL};


The endpoint types are:

    * ``XUD_EPTYPE_ISO``: Isochronous endpoint
    * ``XUD_EPTYPE_INT``: Interrupt endpoint
    * ``XUD_EPTYPE_BUL``: Bulk endpoint
    * ``XUD_EPTYPE_CTL``: Control endpoint
    * ``XUD_EPTYPE_DIS``: Disabled endpoint

``XUD_STATUS_ENABLE`` is ORed in to the endpoints that wish to be informed of USB bus resets (see
:ref:`sec_status_reporting`).

``main()``
==========

Within the ``main()`` function it is necessary to allocate the channels to connect the endpoints
and then create the top-level par containing calls to  ``XUD_Main()``, an endpoint 0 task and any
application specific endpoint tasks, for example::

    int main ()
    {
        chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
        par
        {
            XUD_Main(c_ep_out , XUD_EP_COUNT_OUT ,
                     c_ep_in , XUD_EP_COUNT_IN ,
                     null , epTypeTableOut , epTypeTableIn ,
                     null , null , null , XUD_SPEED_HS , null);

            Endpoint0(c_ep_out[0], c_ep_in[0]);

            // Application specific endpoints
            ...
        }
    }
    return 0;

``XUD_Main()`` connects to one end of every channel while the other end is passed to an endpoint
(either endpoint 0 or an application specific endpoint). Application specific endpoints are
connected using channel ends so the IN and OUT channel arrays need to be extended for each endpoint.

Endpoint Addresses
==================

Endpoint 0 uses index 0 of both the endpoint type table and the channel array. The address of other
endpoints must also correspond to their index in the endpoint table and the channel array.

Sending and Receiving Data
==========================

An application specific endpoint can send data using ``XUD_SetBuffer()`` and receive data using
``XUD_GetBuffer()`` etc as described in :ref:`sec_basic_usage`.

Endpoint 0 Implementation
=========================

It is necessary to create an implementation for endpoint 0 which takes two channels, one for IN and
one for OUT. It can take an optional channel for `test` (see :ref:`sec_test_modes`):

A typical prototype might for such a funciton might look like the following::

    void Endpoint0(chanend chan_ep0_out , chanend chan_ep0_in , chanend ?c_usb_test)

Every endpoint must be initialized using the ``XUD_InitEp()`` function. For endpoint 0 this should
like the following::

    XUD_ep ep0_out = XUD_InitEp(chan_ep0_out);
    XUD_ep ep0_in = XUD_InitEp(chan_ep0_in);

Typically the minimal code for endpoint 0 loops making call to ``USB_GetSetupPacket()``, parses
the ``USB_SetupPacket_t`` for any class/applicaton specific requests. Then makes a call to
``USB_StandardRequests()``. And finally, calls ``XUD_ResetEndpoint()`` if there have been a
bus-reset. For example::

    while (1)
    {
        /* Returns XUD_RES_OKAY on success, XUD_RES_RST for USB reset */
        XUD_Result_t result = USB_GetSetupPacket(ep0_out , ep0_in , sp);

        if(result == XUD_RES_OKAY)
        {
            switch(sp.bmRequestType.Type)
            {
                case BM_REQTYPE_TYPE_CLASS:
                    switch(sp.bmRequestType.Receipient)
                    {
                        case BM_REQTYPE_RECIP_INTER:
                            // Optional class specific requests
                            break;

                        ...
                    }

                    break;
                ...
            }

            result = USB_StandardRequests(ep0_out , devDesc , devDescLen , ...);
        }

        if(result == XUD_RES_RST)
            usbBusSpeed = XUD_ResetEndpoint(ep0_out , ep0_in);
    }

The code above could also over-ride any of the requests handled in ``USB_StandardRequests()`` for
custom functionality.

.. note::

    Class specific code should be inserted before USB_StandardRequests() is called since if
    USB_StandardRequests() cannot handle a request it marks the Endpoint stalled to indicate to
    the host that the request is not supported by the device.

``USB_StandardRequests()`` takes `char` array parameters for device descriptors for both high and
full-speed. Note, if null is passed as the full-speed descriptor the high-speed descriptor is used
in full-speed mode and vice versa.

.. note::

    On bus reset the ``XUD_ResetEndpoint()`` function returns the negotiated USB speed (i.e. full
    or high speed).

Device Descriptors
==================

Every USB device must provide a set of descriptors. They are used to identify the USB device’s
vendor ID, product ID and detail all the attributes of the advice as specified in the USB 2.0
specifications.

It is beyond the scope of this document to give details of writing a descriptor, please see the
relevant USB Specification Documents.
