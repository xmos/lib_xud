# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import CreateSofToken
from usb_signalling import UsbSuspend, UsbResume
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_phy import USB_PKT_TIMINGS


@pytest.fixture
def test_session(ep, address, bus_speed):

    pktLength = 10
    frameNumber = 52  # Note, for frame number 52 we expect A5 34 40 on the bus

    interEventDelay = USB_PKT_TIMINGS["TX_TO_TX_PACKET_DELAY"]

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=0,
        )
    )

    session.add_event(CreateSofToken(frameNumber))

    session.add_event(UsbSuspend(350000))
    session.add_event(UsbResume())

    frameNumber = frameNumber + 1
    pktLength = pktLength + 1
    session.add_event(CreateSofToken(frameNumber, interEventDelay=2000))

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
