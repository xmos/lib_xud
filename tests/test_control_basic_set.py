# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_packet import (
    TokenPacket,
    TxDataPacket,
    RxDataPacket,
    TxHandshakePacket,
    RxHandshakePacket,
    USB_PID,
)
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest
from conftest import PARAMS, test_RunUsbSession
from copy import deepcopy

# Only test on EP 0 - Update params
PARAMS = deepcopy(PARAMS)
PARAMS["default"].update({"ep": [0]})
PARAMS["smoke"].update({"ep": [0]})
PARAMS["extended"].update({"ep": [0]})


@pytest.fixture
def test_session(ep, address, bus_speed, dummy_threads):

    ied = 500

    # if bus_speed == "HS" and dummy_threads > 4:
    #    pytest.xfail("Known fail when dummy threads > 4")

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # SETUP transaction
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

    # OUT transaction
    # Note, quite big gap to avoid nak
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
            interEventDelay=10000,
        )
    )
    session.add_event(
        TxDataPacket(
            dataPayload=session.getPayload_out(ep, 10),
            pid=USB_PID["DATA1"],
        )
    )
    session.add_event(RxHandshakePacket())

    # Expect 0 length IN transaction
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"], address=address, endpoint=ep, interEventDelay=ied
        )
    )
    session.add_event(RxDataPacket(dataPayload=[], pid=USB_PID["DATA1"]))
    session.add_event(TxHandshakePacket())

    return session
