
import sys
import zlib
import random

# In USB clocks
RX_TX_DELAY = 20
RXA_END_DELAY = 2 # Pad delay not currently simulated in xsim for USB or OTP, so add this delay here
RXA_START_DELAY = 5 #Taken from RTL sim
RX_RX_DELAY = 40

PID_DATA1 = 0xb
PID_DATA0 = 0x3



def AppendSetupToken(packets, ep, address, **kwargs):
    ipg = kwargs.pop('inter_pkt_gap', 500)
    address = kwargs.pop('address', 0)
    AppendTokenPacket(packets, 0x2d, ep, ipg, address)

def AppendOutToken(packets, ep, address, **kwargs):
    ipg = kwargs.pop('inter_pkt_gap', 500) 
    AppendTokenPacket(packets, 0xe1, ep, ipg, address)

def AppendPingToken(packets, ep, address, **kwargs):
    ipg = kwargs.pop('inter_pkt_gap', 500) 
    AppendTokenPacket(packets, 0xb4, ep, ipg, address)

def AppendInToken(packets, ep, address, **kwargs):
    #357 was min IPG supported on bulk loopback to not nak
    #lower values mean the loopback NAKs
    ipg = kwargs.pop('inter_pkt_gap', 10) 
    AppendTokenPacket(packets, 0x69, ep, ipg, address)

def AppendSofToken(packets, framenumber, **kwargs):
    ipg = kwargs.pop('inter_pkt_gap', 500) 
    
    # Override EP and Address 
    ep = (framenumber >> 7) & 0xf
    address = (framenumber) & 0x7f
    AppendTokenPacket(packets, 0xa5, ep, ipg, address)

def AppendTokenPacket(packets, _pid, ep, ipg, addr=0):
    
    packets.append(TokenPacket( 
        inter_pkt_gap=ipg, 
        pid=_pid,
        address=addr, 
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

def GenCrc5(args):
    intSize = 32;
    elevenBits = args

    poly5 = (0x05 << (intSize - 5));
    crc5 = (0x1F << (intSize - 5));
    udata = (elevenBits << (intSize - 11));    #crc over 11 bits
  
    iBitcnt = 11;

    while iBitcnt > 0:
        if ((udata ^ crc5) & (0x1 << (intSize - 1))):   #bit4 != bit4?
            crc5 <<= 1;
            crc5 ^= poly5;
        else:
            crc5 <<= 1;
        udata <<= 1;
        iBitcnt = iBitcnt-1

    #Shift back into position
    crc5 >>= intSize - 5;

    #Invert contents to generate crc field
    crc5 ^= 0x1f;
    
    crc5 = reflect(crc5, 5);
    return crc5;


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

class BusReset(object):

    def __init__(self, **kwargs):
        self.duration_ms  = kwargs.pop('duraton', 10) #Duration of reset
        self.bus_speed = kwargs.pop('bus_speed', 'high') #Bus speed to reset into


# Lowest base class for all packets. All USB packets have:
# - a PID
# - some (or none) data bytes
class UsbPacket(object):

    def __init__(self, **kwargs):
        self.pid = kwargs.pop('pid', 0xc3) 
        self.data_bytes = kwargs.pop('data_bytes', None)
        self.num_data_bytes = kwargs.pop('length', 0)
        self.data_valid_count = kwargs.pop('data_valid_count', 0)
        self.bad_crc = kwargs.pop('bad_crc', False)

    def get_data_valid_count(self):
        return self.data_valid_count

    def get_pid_pretty(self):

        if self.pid == 2:
            return "ACK"
        elif self.pid == 225:
            return "OUT"
        elif self.pid == 11:
            return "DATA1"
        elif self.pid == 3:
            return "DATA0"
        elif self.pid == 105:
            return "IN"
        elif self.pid == 180:
            return "PING"
        elif self.pid == 165:
            return "SOF"
        else:
           return "UNKNOWN"


#Rx to host i.e. xCORE Tx
class RxPacket(UsbPacket):

    def __init__(self, **kwargs):
        self.timeout = kwargs.pop('timeout', 25)
        super(RxPacket, self).__init__(**kwargs)

    def get_timeout(self):
        return self.timeout

#Tx from host i.e. xCORE Rx
class TxPacket(UsbPacket):

    def __init__(self, **kwargs):
        self.inter_pkt_gap = kwargs.pop('inter_pkt_gap', RX_RX_DELAY) #13 lowest working for single issue loopback
        self.rxa_start_delay = kwargs.pop('rxa_start_delay', 2)
        self.rxa_end_delay = kwargs.pop('rxa_end_delay', RXA_END_DELAY)
        self.rxe_assert_time = kwargs.pop('rxe_assert_time', 0)
        self.rxe_assert_length = kwargs.pop('rxe_assert_length', 1)
        super(TxPacket, self).__init__(**kwargs)

    def get_inter_pkt_gap(self):
        return self.inter_pkt_gap

# Implemented such that we can generate broken or bad packets
    def get_bytes(self, do_tokens=False):
        print "GET BYTES\n"
        bytes = []
        #if do_tokens:
        #    bytes.append(self.pid)
        #else:
        #    bytes.append(self.pid | ((~self.pid) << 4))
        #    for x in range(len(self.data_bytes)):
        #       bytes.append(self.data_bytes[x])
        return bytes


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

    def get_bytes(self, do_tokens=False):
        
        bytes = []

        if do_tokens:
           bytes.append(self.pid)
        else:
            bytes.append(self.pid | (((~self.pid)&0xf) << 4))

        packet_bytes = self.get_packet_bytes()
        for byte in packet_bytes:
            bytes.append(byte)

        if self.bad_crc == True:
            crc = 0xbeef
        else:    
            crc = self.get_crc(packet_bytes)

        #Append the 2 bytes of CRC onto the packet
        for i in range(0, 2):
            bytes.append((crc >> (8*i)) & 0xff)

        return bytes

class RxDataPacket(RxPacket, DataPacket):
    
    def __init__(self, rand, **kwargs):
        _pid = self.pid = kwargs.pop('pid', 0x3) #DATA0

        #Re-construct full PID - xCORE sends out full PIDn | PID on Tx
        super(RxDataPacket, self).__init__(pid = (_pid & 0xf) | (((~_pid)&0xf) << 4), **kwargs)

class TxDataPacket(DataPacket, TxPacket):

    def __init__(self, rand, **kwargs):
        super(TxDataPacket, self).__init__(**kwargs)
        #self.inter_pkt_gap = kwargs.pop('inter_pkt_gap', 13) #13 lowest working for single issue loopback


#Always TX
class TokenPacket(TxPacket):

    def __init__(self, **kwargs):
        super(TokenPacket, self).__init__(**kwargs)
        self.endpoint = kwargs.pop('endpoint', 0)
        self.valid = kwargs.pop('valid', 1)
        self.address = kwargs.pop('address', 0)
       
        # Generate correct crc5
        crc5 = GenCrc5(reflect(((self.endpoint & 0xf)<<7) | ((self.address & 0x7f)<<0), 11))
        
        # Correct crc5 can be overridden
        self.crc5 = kwargs.pop('crc5', crc5)

        # Always override to match IFM
        #self.data_valid_count = 4 #todo
        self.data_valid_count = 0

    def get_bytes(self, do_tokens=False):
        bytes = []
        
        if do_tokens:
            bytes.append(self.pid & 0xf)
            bytes.append(self.endpoint)
        else:
            bytes.append(self.pid)
           
            tokenbyte0 = self.address | ((self.endpoint & 1) << 7);
            tokenbyte1 = (self.endpoint >> 1) | (self.crc5 << 3)
            
            bytes.append(tokenbyte0);
            bytes.append(tokenbyte1);
        
        return bytes

    # Token valid
    def get_token_valid(self):
        return self.valid

class HandshakePacket(UsbPacket):
    
    def __init__(self, **kwargs):
        super(HandshakePacket, self).__init__(**kwargs)
        self.pid = kwargs.pop('pid', 0x2) #Default to ACK
        
    def get_bytes(self, do_tokens=False):
        bytes = []
        bytes.append(self.pid)
        return bytes

class RxHandshakePacket(HandshakePacket, RxPacket):

    def __init__(self, **kwargs):
        super(RxHandshakePacket, self).__init__(**kwargs)
        self.pid = kwargs.pop('pid', 0xd2) #Default to ACK (not expect inverted bits on Rx)
        self.timeout = kwargs.pop('timeout', RX_TX_DELAY) 
    
 
class TxHandshakePacket(HandshakePacket, TxPacket):
    
    def __init__(self, **kwargs):
        super(TxHandshakePacket, self).__init__(**kwargs)
        
    def get_bytes(self, do_tokens=False):
        bytes = []
        if do_tokens:
            bytes.append(self.pid)
        else:
            bytes.append(self.pid | ((~self.pid) << 4))
        return bytes

