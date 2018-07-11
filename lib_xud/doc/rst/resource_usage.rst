Resource Usage
==============

The XUD library requires the resources described in the following
sections.

Ports/Pins
----------

U-Series
........

The U-Series of devices have an integrated USB transceiver. Some ports
are used to communicate with the USB transceiver inside the U-Series packages.
These ports/pins should not be used when USB functionality is enabled.
The ports/pins are shown in :ref:`table_xud_u_required_pin_port`.

.. _table_xud_u_required_pin_port:

.. table:: U-Series required pin/port connections
    :class: horizontal-borders vertical_borders

    +-------+-------+------+-------+-------+--------+
    | Pin   | Port                                  |
    |       +-------+------+-------+-------+--------+
    |       | 1b    | 4b   | 8b    | 16b   | 32b    |
    +=======+=======+======+=======+=======+========+
    | X0D02 |       | P4A0 | P8A0  | P16A0 | P32A20 |
    +-------+-------+------+-------+-------+--------+
    | X0D03 |       | P4A1 | P8A1  | P16A1 | P32A21 |
    +-------+-------+------+-------+-------+--------+
    | X0D04 |       | P4B0 | P8A2  | P16A2 | P32A22 |
    +-------+-------+------+-------+-------+--------+
    | X0D05 |       | P4B1 | P8A3  | P16A3 | P32A23 |
    +-------+-------+------+-------+-------+--------+
    | X0D06 |       | P4B2 | P8A4  | P16A4 | P32A24 |
    +-------+-------+------+-------+-------+--------+
    | X0D07 |       | P4B3 | P8A5  | P16A5 | P32A25 |
    +-------+-------+------+-------+-------+--------+
    | X0D08 |       | P4A2 | P8A6  | P16A6 | P32A26 |
    +-------+-------+------+-------+-------+--------+
    | X0D09 |       | P4A3 | P8A7  | P16A7 | P32A27 |
    +-------+-------+------+-------+-------+--------+
    | X0D23 | P1H0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D25 | P1J0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D26 |       | P4E0 | P8C0  | P16B0 | P32A28 |
    +-------+-------+------+-------+-------+--------+
    | X0D27 |       | P4E1 | P8C1  | P16B1 | P32A29 |
    +-------+-------+------+-------+-------+--------+
    | X0D28 |       | P4F0 | P8C2  | P16B2 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D29 |       | P4F1 | P8C3  | P16B3 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D30 |       | P4F2 | P8C4  | P16B4 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D31 |       | P4F3 | P8C5  | P16B5 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D32 |       | P4E2 | P8C6  | P16B6 | P32A30 |
    +-------+-------+------+-------+-------+--------+
    | X0D33 |       | P4E3 | P8C7  | P16B7 | P32A31 |
    +-------+-------+------+-------+-------+--------+
    | X0D34 | P1K0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D36 | P1M0  |      | P8D0  | P16B8 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D37 | P1N0  |      | P8C1  | P16B1 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D38 | P1O0  |      | P8C2  | P16B2 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D39 | P1P0  |      | P8C3  | P16B3 |        |
    +-------+-------+------+-------+-------+--------+

|newpage|

xCORE-200 Series
................

The xCORE 200 series of devices have an integrated USB transceiver. Some ports
are used to communicate with the USB transceiver inside the xCORE-200
series
packages.
These ports/pins should not be used when USB functionality is enabled.
The ports/pins are shown in :ref:`table_xud_x200_required_pin_port`.

.. _table_xud_x200_required_pin_port:

.. table:: xCORE-200 series required pin/port connections
    :class: horizontal-borders vertical_borders

    +-------+-------+------+-------+-------+--------+
    | Pin   | Port                                  |
    |       +-------+------+-------+-------+--------+
    |       | 1b    | 4b   | 8b    | 16b   | 32b    |
    +=======+=======+======+=======+=======+========+
    | X0D00 | P1A0  |      |       |       |        |
    +-------+-------+------+-------+-------+--------+
    | X0D02 |       | P4A0 | P8A0  | P16A0 | P32A20 |
    +-------+-------+------+-------+-------+--------+
    | X0D03 |       | P4A1 | P8A1  | P16A1 | P32A21 |
    +-------+-------+------+-------+-------+--------+
    | X0D04 |       | P4B0 | P8A2  | P16A2 | P32A22 |
    +-------+-------+------+-------+-------+--------+
    | X0D13 |       | P4B1 | P8A3  | P16A3 | P32A23 |
    +-------+-------+------+-------+-------+--------+
    | X0D22 |       | P4B2 | P8A4  | P16A4 | P32A24 |
    +-------+-------+------+-------+-------+--------+
    | X0D23 |       | P4B3 | P8A5  | P16A5 | P32A25 |
    +-------+-------+------+-------+-------+--------+
    | X0D34 |       | P4A2 | P8A6  | P16A6 | P32A26 |
    +-------+-------+------+-------+-------+--------+
    | X0D09 |       | P4A3 | P8A7  | P16A7 | P32A27 |
    +-------+-------+------+-------+-------+--------+
    | X0D10 | P1C0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D12 | P1E0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D13 | P1F0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D14 |       | P4C0 | P8B0  | P16A8 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D15 |       | P4C1 | P8B1  | P16A9 |        |
    +-------+-------+------+-------+-------+--------+
    | X0D16 |       | P4D0 | P8B2  | P16A10|        |
    +-------+-------+------+-------+-------+--------+
    | X0D17 |       | P4D1 | P8B3  | P16A11|        |
    +-------+-------+------+-------+-------+--------+
    | X0D18 |       | P4D2 | P8B4  | P16A12|        |
    +-------+-------+------+-------+-------+--------+
    | X0D19 |       | P4D3 | P8B5  | P16A13|        |
    +-------+-------+------+-------+-------+--------+
    | X0D20 |       | P4C2 | P8B6  | P16A14|        |
    +-------+-------+------+-------+-------+--------+
    | X0D21 |       | P4C3 | P8B7  | P16A15|        |
    +-------+-------+------+-------+-------+--------+
    | X0D22 | P1G0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D23 | P1H0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D24 | P1I0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D34 | P1K0  |                               |
    +-------+-------+------+-------+-------+--------+


|newpage|

L-Series
........

The ports used for the physical connection to the external ULPI transceiver must
be connected as shown in :ref:`table_xud_ulpi_required_pin_port`.

.. _table_xud_ulpi_required_pin_port:

.. table:: ULPI required pin/port connections
    :class: horizontal-borders vertical_borders

    +-------+-------+------+-------+---------------------+
    | Pin   | Port                 | Signal              |
    |       +-------+------+-------+---------------------+
    |       | 1b    | 4b   | 8b    |                     |
    +=======+=======+======+=======+=====================+
    | X0D12 | P1E0  |              | ULPI_STP            |
    +-------+-------+------+-------+---------------------+
    | X0D13 | P1F0  |              | ULPI_NXT            |
    +-------+-------+------+-------+---------------------+
    | X0D14 |       | P4C0 | P8B0  | ULPI_DATA[7:0]      |
    +-------+       +------+-------+                     |
    | X0D15 |       | P4C1 | P8B1  |                     |
    +-------+       +------+-------+                     |
    | X0D16 |       | P4D0 | P8B2  |                     |
    +-------+       +------+-------+                     |
    | X0D17 |       | P4D1 | P8B3  |                     |
    +-------+       +------+-------+                     |
    | X0D18 |       | P4D2 | P8B4  |                     |
    +-------+       +------+-------+                     |
    | X0D19 |       | P4D3 | P8B5  |                     |
    +-------+       +------+-------+                     |
    | X0D20 |       | P4C2 | P8B6  |                     |
    +-------+       +------+-------+                     |
    | X0D21 |       | P4C3 | P8B7  |                     |
    +-------+-------+------+-------+---------------------+
    | X0D22 | P1G0  |              | ULPI_DIR            |
    +-------+-------+------+-------+---------------------+
    | X0D23 | P1H0  |              | ULPI_CLK            |
    +-------+-------+------+-------+---------------------+
    | X0D24 | P1I0  |              | ULPI_RST_N          |
    +-------+-------+------+-------+---------------------+

In addition some ports are used internally when the XUD library is in
operation. For example pins X0D2-X0D9, X0D26-X0D33 and X0D37-X0D43 on
an XS1-L device should not be used.

Please refer to the device datasheet for further information on which ports
are available.


Core Speed
------------

Due to I/O requirements, the library requires a guaranteed MIPS rate to
ensure correct operation. This means that core count restrictions must
be observed. The XUD core must run at at least 80 MIPS.

This means that for an xCORE device running at 500MHz there should be no more
than six cores executing at any time when using the XUD. xCORE-200 devices all setting
priority cores that are guarrenteed 20% of the processor bandwidth. If XUD is assigned
a priority core then up to eight cores may be used with the remaining seven getting
(500 * 0.8) / 7 = 57.1MHz each.

This restriction is only a requirement on the tile on which the ``XUD_Manager`` is running.
For example, the other tile on an dual-core device is unaffected by this restriction.

Clock Blocks
------------

The XUD library uses one clock block (clock block 0) and configures this
clock block to be clocked by the 60MHz clock from the ULPI transceiver.
The ports it uses are in turn clocked from the clock block.

Since clock block 0 is the default for all ports when enabled it is
important that if a port is not required to be clocked from this 60MHz
clock, then it is configured to use another clock block.

U-Series / xCORE-200
....................

The XUD library uses two clock blocks (clock blocks 4 and 5). These are
clocked from the USB clock.  Unlike the L devices, clock-block 0 is not
used or affected.

Timers
------

The XUD library allocates and uses four timers.

Memory
------

The XUD library requires about 9 Kbytes of memory, of which around 6 Kbytes
is code or initialized variables that must be stored in boot memory.

