#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest
from usb_packet import (
    TokenPacket,
    TxDataPacket,
    RxDataPacket,
    TxHandshakePacket,
    RxHandshakePacket,
    USB_PID,
)
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction

# Same as simple RX bulk test but some invalid tokens also included


def do_test(arch, clk, phy, usb_speed, seed, verbose=False):

    address = 1
    ep = 1

    session = UsbSession(
        bus_speed=usb_speed, run_enumeration=False, device_address=address
    )

    # Reserved/Invalid PID
    session.add_event(
        TokenPacket(
            pid=USB_PID["RESERVED"],
            address=address,
            endpoint=ep,
        )
    )

    # Valid IN but not for DUT
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address + 1,
            endpoint=ep,
        )
    )

    # Valid OUT but not for DUT
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address + 1,
            endpoint=ep,
        )
    )

    # Valid OUT transaction
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=10,
        )
    )

    # Valid SETUP but not for us..
    session.add_event(
        TokenPacket(
            pid=USB_PID["SETUP"],
            address=address + 2,
            endpoint=ep,
        )
    )

    # Valid OUT transaction
    # Note, quite big gap to allow checking.
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=11,
            interEventDelay=6000,
        )
    )

    # Valid PING but not for us..
    session.add_event(
        TokenPacket(
            pid=USB_PID["PING"],
            address=address + 2,
            endpoint=ep,
        )
    )

    # Finish with some valid transactions
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=12,
            interEventDelay=6000,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=13,
            interEventDelay=6000,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=14,
            interEventDelay=6000,
        )
    )

    do_usb_test(
        arch,
        clk,
        phy,
        usb_speed,
        [session],
        __file__,
        seed,
        level="smoke",
        extra_tasks=[],
    )


def runtest():
    RunUsbTest(do_test)
