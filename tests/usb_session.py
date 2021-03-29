
from usb_phy import USB_DATA_VALID_COUNT
import usb_transaction

class UsbSession(object):

    def __init__(self, bus_speed = "HS", run_enumeration = False, device_address = 0, **kwargs):
        self._bus_speed = bus_speed
        self._events = []
        self._enumerate = run_enumeration
        self._device_address = device_address
    
    @property
    def bus_speed(self):
        return self._bus_speed

    @property
    def events(self):
        return self._events

    @property
    def device_address(self):
        return self._device_address

    @property
    def enumerate(self):
        return self._enumerate

    @property
    def data_valid_count(self):
        return USB_DATA_VALID_COUNT[self._bus_speed] 

    def __str__(self):
        
        s = ""

        for e in self._events:
            s += str(self._events.index(e)) + ": " 
            s += str(e) + "\n"

        return s

    def add_event(self, e):
        
        e.bus_speed = self.bus_speed #TODO ideally dont need transction to know bus speed
        self._events.append(e)
        #self._events = _sort_events_by_time(self._events)

    def pop_event(self, e):
        self.events.pop(0)

    def _sort_events_by_time(self, events):
        return sorted(events, key=lambda x: x.time, reverse=True)

