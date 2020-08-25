app_test_mode
=============


Summary
-------

This application stand-alone binaries for USB test modes. There are four build configurations, one for each USB test modes: 

    - Test_SE0_NAK
    - Test_J
    - Test_K
    - Test_Packet

The application enters it's respective test mode from boot, this removing the requirement to set the mode from a host via the  USBHSETT tool.

Note, you not shouild expect the the device to appear on any USB bus and its probabky not advisable to plug into any standard host. 

This binaries are most commonly used in device characterisation.


