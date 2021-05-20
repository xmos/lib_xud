# Copyright 2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.rom usb_event import UsbEvent
from usb_packet import (
    USB_PID,
    TokenPacket,
    TxDataPacket,
    RxHandshakePacket,
    RxDataPacket,
    TxHandshakePacket,
)
from usb_phy import USB_DATA_VALID_COUNT

INTER_TRANSACTION_DELAY = 500

USB_DIRECTIONS = ["OUT", "IN"]
USB_EP_TYPES = ["CONTROL", "BULK", "ISO", "INTERRUPT"]

# TODO UsbTransaction_IN and UsbTransaction_OUT
class UsbTransaction(UsbEvent):
    def __init__(
        self,
        session,
        deviceAddress=0,
        endpointNumber=0,
        endpointType="BULK",
        direction="OUT",
        bus_speed="HS",
        eventTime=0,
        dataLength=0,
        interEventDelay=INTER_TRANSACTION_DELAY,
        badDataCrc=False,
        resend=False,
        rxeAssertDelay_data=0,
    ):  # TODO Enums when we move to py3

        self._deviceAddress = deviceAddress
        self._endpointNumber = endpointNumber
        self._endpointType = endpointType
        self._direction = direction
        self._datalength = dataLength
        self._bus_speed = bus_speed
        self._badDataCrc = badDataCrc
        self._rxeAssertDelay_data = rxeAssertDelay_data

        assert endpointType in USB_EP_TYPES
        assert direction in USB_DIRECTIONS

        # Populate packet list for a (valid) transaction
        self._packets = []

        # TODO would it be better to generate packets on the fly in drive() rather than create a packet list?
        if direction == "OUT":

            packets = []
            packets.append(
                TokenPacket(
                    interEventDelay=interEventDelay,
                    pid=USB_PID["OUT"],
                    address=self._deviceAddress,
                    endpoint=self._endpointNumber,
                    data_valid_count=self.data_valid_count,
                )
            )

            # Don't toggle data pid if we had a bad data crc
            if self._badDataCrc or self._rxeAssertDelay_data or endpointType == "ISO":
                togglePid = False
            else:
                togglePid = True

            if (
                (not self._badDataCrc)
                and (not self._rxeAssertDelay_data)
                and (deviceAddress == session.deviceAddress)
                and (self._endpointType != "ISO")
            ):
                expectHandshake = True
            else:
                expectHandshake = False

            if expectHandshake or self._endpointType == "ISO":
                resend = False
            else:
                resend = True

            # Generate packet data payload
            packetPayload = session.getPayload_out(
                endpointNumber, dataLength, resend=resend
            )

            pid = session.data_pid_out(endpointNumber, togglePid=togglePid)

            # Add data packet to packets list
            packets.append(
                TxDataPacket(
                    pid=pid,
                    dataPayload=packetPayload,
                    bad_crc=self._badDataCrc,
                    rxe_assert_time=self._rxeAssertDelay_data,
                )
            )

            if expectHandshake:
                packets.append(RxHandshakePacket())

            self._packets.extend(packets)

        else:

            self._packets.append(
                TokenPacket(
                    interEventDelay=interEventDelay,
                    pid=USB_PID["IN"],
                    address=self._deviceAddress,
                    endpoint=self._endpointNumber,
                    data_valid_count=self.data_valid_count,
                )
            )

            # Generate packet data payload
            packetPayload = session.getPayload_in(endpointNumber, dataLength)

            if (
                self._badDataCrc
                or self._rxeAssertDelay_data
                or self._endpointType == "ISO"
            ):
                togglePid = False
            else:
                togglePid = True

            pid = session.data_pid_in(endpointNumber, togglePid=togglePid)

            # Add data packet to packets list
            self._packets.append(RxDataPacket(pid=pid, dataPayload=packetPayload))

            if self._endpointType != "ISO":
                self._packets.append(TxHandshakePacket())

        super(UsbTransaction, self).__init__(
            time=eventTime, interEventDelay=interEventDelay
        )

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

    def expected_output(self, bus_speed, offset=0):
        expected_output = ""

        for i, p in enumerate(self.packets):
            expected_output += p.expected_output(bus_speed)

        return expected_output

    def __str__(self):
        s = "UsbTransaction:\n"
        for p in self.packets:
            s += "\t" + str(p) + "\n"
        return s

    def drive(self, usb_phy, bus_speed):
        for i, p in enumerate(self.packets):
            p.drive(usb_phy, bus_speed)
