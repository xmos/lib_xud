# Copyright 2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from pathlib import Path
import os
import shutil
import sys

import pytest

from helpers import get_usb_clk_phy, do_usb_test
import Pyxsim
from xcoverage.xcov import xcov_process, xcov_combine, combine_tests

# Note, no current support for XS2 so don't copy XS2 xn files
XN_FILES = ["test_xs3_600.xn", "test_xs3_800.xn", "test_xs3_540.xn", "test_xs3_500.xn"]

PARAMS = {
    "extended": {
        "arch": ["xs3"],
        "ep": [1, 2, 4],
        "address": [0, 1, 127],
        "bus_speed": ["HS", "FS"],
        "dummy_threads": [0, 5, 6],
        "core_freq": [600, 800],
    },
    "default": {
        "arch": ["xs3"],
        "ep": [1, 2],
        "address": [0, 1],
        "bus_speed": ["HS", "FS"],
        "dummy_threads": [0, 6],
        "core_freq": [600],
    },
    "smoke": {
        "arch": ["xs3"],
        "ep": [1],
        "address": [1],
        "bus_speed": ["HS"],
        "dummy_threads": [6],
        "core_freq": [600],
    },
}


def pytest_addoption(parser):
    parser.addoption("--smoke", action="store_true", help="Smoke test")
    parser.addoption("--extended", action="store_true", help="Extended test")
    parser.addoption(
        "--xcov",
        action="store_true",
        help="Enable xcov",
    )
    parser.addoption(
        "--enabletracing",
        action="store_true",
        default=False,
        help="Run tests with tracing",
    )


def pytest_configure(config):
    os.environ["enabletracing"] = str(config.getoption("enabletracing"))


def pytest_generate_tests(metafunc):
    try:
        PARAMS = metafunc.module.PARAMS  # noqa F401
        if metafunc.config.getoption("smoke"):
            params = PARAMS.get("smoke", PARAMS["default"])
        elif metafunc.config.getoption("extended"):
            params = PARAMS.get("extended", PARAMS["default"])
        else:
            params = PARAMS["default"]
        if metafunc.config.getoption("xcov"):
            params["xcov"] = [metafunc.config.getoption("xcov")]
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


@pytest.fixture()
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
    xcov,
    test_file,
    capfd,
):

    tester_list = []
    output = []

    # TODO it would be good to sanity check core_freq == xe.freq
    (clk_60, usb_phy) = get_usb_clk_phy(core_freq, verbose=False, arch=arch)
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
            xcov,
            [test_session],
            test_file,
        )
    )

    testname, _ = os.path.splitext(os.path.basename(test_file))
    desc = f"{arch}_{core_freq}_{dummy_threads}_{ep}_{address}_{bus_speed}"
    disasm = f"{testname}/bin/{desc}/{testname}_{desc}.dump"
    trace = f"logs/xsim_trace_{testname}_{desc}.txt"
    xcov_dir = f"{testname}/bin/{desc}"

    cap_output, err = capfd.readouterr()
    output.append(cap_output.split("\n"))

    sys.stdout.write("\n")
    results = Pyxsim.run_tester(output, tester_list)

    # TODO only one result
    for result in results:
        if not result:
            print(cap_output)
            sys.stderr.write(err)
        else:
            if xcov:
                # calculate code coverage for each tests
                coverage = xcov_process(disasm, trace, xcov_dir)
                # generate coverage file for each source code included
                xcov_combine(xcov_dir)
                # delete_logs(trace)
        assert result

def copy_common_xn_files(
    test_dir,
    common_dir="shared_src",
    source_dir="src",
    xn_files=XN_FILES,
):
    src_dir = os.path.join(test_dir, source_dir)
    for xn_file in xn_files:
        xn = os.path.join(common_dir, xn_file)
        shutil.copy(xn, src_dir)

# def delete_logs(logsfile):
#     if os.path.isfile(logsfile):
#         try:
#             print("delete %s" % logsfile)
#             os.remove(logsfile)
#         except Exception as e:
#             print(e)
#     else:
#         print("%s not found" % logsfile)

def delete_test_specific_xn_files(test_dir, source_dir="src", xn_files=XN_FILES):
    src_dir = os.path.join(test_dir, source_dir)
    for xn_file in xn_files:
        xn = os.path.join(src_dir, xn_file)

        try:
            os.remove(xn)
        except OSError:
            pass


@pytest.fixture(scope="session", autouse=True)
def worker_id(request):
    if hasattr(request.config, "slaveinput"):
        return request.config.slaveinput["slaveid"]
    # Master means not executing with multiple workers
    return "master"


# Runs after all tests are collected, but before all tests are run
# Note, there is one session per process, so this runs once per process...
@pytest.fixture(scope="session", autouse=True)
def copy_xn_files(worker_id, request):

    # Attempt to only run copy/delete once..
    if worker_id in ("master", "gw0"):

        session = request.node

        # There will be duplicates (same test name with different params) sos
        # treat as set
        global test_dirs
        test_dirs = set([])
        # test_dir_list = []
        # Go through collected tests and copy over XN files
        for item in session.items:
            full_path = item.fspath
            test_dir = Path(full_path).with_suffix("")  # Strip suffix
            test_dir = os.path.basename(test_dir)  # Strip path leaving filename
            test_dirs.add(test_dir)
            # test_dir_list.append(test_dir)

        for test_dir in test_dirs:
            copy_common_xn_files(test_dir)

        # def delete_xn_files():

        #     # Run deletion on one process only
        #     if worker_id in ("master", "gw0"):

        #         # Go through collected tests deleting XN files
        #         for test_dir in test_dirs:
        #             delete_test_specific_xn_files(test_dir)

    # Setup tear down
    # Deletion removed for now - doesn't seem important
    # request.addfinalizer(delete_xn_files)

@pytest.fixture(scope="session", autouse=True)
def xcoverage_combination(worker_id, request):
    #run xcoverage combine test at the end of pytest
    def run_combination():
        global test_dirs
        if worker_id in ("master", "gw0"):
            current_path = os.getcwd()
            coverage = combine_tests(current_path,test_dirs)
    request.addfinalizer(run_combination)