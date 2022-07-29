# Copyright 2016-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    ep_loopback = ep
    ep_loopback_kill = ep + 1

    start_length = 200
    end_length = 203
    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # TODO randomise packet lengths and data
    for pktLength in range(start_length, end_length + 1):
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep_loopback,
                endpointType="ISO",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=500,
            )
        )

        # Was min IPG supported on iso loopback to not nak
        # This was 420, had to increase when moved to lib_xud (14.1.2 tools)
        # increased again from 437 when SETUP/OUT checking added
        # increaed from 477 when adding xs3
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep_loopback,
                endpointType="ISO",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=498,
            )
        )

    pktLength = 10

    # Loopback and die..
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_loopback_kill,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_loopback_kill,
            endpointType="ISO",
            transType="IN",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )

    return session
