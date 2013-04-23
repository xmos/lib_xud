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

.. doxygenfunction:: USB_StandardRequests

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

