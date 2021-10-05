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
for k in PARAMS:
    PARAMS[k].update({"ep": [0]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="SETUP",
            dataLength=8,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="IN",
            dataLength=10,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="CONTROL",
            transType="OUT",
            dataLength=0,
        )
    )

    return session
