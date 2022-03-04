# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    pktLength = 10

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # Valid transactions on test EP's
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
        )
    )

    # Try some other endpoints that should not be used - expect STALL
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=15,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            halted=True,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=6,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            halted=True,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=15,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            halted=True,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=6,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            halted=True,
        )
    )

    # Valid transactions on test EP finishes the test
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
        )
    )


    return session
