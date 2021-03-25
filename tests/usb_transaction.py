
from usb_event import UsbEvent

class UsbTransaction(UsbEvent):

    def __init__(self, endpointAddress = 0, endpointType = "BULK", eventTime = 0): # TODO Enum when we move to py3
        self._endpointAddress = endpointAddress
        self._endpointType = endpointType
        self._packets = []
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

    def __str__(self):
        s = "UsbTransaction "
        for p in self._packets:
           s += str(p)
        return s
