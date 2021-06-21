# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_phy import USB_MAX_EP_ADDRESS
import pytest
from conftest import PARAMS, test_RunUsbSession

# TODO Can this be moved?
@pytest.fixture
def test_file():
    return __file__


@pytest.fixture
def test_session(ep, address, bus_speed):

    if bus_speed == "FS":
        pytest.xfail("Known failure at FS")

    ep = 1
    address = 1
    ied = 500

    trafficAddress1 = 0
    trafficAddress2 = 127
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
                direction="OUT",
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
                direction="OUT",
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
                direction="OUT",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )

        trafficEp1 = trafficEp1 - 1
        if trafficEp1 < 0:
            trafficEp1 = USB_MAX_EP_ADDRESS

        trafficEp2 + trafficEp2 + 1
        if trafficEp1 > USB_MAX_EP_ADDRESS:
            trafficEp1 = 0

    return session
