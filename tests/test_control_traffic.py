# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from copy import deepcopy

import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import (
    TokenPacket,
    TxDataPacket,
    RxDataPacket,
    TxHandshakePacket,
    RxHandshakePacket,
    USB_PID,
)
from usb_session import UsbSession

# Only test on EP 0 - Update params
PARAMS = deepcopy(PARAMS)
for v in PARAMS.values():
    v.update({"ep": [0]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    ied = 500

    trafficAddress1 = (address + 1) % 128
    trafficAddress2 = (address + 127) % 128

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # SETUP to another address (Note, DUT would not see ACK)
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=trafficAddress1,
            endpoint=ep,
        )
    )
    session.add_event(
        TxDataPacket(
            dataPayload=[1, 2, 3, 4, 5, 6, 7, 8],
            pid=USB_PID["DATA0"],
        )
    )

    # SETUP transaction to DUT
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=address,
            endpoint=ep,
        )
    )
    session.add_event(
        TxDataPacket(
            dataPayload=session.getPayload_out(ep, 8),
            pid=USB_PID["DATA0"],
        )
    )
    session.add_event(RxHandshakePacket())

    # IN transaction
    # Note, quite big gap to avoid nak
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
            interEventDelay=10000,
        )
    )
    session.add_event(
        RxDataPacket(
            dataPayload=session.getPayload_in(ep, 10),
            pid=USB_PID["DATA1"],
        )
    )
    session.add_event(TxHandshakePacket())

    # SETUP to another address (Note, DUT would not see ACK)
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=trafficAddress2,
            endpoint=ep,
        )
    )
    session.add_event(
        TxDataPacket(
            dataPayload=[1, 2, 3, 4, 5, 6, 7, 8],
            pid=USB_PID["DATA0"],
        )
    )

    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=trafficAddress2,
            endpoint=ep,
            interEventDelay=1000,
        )
    )

    # Send 0 length OUT transaction
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
            interEventDelay=ied,
        )
    )
    session.add_event(TxDataPacket(length=0, pid=USB_PID["DATA1"]))
    session.add_event(RxHandshakePacket())

    return session
