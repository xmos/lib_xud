# Copyright 2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from copy import deepcopy

import pytest
import random

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction

# EP numbers currently fixed for this test - set in params
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"ep": [3]})


@pytest.fixture
def test_session(ep, address, bus_speed):

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    testEpCount = 3
    pktLength_start = 10
    pktLength_end = 19
    interEventDelay = 100
    maxEp = ep + testEpCount - 1

    pktLength = [pktLength_start] * testEpCount

    while True:

        transEp = random.randint(ep, maxEp)

        transPktLength = pktLength[transEp - ep]
        pktLength[transEp - ep] += 1

        if transPktLength <= pktLength_end:

            session.add_event(
                UsbTransaction(
                    session,
                    deviceAddress=address,
                    endpointNumber=transEp,
                    endpointType="BULK",
                    transType="OUT",
                    dataLength=transPktLength,
                    interEventDelay=interEventDelay,
                )
            )

        if all(length > pktLength_end for length in pktLength):
            break

    return session
