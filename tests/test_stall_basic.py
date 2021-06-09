#!/usr/bin/env python
# Copyright 2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import xmostest
from usb_packet import *
import usb_packet
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_phy import USB_MAX_EP_ADDRESS


def do_test(arch, clk, phy, usb_speed, seed, verbose=False):

    stalled_eps_out = [0, 2, 4]
    stalled_eps_in = [0, 1, 3]
    max_ep = 4
    address = 1
    pktLenfth = 10

    session = UsbSession(
        bus_speed=usb_speed, run_enumeration=False, device_address=address
    )

    for ep in range(1):

        halted = False
        if ep in stalled_eps_out:
            halted = True

        session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="BULK",
                direction="OUT",
                dataLength=pktLength,
                halted = halted,
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
    RunUsbTest(do_test)
