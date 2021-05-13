# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
# import xmostest
import Pyxsim
import sys
import zlib

class Clock(Pyxsim.SimThread):

    CLK_60MHz = 0x0

    def __init__(self, port, clk):
        self._running = True
        self._clk = clk
        if clk == self.CLK_60MHz:
            self._period = float(1000000000) / 60000000
            self._name = '60Mhz'
            self._bit_time = 5 # TODO
        else:
            raise ValueError('Unsupported Clock Frequency')
        self._min_ifg = 96 * self._bit_time
        self._val = 0
        self._port = port

    def run(self):
        while True:
            self.wait_until(self.xsi.get_time() + self._period/2)
            self._val = 1 - self._val

            if self._running:
                #print "{}".format(self._val)
                #self.xsi.drive_port_pins(self._port, self._val)
                self.xsi.drive_periph_pin(self._port, self._val)

    def is_high(self):
        return (self._val == 1)

    def is_low(self):
        return (self._val == 0)

    def get_rate(self):
        return self._clk

    def get_name(self):
        return self._name

    def get_min_ifg(self):
        return self._min_ifg

    def get_bit_time(self):
        return self._bit_time

    def stop(self):
        print("**** CLOCK STOP ****")
        self._running = False

    def start(self):
        self._running = True
