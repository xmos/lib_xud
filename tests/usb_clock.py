# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from Pyxsim import SimThread


class Clock(SimThread):

    CLK_60MHz = 0x0

    def __init__(self, port, clk):
        self._running = True
        self._clk = clk
        if clk == self.CLK_60MHz:
            self._period_fs = 16666667
            self._name = "60Mhz"
        else:
            raise ValueError("Unsupported Clock Frequency")
        self._val = 0
        self._port = port

    def run(self):

        time = self.xsi.get_time()

        while True:

            time += self._period_fs / 2
            self.wait_until(time)
            self._val = 1 - self._val

            if self._running:
                self.xsi.drive_periph_pin(self._port, self._val)

    def is_high(self):
        return self._val == 1

    def is_low(self):
        return self._val == 0

    def get_rate(self):
        return self._clk

    def get_name(self):
        return self._name

    def stop(self):
        print("**** CLOCK STOP ****")
        self._running = False

    def start(self):
        self._running = True
