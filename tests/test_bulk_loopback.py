# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from copy import deepcopy

import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction

PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"dummy_threads": [4]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    ep_loopback = ep
    ep_loopback_kill = ep + 1

    # Rx -> Tx, recieving handshake after OUT -> sending IN tok
    ied_in = 21
    # Last IN doesn't work with 21 for some reason
    ied_in1 = 25
    # Tx -> Tx, sending IN handshake -> sending next OUT tok
    ied_out = 15

    start_length = 10
    end_length = 20

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
                endpointType="BULK",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=ied_out,
            )
        )
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep_loopback,
                endpointType="BULK",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=ied_in,
            )
        )

    pktLength = start_length

    # Loopback and die..
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_loopback_kill,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=ied_out,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_loopback_kill,
            endpointType="BULK",
            transType="IN",
            dataLength=pktLength,
            interEventDelay=ied_in1,
        )
    )

    return session
