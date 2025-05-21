# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# This test checks that both IN and OUT endpoints properly receive bus reset notications
# when they register for them.
# Specifically this test checks that EP's still receive the notification properly even if they were
# not marked ready at the time.

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

    initial_delay = 20000

    pktLength = 10
    frameNumber = 52  # For frame number 52 we expect A5 34 40 on the bus

    interEventDelay = USB_PKT_TIMINGS["TX_TO_TX_PACKET_DELAY"] + 10

    session = UsbSession(
        bus_speed=bus_speed,
        run_enumeration=False,
        device_address=address,
        initial_delay=initial_delay * 1000 * 1000, #fS
    )

    session.add_event(UsbDeviceAttach())

    session.add_event(CreateSofToken(frameNumber, interEventDelay=0))

    # OUT transaction to EP 0 to sync host and device
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=0,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=interEventDelay,
        )
    )
    # OUT transaction to test EP
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=interEventDelay+50,
        )
    )

    # IN transaction to test EP - expect NAK, not "old" data
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            interEventDelay=200,
            nacking=True
        )
    )

    # OUT transaction to EP 0 to sync host and device.
    # Device should now mark test EP ready with fresh data.
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=0,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=interEventDelay,
        )
    )

    # IN transaction to test EP - expect good data
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            interEventDelay=200,
        )
    )

    return session
