# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import sys
import zlib
import random

def AppendSetupToken(packets, ep, **kwargs):
    ipg = kwargs.pop('inter_pkt_gap', 500) 
    AppendTokenPacket(packets, 0x2d, ep, ipg)

def AppendOutToken(packets, ep, **kwargs):
    ipg = kwargs.pop('inter_pkt_gap', 500) 
    AppendTokenPacket(packets, 0xe1, ep, ipg)

def AppendPingToken(packets, ep, **kwargs):
    ipg = kwargs.pop('inter_pkt_gap', 500) 
    AppendTokenPacket(packets, 0xb4, ep, ipg)

def AppendInToken(packets, ep, **kwargs):

    #357 was min IPG supported on bulk loopback to not nak
    #lower values mean the loopback NAKs
    ipg = kwargs.pop('inter_pkt_gap', 10) 
    AppendTokenPacket(packets, 0x69, ep, ipg)

    
def AppendTokenPacket(packets, _pid, ep, ipg):
    
    packets.append(TokenPacket( 
        inter_pkt_gap=ipg, 
        pid=_pid,
        address=0, 
        endpoint=ep))

def reflect(val, numBits):

    valRef = 0;
    for i in range(numBits):
        valRef <<= 1;
        
        if (val & 1):
            valRef |= 1;
        
        val >>= 1;
    
    return valRef;

def GenCrc16(args):

    data = args
  
    crc = 0xffff;
    poly = 0x8005;

    for byte in  data:
        topBit = 1 << 15;
        crc ^= reflect(int(byte) & int(0xFF), 8) << 8; 

        for k in range(0,8):
            if crc & topBit:
                crc = (crc << 1) ^ poly;
            else:
                crc <<= 1;

    #//crc = crc ^0xffff;
    crc = reflect(crc,16);
    crc = ~crc;
    crc = crc & 0xffff;
    #print "CRC: : {0:#x}".format(crc)
    return crc;

# Functions for creating the data contents of packets
def create_data(args):
    f_name,f_args = args
    func = 'create_data_{}'.format(f_name)
    return globals()[func](f_args)

def create_data_step(args):
    step,num_data_bytes = args
    return [(step * i) & 0xff for i in range(num_data_bytes)]

def create_data_same(args):
    value,num_data_bytes = args
    return [value & 0xff for i in range(num_data_bytes)]


# Functions for creating the expected output that the DUT will print given
# this packet
def create_data_expect(args):
    f_name,f_args = args
    func = 'create_data_expect_{}'.format(f_name)
    return globals()[func](f_args)

def create_data_expect_step(args):
    step,num_data_bytes = args
    return "Step = {0}\n".format(step)

def create_data_expect_same(args):
    value,num_data_bytes = args
    return "Value = {0}\n".format(value)

# Lowest base class for all packets. All USB packets have:
# - a PID
# - some (or none) data bytes
class UsbPacket(object):

    def __init__(self, **kwargs):
        self.pid = kwargs.pop('pid', 0xc3) 
        self.num_data_bytes = kwargs.pop('length', 0)
        self.data_bytes = None
        self.data_valid_count = kwargs.pop('data_valid_count', 0)
        self.bad_crc = kwargs.pop('bad_crc', False)

    def get_data_valid_count(self):
        return self.data_valid_count


#Rx to host i.e. xCORE Tx
class RxPacket(UsbPacket):

    def __init__(self, **kwargs):
        self.timeout = kwargs.pop('timeout', 8)
        super(RxPacket, self).__init__(**kwargs)


    def get_timeout(self):
        return self.timeout

#Tx from host i.e. xCORE Rx
class TxPacket(UsbPacket):

    def __init__(self, **kwargs):
        self.inter_pkt_gap = kwargs.pop('inter_pkt_gap', 13) #13 lowest working for single issue loopback
        self.rxa_start_delay = kwargs.pop('rxa_start_delay', 2)
        self.rxa_end_delay = kwargs.pop('rxa_end_delay', 2)
        self.rxe_assert_time = kwargs.pop('rxe_assert_time', 0)
        self.rxe_assert_length = kwargs.pop('rxe_assert_length', 1)
        super(TxPacket, self).__init__(**kwargs)

    def get_inter_pkt_gap(self):
        return self.inter_pkt_gap

# DataPacket class, inherits from Usb Packet
class DataPacket(UsbPacket):

    def __init__(self, **kwargs):
        super(DataPacket, self).__init__(**kwargs)
        self.pid = kwargs.pop('pid', 0x3) #DATA0
        data_start_val = kwargs.pop('data_start_val', None)

        if data_start_val != None:
            self.data_bytes = [x+data_start_val for x in range(self.num_data_bytes)]
        else:
            self.data_bytes = [x for x in range(self.num_data_bytes)]


    def get_packet_bytes(self):
        packet_bytes = []
        packet_bytes = self.data_bytes
        return packet_bytes
    
    def get_crc(self, packet_bytes):
        crc = GenCrc16(packet_bytes)   
        return crc

    def get_bytes(self):
        bytes = []

        bytes.append(self.pid)

        packet_bytes = self.get_packet_bytes()
        for byte in packet_bytes:
            bytes.append(byte)

        if self.bad_crc == True:
            crc = 0xbeef
        else:    
            crc = self.get_crc(packet_bytes)

        # Append the 2 bytes of CRC onto the packet
        for i in range(0, 2):
            bytes.append((crc >> (8*i)) & 0xff)

        return bytes


class RxDataPacket(RxPacket, DataPacket):
    
    def __init__(self, rand, **kwargs):
        _pid = self.pid = kwargs.pop('pid', 0x3) #DATA0

        #Re-construct full PID - xCORE sends out full PIDn | PID on Tx
        super(RxDataPacket, self).__init__(pid = (_pid & 0xf) | (((~_pid)&0xf) << 4), **kwargs)

class TxDataPacket(TxPacket, DataPacket):

    def __init__(self, rand, **kwargs):
        super(TxDataPacket, self).__init__(**kwargs)
        #self.inter_pkt_gap = kwargs.pop('inter_pkt_gap', 13) #13 lowest working for single issue loopback


#Always TX
class TokenPacket(TxPacket):

    def __init__(self, **kwargs):
        super(TokenPacket, self).__init__(**kwargs)
        self.endpoint = kwargs.pop('endpoint', 0)
        self.valid = kwargs.pop('valid', 1)
 
        # Always override to match IFM
        self.data_valid_count = 4 #todo

    def get_bytes(self):
        bytes = []
        bytes.append(self.pid & 0xf)
        bytes.append(self.endpoint)
        return bytes

    # Token valid
    def get_token_valid(self):
        return self.valid

class HandshakePacket(UsbPacket):
    
    def __init__(self, **kwargs):
        super(HandshakePacket, self).__init__(**kwargs)
        self.pid = kwargs.pop('pid', 0x2) #Default to ACK

    def get_bytes(self):
        bytes = []
        bytes.append(self.pid)
        return bytes

class RxHandshakePacket(HandshakePacket, RxPacket):

    def __init__(self, **kwargs):
        super(RxHandshakePacket, self).__init__(**kwargs)
        self.pid = kwargs.pop('pid', 0xd2) #Default to ACK (not expect inverted bits on Rx)
        self.timeout = kwargs.pop('timeout', 9) 

class TxHandshakePacket(HandshakePacket, TxPacket):
    
    def __init__(self, **kwargs):
        super(TxHandshakePacket, self).__init__(**kwargs)

