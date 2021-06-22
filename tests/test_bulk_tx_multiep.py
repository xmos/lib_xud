# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest
from conftest import PARAMS, test_RunUsbSession


@pytest.fixture
def test_session(ep, address, bus_speed):

    ep = 3  # Note this is a starting EP
    address = 1
    ied = 200

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(10, 20):
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="BULK",
                direction="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep + 1,
                endpointType="BULK",
                direction="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep + 2,
                endpointType="BULK",
                direction="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep + 3,
                endpointType="BULK",
                direction="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )

    return session
