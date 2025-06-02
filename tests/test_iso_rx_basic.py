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
def test_session(ep, address, bus_speed, hbw_support, core_freq):
    if hbw_support == "hbw_on" and core_freq == 600:
        pytest.xfail("To keep the same interTransactionDelay as when hbw_off, this needs to run at 800MHz")

    # Not skipping the hbw_off + 800MHz case since the extended config actually does test both 600 and 800

    start_length = 10
    end_length = start_length + 4

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    frameNumber = 0
    interTransactionDelay = 25

    for pktLength in range(start_length, end_length + 1):
        if hbw_support == "hbw_on":
            session.add_event(CreateSofToken(frameNumber, interEventDelay=10))
            frameNumber += 1
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="ISO",
                transType="OUT",
                dataLength=pktLength,
                interEventDelay=interTransactionDelay
            )
        )

    return session
