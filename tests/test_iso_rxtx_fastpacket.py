# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import CreateSofToken


@pytest.fixture
def test_session(ep, address, bus_speed, hbw_support):

    start_length = 10
    end_length = 19
    frameNumber = 0

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(start_length, end_length + 1):
        if hbw_support == "hbw_on":
            session.add_event(CreateSofToken(frameNumber))
            frameNumber += 1
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="ISO",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=6
            )
        )

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="ISO",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=6
            )
        )

    return session
