# Copyright 2016-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from copy import deepcopy

import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import CreateSofToken
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_signalling import UsbDeviceAttach
from usb_phy import USB_PKT_TIMINGS

# Only need to run device attach tests for one ep/address
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"ep": [1], "address": [1]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    # TODO ideally this can be tidied
    initial_delay = 22000

    pktLength = 10
    frameNumber = 52  # Note, for frame number 52 we expect A5 34 40 on the bus

    interEventDelay = USB_PKT_TIMINGS["TX_TO_TX_PACKET_DELAY"]

    session = UsbSession(
        bus_speed=bus_speed,
        run_enumeration=False,
        device_address=address,
        initial_delay=initial_delay * 1000 * 1000,  # fS
    )

    session.add_event(UsbDeviceAttach())

    session.add_event(CreateSofToken(frameNumber, interEventDelay=0))

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=interEventDelay,
        )
    )

    frameNumber = frameNumber + 1
    pktLength = pktLength + 1

    session.add_event(CreateSofToken(frameNumber))
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=interEventDelay,
        )
    )

    return session
