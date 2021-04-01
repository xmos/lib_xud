
import abc

class UsbEvent(object):

    def __init__(self, time=0, interEventDelay= 1): #TODO set delay to sensible default
        self._time = time
        self._interEventDelay = interEventDelay
   
    #TODO so we want to use relative delays or absolute times?
    @property
    def time(self):
        return self._time
    
    @property
    def interEventDelay(self):
        return self._interEventDelay       

    @abc.abstractmethod
    def expected_output(self):
        pass

    # Drive event to simulator
    @abc.abstractmethod
    def drive(self, xsi):
        pass

    #Note, an event might contain events 
    @abc.abstractproperty
    def eventcount(self):
        pass

   
