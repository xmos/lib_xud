# Copyright 2016-2025 XMOS LIMITED.
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

    # Rx -> Tx, recieving OUT handshake -> sending OUT tok
    ied_out = 19

    # Valid OUT transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=10,
        )
    )

    # OUT Transaction with invalid DATA PID. XCORE should ignore packet - no ACK
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
            interEventDelay=ied_out,
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
            interEventDelay=ied_out,
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
            interEventDelay=ied_out,
        )
    )

    return session
