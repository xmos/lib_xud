#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Rx out of seq (but valid.. ) data PID
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest
from conftest import PARAMS, test_RunUsbSession

# TODO Can this be moved?
@pytest.fixture
def test_file():
    return __file__


@pytest.fixture
def test_session(ep, address, bus_speed):

    address = 1
    ep = 1

    # The large inter-event delay is to give the DUT time to perform checking
    ied = 500

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for length in range(10, 15):

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="BULK",
                direction="OUT",
                dataLength=length,
                interEventDelay=ied,
            )
        )

        # Simulate missing data payload
        if length == 11:
            session.add_event(
                TokenPacket(
                    endpoint=ep,
                    address=address,
                    pid=USB_PID["OUT"],
                    interEventDelay=ied,
                )
            )

    return session
