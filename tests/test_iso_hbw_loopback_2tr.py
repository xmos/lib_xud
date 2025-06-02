# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
from copy import deepcopy
from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import CreateSofToken

# Run at increased system frequency
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"core_freq": [600, 800]})

@pytest.fixture
def test_session(ep, address, bus_speed, core_freq):

    ep_loopback = ep
    ep_loopback_kill = ep + 1

    start_length = 190
    end_length = 210
    ep_length = 200

    frameNumber = 0
    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # TODO randomise packet lengths and data
    for pktLength in range(start_length, end_length + 1):
        session.add_event(CreateSofToken(frameNumber))
        frameNumber += 1

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep_loopback,
                endpointType="ISO",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=10,
                ep_len = ep_length
            )
        )

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep_loopback,
                endpointType="ISO",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=50,
                ep_len = ep_length
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
            ep_len = ep_length
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
            ep_len = ep_length
        )
    )

    if core_freq == 600:
        pytest.xfail("HBW 2txn test requires a 800MHz part")

    return session
