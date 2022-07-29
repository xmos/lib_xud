#!/usr/bin/env python
# Copyright 2016-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Directed test for (github) issue #58
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    pktLength = 10

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    ep_ctrl = ep + 1

    # Expect test EP's to be halted
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            halted=True,
            interEventDelay=500,
        )
    )

    # Inform DUT to un-halt OUT EP via ctrl EP
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_ctrl,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )

    # Expect normal transaction on IN EP
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )
    pktLength += 1

    # ----

    # Expect normal transaction on IN EP
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )
    pktLength += 1

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_ctrl,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )

    # Expect EP to now be re-halted
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            halted=True,
            interEventDelay=500,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_ctrl,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )

    return session
