# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    # Large inter-event delay is to give the DUT time to perform checking
    ied = 6000

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # Valid OUT transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=10,
        )
    )

    # Assert RxError during packet
    # xCORE should ignore the packet and not handshake...
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=11,
            interEventDelay=ied,
            rxeAssertDelay_data=5,
        )
    )

    # Re-send..
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=11,
            interEventDelay=ied,
        )
    )

    # Valid OUT transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=12,
            interEventDelay=ied,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=13,
            interEventDelay=ied,
            rxeAssertDelay_data=1,
        )
    )

    # Re-send
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=13,
            interEventDelay=ied,
        )
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=14,
            interEventDelay=ied,
        )
    )

    return session
