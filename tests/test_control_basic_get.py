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
for k in PARAMS:
    PARAMS[k].update({"ep": [0]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    start_length = 0
    end_length = start_length + 10
    interEventDelay = 500

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(start_length, end_length):

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="CONTROL",
                transType="SETUP",
                dataLength=8,
                interEventDelay=interEventDelay,
            )
        )

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="CONTROL",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=interEventDelay,
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
                interEventDelay=interEventDelay,
            )
        )

    return session
