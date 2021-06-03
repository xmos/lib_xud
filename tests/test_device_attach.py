#!/usr/bin/env python
# Copyright 2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import xmostest
import usb_packet
from usb_packet import CreateSofToken
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_signalling import UsbDeviceAttach


def do_test(arch, clk, phy, usb_speed, seed, verbose=False):

    ep = 1
    address = 1
    start_length = 10
    end_length = 12
    pktLength = 10
    frameNumber = 52  # Note, for frame number 52 we expect A5 34 40 on the bus

    session = UsbSession(
        bus_speed=usb_speed, run_enumeration=False, device_address=address
    )

    session.add_event(UsbDeviceAttach())

    session.add_event(CreateSofToken(frameNumber))

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=pktLength,
            interEventDelay=0,
        )
    )

    frameNumber = frameNumber + 1
    pktLength = pktLength + 1

    session.add_event(CreateSofToken(frameNumber))
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            direction="OUT",
            dataLength=pktLength,
            interEventDelay=0,
        )
    )

    phy.initial_delay = 19000

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
    RunUsbTest(do_test)
