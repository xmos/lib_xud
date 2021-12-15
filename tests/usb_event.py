# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from abc import ABC, abstractmethod


class UsbEvent(ABC):
    def __init__(self, time=0):
        self._time = time

    # TODO so we want to use relative delays or absolute times?
    @property
    def time(self):
        return self._time

    @abstractmethod
    def expected_output(self, bus_speed, offset=0):
        pass

    # Drive event to simulator
    @abstractmethod
    def drive(self, usb_phy, bus_speed):
        pass

    # Note, an event might contain events
    @property
    @abstractmethod
    def event_count(self):
        pass

    def __str__(self):
        return "UsbEvent: IED: " + str(self.interEventDelay)
