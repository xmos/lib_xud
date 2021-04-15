#!/usr/bin/env python

# Basic check of PING functionality

import xmostest
from usb_packet import TokenPacket, TxDataPacket, RxDataPacket, TxHandshakePacket, RxHandshakePacket, USB_PID 
from helpers import do_usb_test, RunUsbTest
from usb_session import UsbSession
from usb_transaction import UsbTransaction


def do_test(arch, clk, phy, data_valid_count, usb_speed, seed, verbose=False):

    address = 1
    ep = 1

    session = UsbSession(bus_speed=usb_speed, run_enumeration=False, device_address=address)

    # Ping EP 2, expect NAK
    session.add_event(TokenPacket(pid=USB_PID['PING'], address=address, endpoint=2, data_valid_count=data_valid_count))
    session.add_event(RxHandshakePacket(data_valid_count=data_valid_count, pid=USB_PID['NAK']))

    # And again
    session.add_event(TokenPacket(pid=USB_PID['PING'], address=address, endpoint=2, data_valid_count=data_valid_count))
    session.add_event(RxHandshakePacket(data_valid_count=data_valid_count, pid=USB_PID['NAK']))

    # Send packet to EP 1, xCORE should mark EP 2 as ready
    session.add_event(UsbTransaction(session, deviceAddress=address, endpointNumber=ep, endpointType="BULK", direction="OUT", dataLength=10))
    
    # Ping EP 2 again - expect ACK
    session.add_event(TokenPacket(pid=USB_PID['PING'], address=address, endpoint=2, data_valid_count=data_valid_count, interEventDelay=6000))
    session.add_event(RxHandshakePacket(data_valid_count=data_valid_count, pid=USB_PID['ACK']))

    # And again..
    session.add_event(TokenPacket(pid=USB_PID['PING'], address=address, endpoint=2, data_valid_count=data_valid_count, interEventDelay=6000))
    session.add_event(RxHandshakePacket(data_valid_count=data_valid_count, pid=USB_PID['ACK']))

    # Send out to EP 2.. expect ack
    session.add_event(UsbTransaction(session, deviceAddress=address, endpointNumber=2, endpointType="BULK", direction="OUT", dataLength=10, interEventDelay=6000))

    # Re-Ping EP 2, expect NAK
    session.add_event(TokenPacket(pid=USB_PID['PING'], address=address, endpoint=2, data_valid_count=data_valid_count))
    session.add_event(RxHandshakePacket(data_valid_count=data_valid_count, pid=USB_PID['NAK']))

    # And again
    session.add_event(TokenPacket(pid=USB_PID['PING'], address=address, endpoint=2, data_valid_count=data_valid_count))
    session.add_event(RxHandshakePacket(data_valid_count=data_valid_count, pid=USB_PID['NAK']))

    # Send a packet to EP 1 so the DUT knows it can exit. 
    session.add_event(UsbTransaction(session, deviceAddress=address, endpointNumber=ep, endpointType="BULK", direction="OUT", dataLength=10))
   
    do_usb_test(arch, clk, phy, usb_speed, [session], __file__, seed, level='smoke', extra_tasks=[])

def runtest():
    RunUsbTest(do_test)
