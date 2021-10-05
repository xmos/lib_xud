# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import (
    TokenPacket,
    TxDataPacket,
    USB_PID,
)


@pytest.fixture
def test_session(ep, address, bus_speed):

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # The large inter-frame gap is to give the DUT time to print its output
    interEventDelay = 500

    # Valid OUT transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=10,
            interEventDelay=interEventDelay,
        )
    )

    # OUT Transaction with invalid DATA PID. XCORE should ignore packet - no ACK
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
            interEventDelay=interEventDelay,
        )
    )

    session.add_event(
        TxDataPacket(
            dataPayload=session.getPayload_out(ep, 11, resend=True),
            pid=USB_PID["DATA1"] & 0xF,
        )
    )

    # Send some valid OUT transactions
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=11,
            interEventDelay=interEventDelay,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=12,
            interEventDelay=interEventDelay,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=13,
            interEventDelay=interEventDelay,
        )
    )

    return session
