#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_packet import USB_PID, TokenPacket, RxDataPacket
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction
import pytest


def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    ep = 1
    address = 1

    # Note, quite big gap to allow checking
    ied = 4000

    session = UsbSession(
        bus_speed=usb_speed, run_enumeration=False, device_address=address
    )

    for pktLength in range(10, 14):

        if pktLength == 12:
            session.add_event(
                TokenPacket(
                    pid=USB_PID["IN"],
                    address=address,
                    endpoint=ep,
                    data_valid_count=data_valid_count,
                    inter_pkt_gap=ied,
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
                direction="IN",
                dataLength=pktLength,
                interEventDelay=ied,
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


def test_bulk_tx_noack():
    for result in RunUsbTest(do_test):
        assert result
