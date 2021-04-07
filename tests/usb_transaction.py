
from usb_event import UsbEvent
from usb_packet import USB_PID, TokenPacket, TxDataPacket, RxHandshakePacket, RxDataPacket, TxHandshakePacket
from usb_phy import USB_DATA_VALID_COUNT

INTER_TRANSACTION_DELAY = 500

USB_DIRECTIONS=["OUT", "IN"]
USB_EP_TYPES=["CONTROL", "BULK", "ISO", "INTERRUPT"]

class UsbTransaction(UsbEvent):

    def __init__(self, session, deviceAddress = 0, endpointNumber = 0, endpointType = "BULK", 
            direction="OUT", bus_speed="HS", eventTime = 0, dataLength = 0, interEventDelay=500): # TODO Enums when we move to py3
        
        self._deviceAddress = deviceAddress
        self._endpointNumber = endpointNumber
        self._endpointType = endpointType
        self._direction = direction
        self._datalength = dataLength
        self._bus_speed = bus_speed

        assert endpointType in USB_EP_TYPES
        assert direction in USB_DIRECTIONS

        # Populate packet list for a (valid) transaction 
        self._packets = []
       
        if direction == "OUT":
            self._packets.append(TokenPacket(interEventDelay = INTER_TRANSACTION_DELAY, 
                                        pid = USB_PID["OUT"], 
                                        address = self._deviceAddress, 
                                        endpoint = self._endpointNumber,
                                        data_valid_count = self.data_valid_count))

            # Generate packet data payload
            packetPayload = session.getPayload_out(endpointNumber, dataLength);

            pid = session.data_pid_out(endpointNumber);

            # Add data packet to packets list 
            self._packets.append(TxDataPacket(pid=pid, dataPayload = packetPayload))
        
            # Add handshake packet to packets list
            self._packets.append(RxHandshakePacket())
        
        else: 
            self._packets.append(TokenPacket(interEventDelay = INTER_TRANSACTION_DELAY, 
                                        pid = USB_PID["IN"], 
                                        address = self._deviceAddress, 
                                        endpoint = self._endpointNumber,
                                        data_valid_count = self.data_valid_count))

            # Generate packet data payload
            packetPayload = session.getPayload_in(endpointNumber, dataLength);

            pid = session.data_pid_in(endpointNumber);

            # Add data packet to packets list 
            self._packets.append(RxDataPacket(pid=pid, dataPayload = packetPayload))
        
            self._packets.append(TxHandshakePacket())


        


        super(UsbTransaction, self).__init__(time = eventTime, interEventDelay = interEventDelay)
    
    # TODO ideally USBTransaction doesnt know about data_valid_count
    @property
    def data_valid_count(self):
        return USB_DATA_VALID_COUNT[self.bus_speed]

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
    
    def expected_output(self, offset=0):
        expected_output = ""
        
        for i, p in enumerate(self.packets):
            #expected_output += "Packet {}: ".format(i+offset) 
            expected_output += "Packet:"
            expected_output += "\t" + p.expected_output
            #expected_output += "\n"

        return expected_output        

    def __str__(self):
        s = "UsbTransaction:\n"
        for p in self.packets:
           s += "\t" + str(p) + "\n"
        return s

    def drive(self, xsi):
        for i, p in enumerate(self.packets):
            p.drive(xsi)

