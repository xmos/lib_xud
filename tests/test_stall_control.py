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
from usb_transaction import UsbTransaction

# Only test on EP 0 - Update params
PARAMS = deepcopy(PARAMS)
PARAMS["default"].update({"ep": [0]})
PARAMS["smoke"].update({"ep": [0]})
PARAMS["extended"].update({"ep": [0]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    ied = 500
    pktLength = 10

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # Ctrl transaction 0

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
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
            interEventDelay=ied,
        )
    )
    session.add_event(RxDataPacket(dataPayload=[], pid=USB_PID["DATA1"]))
    session.add_event(TxHandshakePacket())

    # Ctrl transaction 1

    # SETUP transaction
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=address,
            endpoint=ep,
            interEventDelay=10000,
        )
    )
    session.add_event(
        TxDataPacket(
            dataPayload=session.getPayload_out(ep, 8),
            pid=USB_PID["DATA0"],
        )
    )
    session.add_event(RxHandshakePacket())

    # Check that the EP is now Halted
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            direction="IN",
            dataLength=pktLength,
            halted=True,
            interEventDelay=1000,
        )
    )

    # Ctrl transaction 2

    # SETUP transaction
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=address,
            endpoint=ep,
            interEventDelay=10000,
        )
    )
    session.add_event(
        TxDataPacket(
            dataPayload=session.getPayload_out(ep, 8),
            pid=USB_PID["DATA0"],
        )
    )
    session.add_event(RxHandshakePacket())

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            direction="IN",
            dataLength=pktLength,
            halted=False,
            interEventDelay=1000,
            resetDataPid=True,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=0,
            halted=False,
            interEventDelay=1000,
            resetDataPid=True,
        )
    )

    return session
