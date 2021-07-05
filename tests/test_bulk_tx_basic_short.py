# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest
from conftest import PARAMS, test_RunUsbSession


@pytest.fixture
def test_session(ep, address, bus_speed, dummy_threads):

    start_length = 0
    end_length = 7

    # if dummy_threads > 3 and bus_speed == "HS":
    #    pytest.xfail("Known failure dummy thread > 3 @ HS")

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(start_length, end_length + 1):
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="BULK",
                direction="IN",
                dataLength=pktLength,
            )
        )

    return session
