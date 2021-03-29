
from usb_event import UsbEvent
from usb_packet import USB_PID, TokenPacket, TxDataPacket, RxHandshakePacket
from usb_phy import USB_DATA_VALID_COUNT

INTER_TRANSACTION_DELAY = 500


def CounterByte(length = 0):
    l = 0
    while l < length:
        yield l % 256
        l += 1

class UsbTransaction(UsbEvent):

    def __init__(self, deviceAddress = 0, endpointNumber = 0, endpointType = "BULK", 
            direction="OUT", bus_speed="HS", eventTime = 0, dataLength = 0, data_fn = CounterByte): # TODO Enums when we move to py3
        
        self._deviceAddress = deviceAddress
        self._endpointNumber = endpointNumber
        self._endpointType = endpointType
        self._direction = direction
        self._datalength = dataLength
        self._bus_speed = bus_speed
        

        dataValidCount = USB_DATA_VALID_COUNT[self.bus_speed]

        # Populate packet list for a (valid) transaction 
        self._packets = []
        self._packets.append(TokenPacket(interPktGap = INTER_TRANSACTION_DELAY, 
                                        pid = USB_PID["OUT"], 
                                        address = self._deviceAddress, 
                                        endpoint = self._endpointNumber,
                                        data_valid_count = dataValidCount))

        # Generate packet data payload
        packetPayload = [x for x in data_fn(dataLength)]

        # TODO FIXME
        pid = USB_PID["DATA0"];

        # Add data packet to packets list 
        self._packets.append(TxDataPacket(pid=pid, dataPayload = packetPayload))
        
        # Add handshake packet to packets list
        self._packets.append(RxHandshakePacket())
        
        super(UsbTransaction, self).__init__(time = eventTime)
        

    @property
    def endpointAddress(self):
        return self._endpointAddress

    @property
    def endpointType(self):
        return self._endpointType

    @property
    def packets(self):
        return self._packets

    @property
    def bus_speed(self):
        return self._bus_speed

    @bus_speed.setter
    def bus_speed(self, bus_speed):
        self._bus_speed = bus_speed

    @property
    def event_count(self):
        eventCount = 0
        
        # We should be able to do len(packets) but lets just be sure..
        for p in self.packets:
            eventCount += p.event_count
       
        # Sanity check
        assert eventCount == len(self.packets)

        return eventCount
    
    def expected_output(self, offset):
        expected_output = ""
        
        for i, p in enumerate(self.packets):
            expected_output += "Packet {}: ".format(i+offset) 
            expected_output += p.expected_output
            expected_output += "\n"

        return expected_output        

    def __str__(self):
        s = "UsbTransaction:\n"
        for p in self.packets:
           s += "\t" + str(p) + "\n"
        return s

    # PID: Packet ID
