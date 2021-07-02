app_test_mode
=============


Summary
-------

This application provide stand-alone binaries for USB test modes. There are four build configurations, one for each of the four USB Test Modes:

    - Test_SE0_NAK
    - Test_J
    - Test_K
    - Test_Packet

The application enters it's respective test mode from boot, thus removing the requirement to set the mode from a host via the  USBHSETT tool.

Note, you not should expect the the device to appear on any USB bus and its probably not advisable to plug into any standard host. 

These binaries are most commonly used in device characterisation.


