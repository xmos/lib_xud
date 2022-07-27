# Copyright 2021-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from usb_event import UsbEvent
from usb_packet import (
    USB_PID,
    TokenPacket,
    TxDataPacket,
    RxHandshakePacket,
    RxDataPacket,
    TxHandshakePacket,
    USB_DATA_VALID_COUNT,
)
from usb_phy import USB_PKT_TIMINGS

USB_TRANS_TYPES = ["OUT", "IN", "SETUP"]
USB_EP_TYPES = ["CONTROL", "BULK", "ISO", "INTERRUPT"]

INTER_TRANSACTION_DELAY = USB_PKT_TIMINGS["TX_TO_TX_PACKET_DELAY"]

# TODO UsbTransaction_IN and UsbTransaction_OUT
class UsbTransaction(UsbEvent):
    def __init__(
        self,
        session,
        deviceAddress=0,
        endpointNumber=0,
        endpointType="BULK",
        transType="OUT",
        bus_speed="HS",
        eventTime=0,
        dataLength=0,
        interEventDelay=INTER_TRANSACTION_DELAY,
        badDataCrc=False,
        resend=False,
        rxeAssertDelay_data=0,
        halted=False,
        resetDataPid=False,
        nacking=False,
    ):

        self._deviceAddress = deviceAddress
        self._endpointNumber = endpointNumber
        self._endpointType = endpointType
        self._transType = transType
        self._datalength = dataLength
        self._bus_speed = bus_speed
        self._badDataCrc = badDataCrc
        self._rxeAssertDelay_data = rxeAssertDelay_data
        self._halted = halted
        self._nacking = nacking

        assert endpointType in USB_EP_TYPES
        assert transType in USB_TRANS_TYPES

        # Populate packet list for a (valid) transaction
        self._packets = []

        # TODO would it be better to generate packets on the fly in drive()
        # rather than create a packet list?
        if transType in ["OUT", "SETUP"]:

            packets = []
            packets.append(
                TokenPacket(
                    interEventDelay=interEventDelay,
                    pid=USB_PID[transType],
                    address=self._deviceAddress,
                    endpoint=self._endpointNumber,
                    data_valid_count=self.data_valid_count,
                )
            )

            # Don't toggle data pid if we had a bad data crc
            if (
                self._badDataCrc
                or self._rxeAssertDelay_data
                or endpointType == "ISO"
                or halted
                or resend
            ):
                togglePid = False
            else:
                togglePid = True

            expectHandshake = (
                (not self._badDataCrc)
                and (not self._rxeAssertDelay_data)
                and (deviceAddress == session.deviceAddress)
                and (self._endpointType != "ISO")
            )

            if expectHandshake or self._endpointType == "ISO":
                needResend = False
            else:
                needResend = True

            if halted:
                resetDataPid = True
                needResend = True

            resend = resend or needResend

            # Generate packet data payload
            packetPayload = session.getPayload_out(
                endpointNumber, dataLength, resend=resend
            )

            # Reset data PID's on SETUP transaction
            if transType == "SETUP":
                pid = session.data_pid_out(
                    endpointNumber, togglePid=True, resetDataPid=True
                )

                # If SETUP trans then we need to reset and toggle the corresponding IN EP's PID also
                in_pid = session.data_pid_in(
                    endpointNumber, togglePid=True, resetDataPid=True
                )
            else:
                pid = session.data_pid_out(
                    endpointNumber, togglePid=togglePid, resetDataPid=resetDataPid
                )

            # Add data packet to packets list
            packets.append(
                TxDataPacket(
                    pid=pid,
                    dataPayload=packetPayload,
                    bad_crc=self._badDataCrc,
                    rxe_assert_time=self._rxeAssertDelay_data,
                )
            )

            # Note precedence of halted here
            if expectHandshake:
                if self._halted:
                    packets.append(RxHandshakePacket(pid=USB_PID["STALL"]))
                elif self._nacking:
                    packets.append(RxHandshakePacket(pid=USB_PID["NAK"]))
                else:
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

            if (
                self._badDataCrc
                or self._rxeAssertDelay_data
                or self._endpointType == "ISO"
                or self._halted
                or self._nacking
            ):
                togglePid = False
            else:
                togglePid = True

            if halted:
                resetDataPid = True

            pid = session.data_pid_in(
                endpointNumber, togglePid=togglePid, resetDataPid=resetDataPid
            )

            # Add data packet to packets list
            if not halted and not self._nacking:
                # Generate packet data payload
                packetPayload = session.getPayload_in(endpointNumber, dataLength)
                self._packets.append(RxDataPacket(pid=pid, dataPayload=packetPayload))

            if self._endpointType != "ISO":

                if self._halted:
                    self._packets.append(RxHandshakePacket(pid=USB_PID["STALL"]))
                elif self._nacking:
                    self._packets.append(RxHandshakePacket(pid=USB_PID["NAK"]))
                else:
                    self._packets.append(TxHandshakePacket())

        super().__init__(time=eventTime)

    # TODO ideally USBTransaction doesnt know about data_valid_count
    @property
    def data_valid_count(self):
        return USB_DATA_VALID_COUNT[self.bus_speed]

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

        for p in self.packets:
            expected_output += p.expected_output(bus_speed)

        return expected_output

    def __str__(self):
        s = "UsbTransaction:\n"
        for p in self.packets:
            s += "\t" + str(p) + "\n"
        return s

    def drive(self, usb_phy, bus_speed):
        for p in self.packets:
            p.drive(usb_phy, bus_speed)
