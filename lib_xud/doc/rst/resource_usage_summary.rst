Typical Resource Usage
----------------------

.. resusage::

  * - configuration: USB device (xCORE-200 series)
    - target: XCORE-200-EXPLORER
    - flags: -DXUD_SERIES_SUPPORT=XUD_X200_SERIES
    - globals: XUD_EpType epTypeTableOut[1] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
               XUD_EpType epTypeTableIn[1] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
    - locals: chan c_ep_out[1];chan c_ep_in[1];
    - fn: XUD_Main(c_ep_out, 1, c_ep_in, 1,
                      null, epTypeTableOut, epTypeTableIn, 
                      null, null, -1 , XUD_SPEED_HS, XUD_PWR_BUS);
    - pins: 23 (internal)
    - ports: 11

  * - configuration: USB device (U series)
    - target: SLICEKIT-U16
    - flags: -DXUD_SERIES_SUPPORT=XUD_U_SERIES
    - globals: XUD_EpType epTypeTableOut[1] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
               XUD_EpType epTypeTableIn[1] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
    - locals: chan c_ep_out[1];chan c_ep_in[1];
    - fn: XUD_Main(c_ep_out, 1, c_ep_in, 1,
                      null, epTypeTableOut, epTypeTableIn, 
                      null, null, -1 , XUD_SPEED_HS, XUD_PWR_BUS);
    - pins: 23 (internal)
    - ports: 11
