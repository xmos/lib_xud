XMOS Low-Level USB Driver Library
=================================

This module provides access to the in-device peripherals. 

Currently the library only supports the Analog to Digital Converters (ADC).

XUD API
-------

.. doxygenenum:: XUD_EpType

.. doxygenfunction:: XUD_GetData
.. doxygenfunction:: XUD_GetSetupData
.. doxygenfunction:: XUD_SetData

.. doxygentypedef:: BmRequestType_t
.. doxygentypedef:: SetupPacket_t

.. doxygenfunction:: XUD_GetSetupPacket
.. doxygenfunction:: XUD_Manager
.. doxygenfunction:: XUD_ParseSetupPacket
.. doxygenfunction:: XUD_PrintSetupPacket
.. doxygenfunction:: XUD_GetBuffer
.. doxygenfunction:: XUD_GetSetupBuffer
.. doxygenfunction:: XUD_SetBuffer
.. doxygenfunction:: XUD_SetBuffer_EpMax
.. doxygenfunction:: XUD_DoGetRequest
.. doxygenfunction:: XUD_DoSetRequestStatus
.. doxygenfunction:: XUD_SetDevAddr
.. doxygenfunction:: XUD_ResetEndpoint
.. doxygenfunction:: XUD_ResetDrain
.. doxygenfunction:: XUD_GetBusSpeed
.. doxygenfunction:: XUD_Init_Ep
.. doxygenfunction:: XUD_SetStall_Out
.. doxygenfunction:: XUD_SetStall_In
.. doxygenfunction:: XUD_ClearStall_Out
.. doxygenfunction:: XUD_ClearStall_In
.. doxygenfunction:: XUD_GetData_Select
.. doxygenfunction:: XUD_SetData_Select
.. doxygenfunction:: XUD_SetReady_Out
.. doxygenfunction:: XUD_SetReady_OutPtr
.. doxygenfunction:: XUD_SetReady_In
.. doxygenfunction:: XUD_SetReady_InPtr

