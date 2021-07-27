#!/usr/bin/env python
# Copyright 2019-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import TxPacket, USB_PID
from usb_session import UsbSession
from usb_transaction import UsbTransaction


# TODO Can this be moved?
@pytest.fixture
def test_file():
    return __file__


@pytest.fixture
def test_session(ep, address, bus_speed, arch):

    if arch == "xs3":
        pytest.xfail("Known failure on xs3")

    address = 1
    ep = 1

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

    # tmp hack for xs2 - for xs2 the shim will throw away the short token and
    # it will never be seen by the xCORE
    if arch == "xs3":
        # Create a short token, only PID and 2nd byte
        shorttoken = TxPacket(
            pid=USB_PID["OUT"],
            data_bytes=[0x81],
            interEventDelay=100,
        )
        session.add_event(shorttoken)

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
