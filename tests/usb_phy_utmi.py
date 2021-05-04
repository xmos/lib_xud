# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import random
import Pyxsim
import sys
import zlib
from usb_packet import RxPacket, TokenPacket
import usb_packet
from usb_phy import UsbPhy

class UsbPhyUtmi(UsbPhy):

    def __init__(self, rxd, rxa, rxdv, rxer, txd, txv, txrdy, ls0, ls1, clock,
                 initial_delay=60000, verbose=False, test_ctrl=None,
                 do_timeout=True, complete_fn=None, expect_loopback=True,
                 dut_exit_time=25000):

        self._do_tokens = False

        super(UsbPhyUtmi, self).__init__('UsbPhyUtmi', rxd, rxa, rxdv, rxer, txd, txv, txrdy, ls0, ls1, clock,
                                             initial_delay, verbose, test_ctrl,
                                             do_timeout, complete_fn, expect_loopback, dut_exit_time)
