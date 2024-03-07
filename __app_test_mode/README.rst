app_test_mode
=============


Summary
-------

This application provide stand-alone binaries for USB test modes. There are five build configurations, four are for each of the four USB Test Modes:

    - Test_SE0_NAK
    - Test_J
    - Test_K
    - Test_Packet

The fifth build configuration is for internal use only and is special build to output IN packets in the specific format (address = 0x01) for use in the receiver sensitivity test.

    - TEST_IN_ADDR1

The application enters it's respective test mode from boot, thus removing the requirement to set the mode from a host via the  USBHSETT tool.

Note, you not should expect the the device to appear on any USB bus and its probably not advisable to plug into any standard host. 

These binaries are most commonly used in device characterisation.


