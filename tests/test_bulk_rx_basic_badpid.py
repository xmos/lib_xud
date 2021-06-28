# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest
from conftest import PARAMS, test_RunUsbSession

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
            direction="OUT",
            dataLength=10,
            interEventDelay=interEventDelay,
        )
    )

    # Pretend the ACK went missing on the way to host. Re-send same packet. xCORE should ACK but throw pkt away
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=11,
            interEventDelay=interEventDelay,
            resend=True,
        )
    )

    # Send some valid OUT transactions
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
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
            direction="OUT",
            dataLength=13,
            interEventDelay=interEventDelay,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=14,
            interEventDelay=interEventDelay,
        )
    )

    return session
