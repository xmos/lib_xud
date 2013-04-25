Resource Usage
==============

The XUD library requires the resources described in the following
sections.

Ports/Pins
----------

XS1-L Family
............

The ports used for the physical connection to the external ULPI transceiver must
be connected as shown in :ref:`table_xud_ulpi_required_pin_port`.

.. _table_xud_ulpi_required_pin_port:

.. table:: ULPI required pin/port connections
    :class: horizontal-borders vertical_borders

    +------+-------+------+-------+---------------------+
    | Pin  | Port                 | Signal              |
    |      +-------+------+-------+---------------------+
    |      | 1b    | 4b   | 8b    |                     |
    +======+=======+======+=======+=====================+
    | XD12 | P1E0  |              | ULPI_STP            |
    +------+-------+------+-------+---------------------+
    | XD13 | P1F0  |              | ULPI_NXT            |
    +------+-------+------+-------+---------------------+
    | XD14 |       | P4C0 | P8B0  | ULPI_DATA[7:0]      |
    +------+       +------+-------+                     |
    | XD15 |       | P4C1 | P8B1  |                     |
    +------+       +------+-------+                     |
    | XD16 |       | P4D0 | P8B2  |                     |
    +------+       +------+-------+                     |
    | XD17 |       | P4D1 | P8B3  |                     |
    +------+       +------+-------+                     |
    | XD18 |       | P4D2 | P8B4  |                     |
    +------+       +------+-------+                     |
    | XD19 |       | P4D3 | P8B5  |                     |
    +------+       +------+-------+                     |
    | XD20 |       | P4C2 | P8B6  |                     |
    +------+       +------+-------+                     |
    | XD21 |       | P4C3 | P8B7  |                     |
    +------+-------+------+-------+---------------------+
    | XD22 | P1G0  |              | ULPI_DIR            |
    +------+-------+------+-------+---------------------+
    | XD23 | P1H0  |              | ULPI_CLK            |
    +------+-------+------+-------+---------------------+
    | XD24 | P1I0  |              | ULPI_RST_N          |
    +------+-------+------+-------+---------------------+

In addition some ports are used internally when the XUD library is in
operation, for example pins 2-9, 26-33 and 37-43 on an L1 device should
not be used. 

Please refer the device datasheet for further information on which ports
are available.

XS1-U Series Processors
.......................

The XS1-U series of processors has an integrated USB transceiver. Some ports
are used to communicate with the USB transceiver inside the XS1-U packages.
These ports/pins should not be used when USB functionality is enabled.
The ports/pins are shown in :ref:`table_xud_u_required_pin_port`.

.. _table_xud_u_required_pin_port:

.. table:: XS1-U required pin/port connections
    :class: horizontal-borders vertical_borders

    +------+-------+------+-------+-------+--------+
    | Pin  | Port                                  |                
    |      +-------+------+-------+-------+--------+
    |      | 1b    | 4b   | 8b    | 16b   | 32b    |                    
    +======+=======+======+=======+=======+========+
    | XD02 |       | P4A0 | P8A0  | P16A0 | P32A20 |
    +------+-------+------+-------+-------+--------+
    | XD03 |       | P4A1 | P8A1  | P16A1 | P32A21 |
    +------+-------+------+-------+-------+--------+
    | XD04 |       | P4B0 | P8A2  | P16A2 | P32A22 |
    +------+-------+------+-------+-------+--------+
    | XD05 |       | P4B1 | P8A3  | P16A3 | P32A23 |
    +------+-------+------+-------+-------+--------+
    | XD06 |       | P4B2 | P8A4  | P16A4 | P32A24 |
    +------+-------+------+-------+-------+--------+
    | XD07 |       | P4B3 | P8A5  | P16A5 | P32A25 |
    +------+-------+------+-------+-------+--------+
    | XD08 |       | P4A2 | P8A6  | P16A6 | P32A26 |
    +------+-------+------+-------+-------+--------+
    | XD09 |       | P4A3 | P8A7  | P16A7 | P32A27 |
    +------+-------+------+-------+-------+--------+
    | XD23 | P1H0  |                               |
    +------+-------+------+-------+-------+--------+
    | XD25 | P1J0  |                               | 
    +------+-------+------+-------+-------+--------+
    | XD26 |       | P4E0 | P8C0  | P16B0 |        |
    +------+-------+------+-------+-------+--------+
    | XD27 |       | P4E1 | P8C1  | P16B1 |        |
    +------+-------+------+-------+-------+--------+
    | XD28 |       | P4F0 | P8C2  | P16B2 |        |
    +------+-------+------+-------+-------+--------+
    | XD29 |       | P4F1 | P8C3  | P16B3 |        |
    +------+-------+------+-------+-------+--------+
    | XD30 |       | P4F2 | P8C4  | P16B4 |        |
    +------+-------+------+-------+-------+--------+
    | XD31 |       | P4F3 | P8C5  | P16B5 |        |
    +------+-------+------+-------+-------+--------+
    | XD32 |       | P4E2 | P8C6  | P16B6 |        |
    +------+-------+------+-------+-------+--------+
    | XD33 |       | P4E3 | P8C7  | P16B7 |        |
    +------+-------+------+-------+-------+--------+
    | XD34 | P1K0  |                               |
    +------+-------+------+-------+-------+--------+
    | XD36 | P1M0  |      | P8D0  | P16B8 |        |
    +------+-------+------+-------+-------+--------+
    | XD37 | P1N0  |      | P8C1  | P16B1 |        |
    +------+-------+------+-------+-------+--------+
    | XD38 | P1O0  |      | P8C2  | P16B2 |        |
    +------+-------+------+-------+-------+--------+
    | XD39 | P1P0  |      | P8C3  | P16B3 |        |
    +------+-------+------+-------+-------+--------+


Core Speed
------------

Due to I/O requirements the library requires a guaranteed MIPS rate to
ensure correct operation. This means that core count restrictions must
be observed. The XUD core must run at at least 80 MIPS.

This means that for an XS1 running at 400MHz there should be no more
than five cores executing at any one time that USB is being used. For
a 500MHz device no more than six cores shall execute at any one time.

This restriction is only a requirement on the tile on which the XUD core is running. 
For example, a different tile on an L16 device is unaffected by this restriction.

Clock Blocks
------------

XS1-L Family
..............

The Library uses one clock block - clock block  0 - and configures this
clock block to be clocked from the 60MHz clock from the ULPI transceiver.
The ports it uses are in turn clocked from the clock block.

Since clock block 0 is the default for all ports when enabled it is
important that if a port is not required to be clocked from this 60MHz
clock, then it is configured to use another clock block.

XS1-U Family
............

The Library uses two clock-blocks (clock blocks 4 and 5).  These are clocked from the USB clock.


Timers
------

Internally the XUD library allocates and uses four timers.

Memory
------

The library requires around 9 Kbytes of memory, of which around 6 Kbytes
is code or initialized variables that must be stored in either OTP or
Flash.

