# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from copy import deepcopy

import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction

# EP numbers currently fixed for this test - set in params
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"ep": [3], "dummy_threads": [0]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    ied = 200

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(10, 20):
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="BULK",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep + 1,
                endpointType="BULK",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep + 2,
                endpointType="BULK",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep + 3,
                endpointType="BULK",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=ied,
            )
        )

    return session
