|newpage|

************************************
High bandwidth isochronous endpoints
************************************

``lib_xud`` provides support for high bandwidth isochronous endpoints on high-speed USB devices, as described in the
Section 5.9.2 of the `USB 2.0 specification <https://usb.org/document-library/usb-20-specification>`_.
This enables higher data throughput by allowing multiple transactions per microframe.

The current implementation in ``lib_xud`` has the following limitations:

* A maximum of 2 transactions per microframe is supported (the USB specification allows up to 3).
* The maximum data payload size per transaction is the same across all high bandwidth endpoints
* The maximum data payload size per transaction must be a multiple of 4 bytes.
* This feature is supported only on `xcore.ai` series devices running at an increased system frequency of 800 MHz due to the performance demands of high bandwidth transfers.

Enabling high bandwidth ISO endpoint support
============================================

High bandwidth ISO endpoint support is disabled by default. To enable it, the application must define the
``XUD_USB_ISO_MAX_TXNS_PER_MICROFRAME`` macro as ``2``. This allows up to two transactions per microframe.
By default, this macro is set to ``1`` in ``xud.h``, limiting operation to a single transaction and disabling
high bandwidth transfers. Applications can override the default by re-defining the macro in a custom ``xud_conf.h`` file.

The ``XUD_USB_ISO_EP_MAX_TXN_SIZE`` macro, also defined in ``xud.h``, sets the maximum payload size per ISO transaction.
Its default value is ``1024`` bytes. This can also be overridden in the application's ``xud_conf.h`` file if needed.

High bandwidth ISO transfer support is communicated to the host via the ``wMaxPacketSize`` field in the
Standard AS Isochronous Audio Data Endpoint Descriptor. This field encodes both the maximum packet size
per transaction and the number of transactions per microframe. The format of this field is defined in
Table 9-13 of the `USB 2.0 specification <https://usb.org/document-library/usb-20-specification>`_.
Ensure that ``wMaxPacketSize`` is set correctly in the descriptor to reflect the desired max transaction length and
number of transactions per microframe.


High bandwidth transfer API usage
=================================

The ``lib_xud`` APIs used for handling high bandwidth transfers are:

* Asynchronous operations:
  ``XUD_SetReady_Out``, ``XUD_SetReady_In``, ``XUD_GetData_Select``, ``XUD_SetData_Select``

* Synchronous operations:
  ``XUD_GetBuffer``, ``XUD_SetBuffer``

Asynchronous operation
----------------------

To initiate an IN or OUT transfer, call ``XUD_SetReady_In`` or ``XUD_SetReady_Out``, respectively.
This process is identical to that of standard (non-HiBW) isochronous transfers, except:

* These functions are called **once per transfer**, not per transaction.
* For IN transfers, the ``buffer`` and ``len`` should cover the entire transfer.
* For OUT transfers, the buffer must be at least ``3 * XUD_USB_ISO_EP_MAX_TXN_SIZE`` bytes to accommodate temporary storage needed during error handling,
  even though only one transfer's worth of space is ultimately used.

To poll for transfer completion, use the select handler functions ``XUD_GetData_Select`` or ``XUD_SetData_Select``.
These will return:

* ``XUD_RES_WAIT``: transfer is still in progress — continue calling the function.
* ``XUD_RES_OK``: transfer completed successfully.
* ``XUD_RES_ERROR``: returned by ``XUD_SetData_Select`` to indicate that an error occurred during the transfer.

Example of asynchronous operation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A simple example of asynchronous high bandwidth transfer is shown below:

.. code-block:: c

    #include "xud.h"

    void ExampleEndpoint(chanend c_ep_out, chanend c_ep_in)
    {
        unsigned char rxBuffer[3 * XUD_USB_ISO_EP_MAX_TXN_SIZE];
        #define IN_TRANSFER_SIZE (XUD_USB_ISO_EP_MAX_TXN_SIZE + 100) /* Example size to demostrate transfer spanning 2 transactions*/
        unsigned char txBuffer[IN_TRANSFER_SIZE];
        for(int i = 0; i < IN_TRANSFER_SIZE; i++)
        {
            txBuffer[i] = i % 256; // Example data to send
        }

        int length, result;

        XUD_ep ep_out = XUD_InitEp(c_ep_out);
        XUD_ep ep_in = XUD_InitEp(c_ep_in);

        /* Mark OUT endpoint as ready to receive */
        XUD_SetReady_Out(ep_out, rxBuffer);

        /* Mark IN endpoint as ready to send */
        XUD_SetReady_In(ep_in, txBuffer, sizeof(txBuffer));

        while(1)
        {
            select
            {
                case XUD_GetData_Select(c_ep_out, ep_out, length, result):
                    if(result != XUD_RES_WAIT)
                    {
                        /* Process received packet */
                        for(int i = 0; i < length; i++)
                        {
                            // Process packet...
                        }
                        /* Mark EP as ready again */
                        XUD_SetReady_Out(ep_out, rxBuffer);
                    }
                    break;

                case XUD_SetData_Select(c_ep_in, ep_in, result):
                    if (result != XUD_RES_WAIT)
                    {
                        if (result == XUD_RES_ERROR)
                        {
                            /* Handle error, e.g., retry */
                            XUD_SetReady_In(ep_in, txBuffer, sizeof(txBuffer));
                        }
                    }
                    else
                    {
                        /* Packet successfully sent to host */
                        // Prepare next packet...
                        for(int i = 0; i < IN_TRANSFER_SIZE; i++)
                        {
                            txBuffer[i] = (txBuffer[i]+1) % 256; // Example data to send
                        }
                        XUD_SetReady_In(ep_in, txBuffer, sizeof(txBuffer));
                    }
                    break;
            }
        }
    }



Synchronous operation
---------------------

For synchronous operations, the functions ``XUD_SetBuffer`` or ``XUD_GetBuffer`` are called once per transfer and only
return once the transfer is complete.
The ``buffer`` and ``datalength`` parameters should cover the entire transfer size, same as described for the asynchronous operation.


