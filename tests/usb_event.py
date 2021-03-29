
import abc

class UsbEvent(object):

    def __init__(self, time=0):
        self._time = time
   
    @property
    def time(self):
        return self._time

    @abc.abstractmethod
    def expected_output(self):
        pass

    #Note, an event might contain events 
    @abc.abstractproperty
    def eventcount(self):
        pass
