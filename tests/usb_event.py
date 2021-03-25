
class UsbEvent(object):

    def __init__(self, time=0):
        self._time = time
   
    @property
    def time(self):
        return self._time

