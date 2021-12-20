# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_phy import USB_MAX_EP_ADDRESS


@pytest.fixture
def test_session(ep, address, bus_speed):

    ied = 500

    trafficAddress1 = (address + 1) % 128
    trafficAddress2 = (address + 127) % 128
    trafficEp1 = USB_MAX_EP_ADDRESS
    trafficEp2 = 0

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(10, 20):

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=trafficAddress1,
                endpointNumber=trafficEp1,
                endpointType="BULK",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="BULK",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=trafficAddress2,
                endpointNumber=trafficEp2,
                endpointType="BULK",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )

        trafficEp1 = trafficEp1 - 1

        # Don't clash with test EP
        if trafficEp1 == ep:
            trafficEp1 = trafficEp1 - 1

        if trafficEp1 < 0:
            trafficEp1 = USB_MAX_EP_ADDRESS

        # Don't clash with test EP
        if trafficEp2 == ep:
            trafficEp2 = trafficEp1 + 1

        if trafficEp2 > USB_MAX_EP_ADDRESS:
            trafficEp2 = 0

    return session
