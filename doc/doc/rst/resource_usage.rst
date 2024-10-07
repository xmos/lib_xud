Resource Usage
==============

The XUD library requires the resources described in the following
sections.

Ports/Pins
----------

xCORE.AI Series
...............

The xCORE.AI series of devices have an integrated USB transceiver. Some ports
are used to communicate with the USB transceiver inside the xCORE.AI
series packages.

These ports/pins should not be used when USB functionality is enabled.
The ports/pins are shown in :ref:`table_xud_xai_required_pin_port`.

.. _table_xud_xai_required_pin_port:

.. table:: xCORE.AI series required pin/port connections
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
    | X0D23 | P1H0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D24 | P1I0  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D25 | P1IJ  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D34 | P1K0  |                               |
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
    | X0D25 | P1IJ  |                               |
    +-------+-------+------+-------+-------+--------+
    | X0D34 | P1K0  |                               |
    +-------+-------+------+-------+-------+--------+


|newpage|


Core Frequency
--------------

Due to I/O requirements, the library requires a guaranteed MIPS rate to
ensure correct operation. This means that core count restrictions must
be observed. The XUD core must run at at least 85 MIPS.

This means that for an xCORE device running at 600MHz there should be no more
than seven cores executing at any time when using the XUD. xCORE devices allow setting cores to
"priority" mode. Priority cores are guarenteed 20% of the processor bandwidth. If XUD is assigned
a priority core then up to eight cores may be used with the remaining seven getting
(600 * 0.8) / 7 = 68.6MIPS each.

This restriction is only a requirement on the tile on which the ``XUD_Main`` is running.
For example, the other tile on an dual-core device is unaffected by this restriction.

Clock Blocks
------------

The XUD library uses two clock blocks, one for receive and one for transmit. 
Clocks blocks 4 and 5 are used respectively.  These clock blocks are configured such
that they are clocked by the 60MHz clock from the UTMI transceiver.
The ports used by lib_xud are in turn clocked from these clock blocks.

Timers
------

The XUD library allocates and uses four timers.

Memory
------

The XUD library requires about 9 Kbytes of memory, of which around 6 Kbytes
is code or initialized variables that must be stored in boot memory.

