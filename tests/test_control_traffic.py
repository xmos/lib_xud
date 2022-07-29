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
for v in PARAMS.values():
    v.update({"ep": [0]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    ied = 500

    trafficAddress1 = (address + 1) % 128
    trafficAddress2 = (address + 127) % 128

    start_length = 0
    end_length = start_length + 10

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(start_length, end_length):

        # SETUP to another address (Note, DUT would not see ACK)
        session.add_event(
            TokenPacket(
                pid=USB_PID["SETUP"],
                address=trafficAddress1,
                endpoint=ep,
                interEventDelay=ied,
            )
        )
        session.add_event(
            TxDataPacket(
                dataPayload=[1, 2, 3, 4, 5, 6, 7, 8],
                pid=USB_PID["DATA0"],
                interEventDelay=ied,
            )
        )

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="CONTROL",
                transType="SETUP",
                dataLength=8,
                interEventDelay=ied,
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
                interEventDelay=ied,
            )
        )

        # SETUP to another address (Note, DUT would not see ACK)
        session.add_event(
            TokenPacket(
                pid=USB_PID["SETUP"],
                address=trafficAddress2,
                endpoint=ep,
                interEventDelay=ied,
            )
        )
        session.add_event(
            TxDataPacket(
                dataPayload=[1, 2, 3, 4, 5, 6, 7, 8],
                pid=USB_PID["DATA0"],
                interEventDelay=ied,
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
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="CONTROL",
                transType="OUT",
                dataLength=0,
                interEventDelay=ied,
            )
        )

    return session
