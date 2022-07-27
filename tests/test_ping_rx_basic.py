#!/usr/bin/env python
# Copyright 2016-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

# Basic check of PING functionality
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import (
    TokenPacket,
    RxHandshakePacket,
    USB_PID,
)
from usb_session import UsbSession
from usb_transaction import UsbTransaction


@pytest.fixture
def test_session(ep, address, bus_speed):

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # Ping test EP, expect NAK
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
            interEventDelay=500,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["NAK"]))

    # And again
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
            interEventDelay=500,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["NAK"]))

    # Send packet to "ctrl" EP, DUT should mark test EP as ready
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep + 1,
            endpointType="BULK",
            transType="OUT",
            dataLength=10,
            interEventDelay=500,
        )
    )

    # Ping test EP again - expect ACK
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
            interEventDelay=6000,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["ACK"]))

    # And again..
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
            interEventDelay=6000,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["ACK"]))

    # Send out to EP 2.. expect ack
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=10,
            interEventDelay=6000,
        )
    )

    # Re-Ping EP 2, expect NAK
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
            interEventDelay=500,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["NAK"]))

    # And again
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address,
            endpoint=ep,
            interEventDelay=500,
        )
    )
    session.add_event(RxHandshakePacket(pid=USB_PID["NAK"]))

    # Send a packet to "ctrl" EP so the DUT knows it can exit.
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep + 1,
            endpointType="BULK",
            transType="OUT",
            dataLength=10,
            interEventDelay=500,
        )
    )

    return session
