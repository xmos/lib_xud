# Copyright 2016-2024 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import TokenPacket, TxDataPacket, RxHandshakePacket, USB_PID
from usb_phy import USB_PKT_TIMINGS
import pytest
from conftest import PARAMS, test_RunUsbSession


@pytest.fixture
def test_session(ep, address, bus_speed):

    pktLength = 10

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
        )
    )

    # Expect NAK's from DUT
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
            interEventDelay = USB_PKT_TIMINGS["RX_TO_TX_PACKET_DELAY"]
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["NAK"]))

    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
            interEventDelay = USB_PKT_TIMINGS["RX_TO_TX_PACKET_DELAY"]
        )
    )

    session.add_event(
        TxDataPacket(
            dataPayload=session.getPayload_out(ep, pktLength),
            pid=USB_PID["DATA0"],
        )
    )

    session.add_event(RxHandshakePacket(pid=USB_PID["NAK"]))

    return session
