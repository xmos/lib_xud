# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import USB_PID, TokenPacket, RxDataPacket
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    # Tx -> Tx, sent hanshake after IN -> sending IN tok
    ied = 24
    # Rx -> Tx, got data from teh device but have not sent an ACK
    # so device must timeout first before beimg able to recieve
    # a new token, TODO: verify this time for FS
    ied_timeout = 99

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(10, 15):

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
                    dataPayload=session.getPayload_in(ep, pktLength, resend=True)
                )
            )
            # Missing ACK - simulate CRC fail at host

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="BULK",
                transType="IN",
                dataLength=pktLength,
                interEventDelay=ied_timeout,
            )
        )

    return session
