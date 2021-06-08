#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest
from usb_packet import *
import usb_packet
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction


def test(arch, clk, phy, usb_speed, seed, verbose=False):

    address = 1
    ep = 1

    # The large inter-event delays are to give the DUT time to do checking on the fly

    session = UsbSession(
        bus_speed=usb_speed, run_enumeration=False, device_address=address
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

    # Another valid OUT transaction
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

    # OUT transaction with bad data CRC
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=12,
            interEventDelay=6000,
            badDataCrc=True,
        )
    )

    # Due to bad CRC, XUD will not ACK and expect a resend of the same packet - DATA PID won't be toggled
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

    # PID will be toggled as normal
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
        verbose=verbose,
    )


def runtest():
    RunUsbTest(test)
