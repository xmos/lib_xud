# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import random
import xmostest
import sys
import zlib
from usb_packet import RxPacket, TokenPacket, USB_PID
import usb_packet

USB_DATA_VALID_COUNT = {'FS': 39, "HS": 0}

USB_LINESTATE = {
                    'IDLE': 0,
                    'FS_J': 2,
                    'FS_K': 1,
                    'HS_J': 1,
                    'HS_K': 2,
                  }

USB_TIMINGS = {
                    'IDLE_TO_FS_MIN_US': 300, #Spec: 3000
                    'IDLE_TO_FS_MAX_US': 312, #Spec: 3125
                    'RESUME_FSK_MIN_US': 200, #Spec: 20000us
                    'RESUME_SE0_US': 1.25, # 1.25uS - 1.5uS  
                }

class UsbPhy(xmostest.SimThread):

    # Time in ns from the last packet being sent until the end of test is signalled to the DUT
    END_OF_TEST_TIME = 5000

    def __init__(self, name, rxd, rxa, rxdv, rxer, txd, txv, txrdy, ls, xcvrsel, termsel, clock, initial_delay, verbose,
                 test_ctrl, do_timeout, complete_fn, expect_loopback, dut_exit_time):
        self._name = name
        self._test_ctrl = test_ctrl
        self._rxd = rxd    #Rx data
        self._rxa = rxa    #Rx Active
        self._rxdv = rxdv  #Rx valid
        self._rxer = rxer  #Rx Error
        self._txd = txd
        self._txv = txv
        self._txrdy = txrdy
        self._ls = ls
        self._xcvrsel = xcvrsel
        self._termsel = termsel
        self._session = []
        self._clock = clock
        self._initial_delay = initial_delay
        self._verbose = verbose
        self._do_timeout = do_timeout
        self._complete_fn = complete_fn
        self._expect_loopback = expect_loopback
        self._dut_exit_time = dut_exit_time

    @property
    def name(self):
        return self._name

    @property
    def clock(self):
        return self._clock
    
    @property
    def session(self):
        return self._session

    @session.setter
    def session(self, session):
        self._session = session
   
    def us_to_clocks(self, time_us):
        time_clocks = int(time_us/self._clock.period_us)
        return time_clocks

    def start_test(self):
        self.wait_until(self.xsi.get_time() + self._initial_delay)
        self.wait(lambda x: self._clock.is_high())
        self.wait(lambda x: self._clock.is_low())

    def end_test(self):
        if self._verbose:
            print("All events sent")

        if self._complete_fn:
            self._complete_fn(self)

        # Give the DUT a reasonable time to process the packet
        self.wait_until(self.xsi.get_time() + self.END_OF_TEST_TIME)

        if self._do_timeout:
            # Allow time for a maximum sized packet to arrive
            timeout_time = (self._clock.get_bit_time() * 1522 * 8)

            if self._expect_loopback:
                # If looping back then take into account all the data
                total_packet_bytes = sum([len(packet.get_bytes()) for packet in self._session.events])
                total_data_bits = total_packet_bytes * 8

                # Allow 2 cycles per bit
                timeout_time += 2 * total_data_bits

                # The clock ticks are 2ns long
                timeout_time *= 2

                # The events are copied to and from the user application
                timeout_time *= 2

            self.wait_until(self.xsi.get_time() + timeout_time)

            if self._test_ctrl:
                # Indicate to the DUT that the test has finished
                self.xsi.drive_port_pins(self._test_ctrl, 1)

            # Allow time for the DUT to exit
            self.wait_until(self.xsi.get_time() + self._dut_exit_time)

            print("ERROR: Test timed out")
            self.xsi.terminate()

    def set_clock(self, clock):
        self._clock = clock

    def drive_error(self, value):
        self.xsi.drive_port_pins(self._rxer, value)

    def run(self):

        xsi = self.xsi

        self.start_test()

        for i,event in enumerate(self._session.events):

            event.drive(self)
           
        print("Test done")
        self.end_test()







