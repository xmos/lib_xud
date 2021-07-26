#!/usr/bin/env python
# Copyright 2019-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import CreateSofToken
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    pytest.xfail("Known failure (on XS3)")

    frameNumber = 52  # Note, for frame number 52 we expect A5 34 40 on the bus

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # Start with a valid transaction */
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=10,
        )
    )

    session.add_event(CreateSofToken(frameNumber))
    session.add_event(CreateSofToken(frameNumber + 1))
    session.add_event(CreateSofToken(frameNumber + 2))
    session.add_event(
        CreateSofToken(frameNumber + 3, badCrc=True)
    )  # Invalidate the CRC
    session.add_event(CreateSofToken(frameNumber + 4))

    # Finish with valid transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=11,
            interEventDelay=6000,
        )
    )

    return session
