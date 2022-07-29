# Copyright 2021-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from usb_packet import USB_DATA_VALID_COUNT
import usb_packet

# TODO should EP numbers include the IN bit?


def CounterByte(startVal=0, length=0):
    i = startVal
    while i < length:
        yield i % 256
        i += 1


class UsbSession:
    def __init__(
        self,
        bus_speed="HS",
        run_enumeration=False,
        device_address=0,
        initial_delay=None,
    ):
        self._initial_delay = initial_delay
        self._bus_speed = bus_speed
        self._events = []
        self._enumerate = run_enumeration
        self._deviceAddress = device_address
        self._pidTable_out = [usb_packet.USB_PID["DATA0"]] * 16
        self._pidTable_in = [usb_packet.USB_PID["DATA0"]] * 16

        self._dataGen_in = [0] * 16
        self._dataGen_out = [0] * 16

        assert run_enumeration is False, "Not yet supported"

    @property
    def initial_delay(self):
        return self._initial_delay

    @property
    def bus_speed(self):
        return self._bus_speed

    @property
    def events(self):
        return self._events

    @property
    def deviceAddress(self):
        return self._deviceAddress

    @property
    def enumerate(self):
        return self._enumerate

    @property
    def data_valid_count(self):
        return USB_DATA_VALID_COUNT[self._bus_speed]

    def getPayload_out(self, n, length, resend=False):
        payload = [
            (x & 0xFF)
            for x in range(self._dataGen_out[n], self._dataGen_out[n] + length)
        ]
        if not resend:
            self._dataGen_out[n] += length
        return payload

    def getPayload_in(self, n, length, resend=False):
        payload = [
            (x & 0xFF) for x in range(self._dataGen_in[n], self._dataGen_in[n] + length)
        ]
        if not resend:
            self._dataGen_in[n] += length
        return payload

    @staticmethod
    def _pid_toggle(pid_table, n):

        if pid_table[n] == usb_packet.USB_PID["DATA0"]:
            pid_table[n] = usb_packet.USB_PID["DATA1"]
        else:
            pid_table[n] = usb_packet.USB_PID["DATA0"]

    def data_pid_in(self, n, togglePid=True, resetDataPid=False):

        if resetDataPid:
            self._pidTable_in[n] = usb_packet.USB_PID["DATA0"]

        pid = self._pidTable_in[n]

        if togglePid:
            self._pid_toggle(self._pidTable_in, n)

        return pid

    def data_pid_out(self, n, togglePid=True, resetDataPid=False):

        if resetDataPid:
            self._pidTable_out[n] = usb_packet.USB_PID["DATA0"]

        pid = self._pidTable_out[n]

        if togglePid:
            self._pid_toggle(self._pidTable_out, n)

        return pid

    def __str__(self):
        s = ""
        for e in self._events:
            s += str(self._events.index(e)) + ": "
            s += str(e) + "\n"
        return s

    def add_event(self, e):
        e.bus_speed = (
            self.bus_speed
        )  # TODO ideally dont need transction to know bus speed

        self._events.append(e)

    def pop_event(self):
        self.events.pop(0)

    @staticmethod
    def _sort_events_by_time(events):
        return sorted(events, key=lambda x: x.time, reverse=True)
