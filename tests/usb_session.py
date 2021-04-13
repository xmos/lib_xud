
from usb_phy import USB_DATA_VALID_COUNT
import usb_transaction
import usb_packet

# TODO should EP numbers include the IN bit?

def CounterByte(startVal = 0, length = 0):
    l = startVal
    while l < length:
        yield l % 256
        l += 1

class UsbSession(object):

    def __init__(self, bus_speed = "HS", run_enumeration = False, device_address = 0, **kwargs):
        self._bus_speed = bus_speed
        self._events = []
        self._enumerate = run_enumeration
        self._deviceAddress = device_address
        self._pidTable_out = [usb_packet.USB_PID["DATA0"]] * 16
        self._pidTable_in = [usb_packet.USB_PID["DATA0"]] * 16

        self._dataGen_in = [0] * 16
        self._dataGen_out = [0] * 16

        assert run_enumeration == False, "Not yet supported"

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

    def getPayload_out(self, n, length, resend = False):
        payload = [x for x in range(self._dataGen_out[n], self._dataGen_out[n] + length)]
        if not resend:
            self._dataGen_out[n] += length
        return payload

    def getPayload_in(self, n, length, resend = False):
        payload = [x for x in range(self._dataGen_in[n], self._dataGen_in[n] + length)]
        if not resend:
            self._dataGen_in[n] += length
        return payload
    
    def _pid_toggle(self, pid_table, n):

        if pid_table[n] == usb_packet.USB_PID["DATA0"]:
            pid_table[n] = usb_packet.USB_PID["DATA1"]
        else:
            pid_table[n] = usb_packet.USB_PID["DATA0"]

    def data_pid_in(self, n, togglePid = True):
        pid = self._pidTable_in[n]
        if togglePid:
            self._pid_toggle(self._pidTable_in, n)
        return pid
    
    def data_pid_out(self, n, togglePid = True):
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
        e.bus_speed = self.bus_speed #TODO ideally dont need transction to know bus speed
        self._events.append(e)

    def pop_event(self, e):
        self.events.pop(0)

    def _sort_events_by_time(self, events):
        return sorted(events, key=lambda x: x.time, reverse=True)

