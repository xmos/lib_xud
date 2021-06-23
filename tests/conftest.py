# Copyright 2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import pytest
import os
import random
import sys
import Pyxsim
from Pyxsim import testers
from helpers import get_usb_clk_phy, do_usb_test
import inspect

PARAMS = {
    "default": {
        "arch": ["xs3"],
        "ep": [1],
        "address": [1],
        "bus_speed": ["HS", "FS"],
    },
}


def pytest_generate_tests(metafunc):
    try:
        PARAMS = metafunc.module.PARAMS
        params = PARAMS["default"]

    except AttributeError:
        params = {}

    for name, values in params.items():
        if name in metafunc.fixturenames:
            metafunc.parametrize(name, values)


@pytest.fixture()
def test_ep(ep: int) -> int:
    return ep


@pytest.fixture()
def test_address(address: int) -> int:
    return address


@pytest.fixture()
def test_bus_speed(bus_speed: str) -> str:
    return bus_speed


@pytest.fixture()
def test_arch(arch: str) -> str:
    return arch


def test_RunUsbSession(test_session, arch, ep, address, bus_speed, test_file):

    tester_list = []
    output = []
    testname, extension = os.path.splitext(os.path.basename(__file__))
    seed = random.randint(0, sys.maxsize)

    (clk_60, usb_phy) = get_usb_clk_phy(verbose=False, arch=arch)
    start_cap = Pyxsim.cap_redirect(sys.stdout)
    tester_list.extend(
        do_usb_test(
            arch,
            clk_60,
            usb_phy,
            bus_speed,
            [test_session],
            test_file,
            seed,
        )
    )
    cap_output = start_cap.read_output()
    start_cap.close_capture()
    output.append(cap_output.split("\n"))

    sys.stdout.write("\n")
    results = Pyxsim.run_tester(output, tester_list)

    # TODO only one result
    for result in results:
        assert result
