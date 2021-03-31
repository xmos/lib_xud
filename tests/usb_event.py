
import abc

class UsbEvent(object):

    def __init__(self, time=0, interEventDelay= 1): #TODO set delay to sensible default
        self._time = time
        self._interEventDelay = interEventDelay
   
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

    # TODO so we want to use relative delays or absolute times?
    @property
    def interEventDelay(self):
        return self._interEventDelay
