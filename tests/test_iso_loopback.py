#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_packet import *
import usb_packet
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest


def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    ep_loopback = 3
    ep_loopback_kill = 2
    address = 1
    start_length = 200
    end_length = 203
    session = UsbSession(
        bus_speed=usb_speed, run_enumeration=False, device_address=address
    )

    # TODO randomise packet lengths and data
    for pktLength in range(start_length, end_length + 1):
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep_loopback,
                endpointType="ISO",
                direction="OUT",
                dataLength=pktLength,
            )
        )

        # Was min IPG supported on iso loopback to not nak
        # This was 420, had to increase when moved to lib_xud (14.1.2 tools)
        # increased again from 437 when SETUP/OUT checking added
        # increaed from 477 when adding xs3
        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep_loopback,
                endpointType="ISO",
                direction="IN",
                dataLength=pktLength,
                interEventDelay=498,
            )
        )

    pktLength = 10

    # Loopback and die..
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_loopback_kill,
            endpointType="BULK",
            direction="OUT",
            dataLength=pktLength,
        )
    )
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep_loopback_kill,
            endpointType="BULK",
            direction="IN",
            dataLength=pktLength,
        )
    )

    return do_usb_test(
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


def test_iso_loopback():
    for result in RunUsbTest(do_test):
        assert result
