# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import TokenPacket, RxDataPacket, TxHandshakePacket, USB_PID
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    pktLength = 10
    ied = 4000

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(10, 14):

        if pktLength == 12:
            session.add_event(
                TokenPacket(
                    pid=USB_PID["IN"],
                    address=address,
                    endpoint=ep,
                    interEventDelay=ied,
                )
            )
            session.add_event(
                RxDataPacket(
                    dataPayload=session.getPayload_in(ep, pktLength, resend=True),
                    pid=USB_PID["DATA0"],
                )
            )
            session.add_event(TxHandshakePacket(pid=0xFF))

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

    return session
