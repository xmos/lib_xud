Licensing
---------

libusb is written in C and licensed under the LGPL-2.1 (see COPYING).

The host application is written by XMOS and covered by our Standard
Software License (see ../../LICENSE.txt).

Overview
--------

This simple host example demonstrates simple bulk transfer requests between
the host processor and the XMOS device.

The application simply sends PTP-like commands for setting up the image size 
and the type and then sends a request to get the image.
It receives a response for each command and also the image data. 
The received image data is stored in PPM or PGM format.

The binary and 'libusb' library are provided for Linux64 platform.
To run the example, execute './get_image'.

Compilation instruction
------------------------

Linux64
-------
g++ -o get_image ../get_image.cpp -I ../libusb/Linux64 ../libusb/Linux64/libusb-1.0.a -lpthread -lrt

