# Copyright 2019-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import CreateSofToken
from usb_transaction import INTER_TRANSACTION_DELAY


@pytest.fixture
def test_session(ep, address, bus_speed):

    frameNumber = 52  # Note, for frame number 52 we expect A5 34 40 on the bus
    interEventDelay = 50

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
            transType="OUT",
            dataLength=10,
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=interEventDelay))
    session.add_event(CreateSofToken(frameNumber + 1, interEventDelay=interEventDelay))
    session.add_event(CreateSofToken(frameNumber + 2, interEventDelay=interEventDelay))
    session.add_event(CreateSofToken(frameNumber + 3, interEventDelay=interEventDelay))
    session.add_event(CreateSofToken(frameNumber + 4, interEventDelay=interEventDelay))

    # Finish with valid transaction
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

    return session
