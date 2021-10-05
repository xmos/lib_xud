# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import TokenPacket, USB_PID

# Rx out of seq (but valid.. ) data PID


@pytest.fixture
def test_session(ep, address, bus_speed, core_freq, dummy_threads):

    total_threads = dummy_threads + 2  # 1 thread for xud another for test code
    if (core_freq / total_threads < 100.0) and bus_speed == "HS":
        pytest.xfail("Test doesn't pass without 100MIPS (issue #277)")

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
                transType="OUT",
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
