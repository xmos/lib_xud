# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import TokenPacket, USB_PID, RxHandshakePacket
import pytest
from conftest import PARAMS, test_RunUsbSession  # noqa F401


@pytest.fixture
def test_session(ep, address, bus_speed):

    pktLength = 10

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    ep_ctrl = ep + 1

    # Ping EP, expect stall
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["STALL"]))

    # And again
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["STALL"]))

    # Valid transaction to another EP informing test code to clear stall
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_ctrl,
            endpointType="BULK",
            direction="OUT",
            dataLength=pktLength,
        )
    )

    # Expect normal transactions
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=pktLength,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=pktLength,
        )
    )

    return session
