# Copyright 2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
import os
import random
import sys
import Pyxsim
from Pyxsim import testers
from helpers import get_usb_clk_phy, do_usb_test
from pathlib import Path
import shutil

XN_FILES = ["test_xs2.xn", "test_xs3_600.xn", "test_xs3_800.xn"]

PARAMS = {
    "default": {
        "arch": ["xs3"],
        "ep": [1, 2, 4],
        "address": [0, 1, 127],
        "bus_speed": ["HS", "FS"],
        "dummy_threads": [0, 4, 5],
        "core_freq": [600, 800],
    },
    "smoke": {
        "arch": ["xs3"],
        "ep": [1],
        "address": [0],
        "bus_speed": ["HS", "FS"],
        "dummy_threads": [4],
        "core_freq": [600],
    },
}


def pytest_addoption(parser):
    parser.addoption("--smoke", action="store_true", help="smoke test")


def pytest_generate_tests(metafunc):
    try:
        PARAMS = metafunc.module.PARAMS
        if metafunc.config.getoption("smoke"):
            params = PARAMS.get("smoke", PARAMS["default"])
        else:
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


@pytest.fixture
def test_file(request):
    return str(request.node.fspath)


@pytest.fixture()
def test_dummy_threads(dummy_threads: int) -> int:
    return dummy_threads


def test_RunUsbSession(
    test_session,
    arch,
    ep,
    address,
    bus_speed,
    dummy_threads,
    core_freq,
    test_file,
    capfd,
):

    tester_list = []
    output = []
    testname, extension = os.path.splitext(os.path.basename(__file__))
    seed = random.randint(0, sys.maxsize)

    (clk_60, usb_phy) = get_usb_clk_phy(verbose=False, arch=arch)
    tester_list.extend(
        do_usb_test(
            arch,
            ep,
            address,
            bus_speed,
            dummy_threads,
            core_freq,
            clk_60,
            usb_phy,
            [test_session],
            test_file,
            seed,
        )
    )
    cap_output, err = capfd.readouterr()
    output.append(cap_output.split("\n"))

    sys.stdout.write("\n")
    results = Pyxsim.run_tester(output, tester_list)

    # TODO only one result
    for result in results:
        if not result:
            print(cap_output)
            sys.stderr.write(err)
        assert result


def copy_common_xn_files(
    test_dir, path=".", common_dir="shared_src", source_dir="src", xn_files=XN_FILES
):
    src_dir = os.path.join(test_dir, source_dir)
    for xn_file in xn_files:
        xn = os.path.join(common_dir, xn_file)
        shutil.copy(xn, src_dir)


def delete_test_specific_xn_files(
    test_dir, path=".", source_dir="src", xn_files=XN_FILES
):
    src_dir = os.path.join(test_dir, source_dir)
    for xn_file in xn_files:
        xn = os.path.join(src_dir, xn_file)

        print("DELETE: " + str(xn))

        try:
            os.remove(xn)
        except OSError:
            pass


@pytest.fixture(scope="session", autouse=True)
def worker_id(request):
    if hasattr(request.config, "slaveinput"):
        return request.config.slaveinput["slaveid"]
    else:
        # Master means not executing with multiple workers
        return "master"


# Runs after all tests are collected, but before all tests are run
# Note, there is one session per process, to this runs once per process...
@pytest.fixture(scope="session", autouse=True)
def copy_xn_files(worker_id, request):

    # Attempt to only run copy/delete once..
    if worker_id == "master" or worker_id == "gw0":

        session = request.node

        # There will be duplicates (same test name with different params) so treat as set
        test_dirs = set([])

        # Go through collected tests and copy over XN files
        for item in session.items:
            full_path = item.fspath
            test_dir = Path(full_path).with_suffix("")  # Strip suffix
            test_dir = os.path.basename(test_dir)
            test_dirs.add(test_dir)

        for test_dir in test_dirs:
            copy_common_xn_files(test_dir)

        def delete_xn_files():

            # Run deletion on one process only
            if worker_id == "master" or worker_id == "gw0":

                # Go through collected tests deleting XN files
                for test_dir in test_dirs:
                    delete_test_specific_xn_files(test_dir)

    # Setup tear down
    # Deletion removed for now - doesn't seem important
    # request.addfinalizer(delete_xn_files)
