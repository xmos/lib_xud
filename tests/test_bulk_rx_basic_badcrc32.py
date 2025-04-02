# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    # Rx -> Tx, recieving OUT handshake -> sending OUT tok
    ied_out = 19
    # one of the OUTs doesn't pass with 19
    ied_out1 = 20
    # Tx -> Tx, sent bad crc DATA, didn't get ACK -> sending OUT tok
    ied_out_badcrc = 8

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

    # Another valid OUT transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=11,
            interEventDelay=ied_out,
        )
    )

    # OUT transaction with bad data CRC
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=12,
            interEventDelay=ied_out,
            badDataCrc=True,
        )
    )

    # Due to bad CRC, XUD will not ACK and expect a resend of the same
    # packet - DATA PID won't be toggled
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=12,
            interEventDelay=ied_out_badcrc,
        )
    )

    # PID will be toggled as normal
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=13,
            interEventDelay=ied_out1,
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
            interEventDelay=ied_out,
        )
    )

    return session
