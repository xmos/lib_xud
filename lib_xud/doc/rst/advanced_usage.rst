Advanced Usage
==============

This section outlines the advanced usage of XUD using the old-style sc_xud API. For new projects please refer to the newer *lib-xud API and Usage* section.

Advanced usage is termed to mean the implementation of multiple endpoints in a single core as well as the addition of real-time processing to an endpoint core.

The functions documented in Basic Usage such as ``XUD_SetBuffer()`` and ``XUD_GetBuffer()`` block until data has either been successfully sent or received to or from the host.  For this reason it is not generally possible to handle multiple endpoints in a single core efficiently (or at all, depending on the protocols involved).

The XUD library therefore provides functions to allow the separation of requesting to send/receive a packet and the notification of a successful transfer.  This is based on the ``XC`` ``select`` statement language feature.

General operation is as follows:

    * An ``XUD_SetReady_`` function is called to mark an endpoint as ready to send or receive data

    * An ``select`` statement is used, along with a ``select handler`` to wait for, and capture, send/receive notifications from the ``XUD_Main`` core.

Function Details
----------------

The available ``XUD_SetReady_`` functions are listed below.

``XUD_SetReady_Out()``
......................

.. doxygenfunction:: XUD_SetReady_Out

``XUD_SetReady_In()``
.....................

.. doxygenfunction:: XUD_SetReady_In

The following functions are also provided to ease integration with more complex buffering schemes than a single packet buffer.  A example might be a circular-buffer for an audio stream.

``XUD_SetReady_OutPtr()``
.........................

.. doxygenfunction:: XUD_SetReady_OutPtr

``XUD_SetReady_InPtr()``
........................

.. doxygenfunction:: XUD_SetReady_InPtr

Once an endpoint has been marked ready to send/receive by calling one of the above ``XUD_SetReady_`` functions, an ``XC select`` statement can be used to handle notifications of a packet being sent/received from ``XUD_Main()``.  These notifications are communicated via channels.

For convenience, ``select handler`` functions are provided to handle events in the ``select`` statement.  These are documented below.

``XUD_GetData_Select()``
........................

.. doxygenfunction:: XUD_GetData_Select

``XUD_SetData_Select()``
........................

.. doxygenfunction:: XUD_SetData_Select

Example
.......

A simple example of the functionality described in this section is shown below:

.. literalinclude:: advanced_usage_example_xc

