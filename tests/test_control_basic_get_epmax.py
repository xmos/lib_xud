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

    # Note, EP0_MAX_PACKET_SIZE set to 8 in test to speed things up
    maxPktLength = 8

    startLength = 8
    endLength = 20

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for dataLength in range(startLength, endLength + 1):

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="CONTROL",
                transType="SETUP",
                dataLength=8,
                interEventDelay=1000,  # Large delay to allow for packet generation
            )
        )

        thisDataLength = dataLength

        while thisDataLength > 0:

            pktLength = maxPktLength

            if thisDataLength < maxPktLength:
                pktLength = thisDataLength

            thisDataLength = thisDataLength - pktLength

            session.add_event(
                UsbTransaction(
                    session,
                    deviceAddress=address,
                    endpointNumber=ep,
                    endpointType="CONTROL",
                    transType="IN",
                    dataLength=pktLength,
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
                dataLength=0,
                interEventDelay=500,
            )
        )

    return session
