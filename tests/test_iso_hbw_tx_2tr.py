# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
from copy import deepcopy

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_packet import CreateSofToken
from usb_transaction import UsbTransaction

# Run at increased system frequency
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"core_freq": [600, 800]})

@pytest.fixture
def test_session(ep, address, bus_speed, core_freq):
    start_length = 6
    end_length = start_length + 10
    frameNumber = 0

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(start_length, end_length):

        session.add_event(CreateSofToken(frameNumber))
        frameNumber += 1

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="ISO",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=[42, 21],
                ep_len=8
            )
        )
    if core_freq == 600:
        pytest.xfail("HBW 2txn test requires a 800MHz part")

    return session
