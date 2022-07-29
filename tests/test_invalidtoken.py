# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Same as simple RX bulk test but some invalid tokens also included
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import TokenPacket, USB_PID
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # Reserved/Invalid PID
    session.add_event(
        TokenPacket(
            pid=USB_PID["RESERVED"],
            address=address,
            endpoint=ep,
        )
    )

    # Valid IN but not for DUT
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address + 1,
            endpoint=ep,
        )
    )

    # Valid OUT but not for DUT
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address + 1,
            endpoint=ep,
        )
    )

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

    # Valid SETUP but not for us..
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=address + 2,
            endpoint=ep,
        )
    )

    # Valid OUT transaction
    # Note, quite big gap to allow checking.
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=11,
            interEventDelay=6000,
        )
    )

    # Valid PING but not for us..
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address + 2,
            endpoint=ep,
        )
    )

    # Finish with some valid transactions
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=12,
            interEventDelay=6000,
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
            interEventDelay=6000,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=14,
            interEventDelay=6000,
        )
    )

    return session
