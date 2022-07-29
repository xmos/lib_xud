# Copyright 2016-2022 XMOS LIMITED.
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
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="SETUP",
            dataLength=8,
            interEventDelay=500,
        )
    )

    # DUT should now mark IN and OUT EP as halted
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="IN",
            dataLength=0,
            halted=True,
            interEventDelay=500,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="OUT",
            dataLength=10,
            halted=True,
            interEventDelay=500,
        )
    )

    # Ctrl transaction 1
    # This should clear the halted flag
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="SETUP",
            dataLength=8,
            interEventDelay=500,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="OUT",
            dataLength=10,
            interEventDelay=500,
        )
    )

    # Expect 0 length IN transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="IN",
            dataLength=0,
            interEventDelay=500,
        )
    )

    return session
