#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_packet import (
    TokenPacket,
    TxDataPacket,
    RxDataPacket,
    TxHandshakePacket,
    RxHandshakePacket,
    USB_PID,
)
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest
from conftest import PARAMS, test_RunUsbSession

# TODO Can this be moved?
@pytest.fixture
def test_file():
    return __file__


@pytest.fixture
def test_session(ep, address, bus_speed):

    ep = 0
    address = 1
    ied = 500

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # SETUP transaction
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=address,
            endpoint=ep,
        )
    )
    session.add_event(
        TxDataPacket(
            dataPayload=session.getPayload_out(ep, 8),
            pid=USB_PID["DATA0"],
        )
    )
    session.add_event(RxHandshakePacket())

    # IN transaction
    # Note, quite big gap to avoid nak
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
            interEventDelay=10000,
        )
    )
    session.add_event(
        RxDataPacket(
            dataPayload=session.getPayload_in(ep, 10),
            pid=USB_PID["DATA1"],
        )
    )
    session.add_event(TxHandshakePacket())

    # Send 0 length OUT transaction
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"], address=address, endpoint=ep, interEventDelay=ied
        )
    )
    session.add_event(TxDataPacket(length=0, pid=USB_PID["DATA1"]))
    session.add_event(RxHandshakePacket())

    return session
