#!/usr/bin/env python
import random
import xmostest
from  usb_packet import *
import usb_packet
from helpers import do_usb_test, runall_rx
from usb_session import UsbSession
from usb_transaction import UsbTransaction

def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):
    rand = random.Random()
    rand.seed(seed)

    ep = 1
    address = 1
    start_length = 10
    end_length = 19
    
    session = UsbSession(bus_speed = usb_speed, run_enumeration = False, device_address = address)

    for pktLength in range(10, end_length+1):
        session.add_event(UsbTransaction(session, deviceAddress = address, endpointNumber=ep, endpointType="BULK", direction= "IN", eventTime=10, dataLength=pktLength))

    do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[], verbose=verbose)

def runtest():
    random.seed(1)
    runall_rx(do_test)
