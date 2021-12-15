# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from usb_phy import UsbPhy


class UsbPhyUtmi(UsbPhy):
    def __init__(
        self,
        rxd,
        rxa,
        rxdv,
        rxer,
        txd,
        txv,
        txrdy,
        ls,
        xcvrsel,
        termsel,
        clock,
        initial_delay=140000000000,  # in fs
        verbose=False,
        do_timeout=True,
        complete_fn=None,
        dut_exit_time=30000,
    ):

        self._do_tokens = False

        super().__init__(
            "UsbPhyUtmi",
            rxd,
            rxa,
            rxdv,
            rxer,
            txd,
            txv,
            txrdy,
            ls,
            xcvrsel,
            termsel,
            clock,
            initial_delay,
            verbose,
            do_timeout,
            complete_fn,
            dut_exit_time,
        )
