# Copyright 2021-2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from pathlib import Path
import os
import shutil
import time
import sys
import re
from filelock import FileLock

import pytest

from helpers import get_usb_clk_phy, do_usb_test
import Pyxsim
from xcoverage.xcov import xcov_process, xcov_combine, combine_process

# Note, no current support for XS2 so don't copy XS2 xn files
XN_FILES = [
    "test_xs3_600.xn",
    "test_xs3_800.xn",
]
combine_test = combine_process(os.path.dirname(os.path.abspath(__file__)))
xcov_comb = xcov_combine()

# Note, HS tests will be skipped unless 85MIPS are available to lib_xud
PARAMS = {
    "extended": {
        "arch": ["xs3"],
        "ep": [1, 2, 4],
        "address": [0, 1, 127],
        "bus_speed": ["HS", "FS"],
        "dummy_threads": [0, 3, 5],  # Note, plus 2 for test cores
        "core_freq": [600, 800],
    },
    "default": {
        "arch": ["xs3"],
        "ep": [1, 2],
        "address": [0, 1],
        "bus_speed": ["HS", "FS"],
        "dummy_threads": [0, 5],  # Note, plus 2 for test cores
        "core_freq": [600],
    },
    "smoke": {
        "arch": ["xs3"],
        "ep": [1],
        "address": [1],
        "bus_speed": ["HS", "FS"],
        "dummy_threads": [5],  # Note, plus 2 for test cores
        "core_freq": [600],
    },
}


def pytest_addoption(parser):
    parser.addoption("--smoke", action="store_true", help="Smoke test")
    parser.addoption("--extended", action="store_true", help="Extended test")
    parser.addoption(
        "--clean",
        action="store_true",
        default=False,
        help="clean build file",
    )
    parser.addoption(
        "--xcov",
        action="store_true",
        default=False,
        help="Enable xcov",
    )
    parser.addoption(
        "--enabletracing",
        action="store_true",
        default=False,
        help="Run tests with instruction tracing",
    )
    parser.addoption(
        "--enablevcdtracing",
        action="store_true",
        default=False,
        help="Run tests with VCD tracing",
    )


def pytest_configure(config):
    os.environ["enabletracing"] = str(config.getoption("enabletracing"))
    os.environ["enablevcdtracing"] = str(config.getoption("enablevcdtracing"))
    os.environ["xcov"] = str(config.getoption("xcov"))
    os.environ["clean"] = str(config.getoption("clean"))


def pytest_generate_tests(metafunc):
    try:
        PARAMS = metafunc.module.PARAMS  # noqa F401
        if metafunc.config.getoption("clean"):
            params = PARAMS.get("extended", PARAMS["default"])
        elif metafunc.config.getoption("smoke"):
            params = PARAMS.get("smoke", PARAMS["default"])
        elif metafunc.config.getoption("extended"):
            params = PARAMS.get("extended", PARAMS["default"])
        else:
            params = PARAMS["default"]
        if metafunc.config.getoption("xcov"):
            os.environ["enabletracing"] = "True"
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
    test_file,
    capfd,
):

    xcov = eval(os.getenv("xcov"))

    total_threads = dummy_threads + 2  # 1 thread for xud another for test code
    if (core_freq / total_threads < 85.0) and bus_speed == "HS":
        pytest.skip("HS requires 85 MIPS")

    tester_list = []
    output = []

    # TODO it would be good to sanity check core_freq == xe.freq
    (clk_60, usb_phy) = get_usb_clk_phy(verbose=False, arch=arch)

    testname, _ = os.path.splitext(os.path.basename(test_file))
    desc = f"{arch}_{core_freq}_{dummy_threads}_{ep}_{address}_{bus_speed}"
    disasm = f"{testname}/bin/{desc}/{testname}_{desc}.dump"
    trace = f"logs/xsim_trace_{testname}_{desc}.txt"
    xcov_dir = f"{testname}/bin/{desc}"

    if not eval(os.getenv("clean")):
        cap_output, err = capfd.readouterr()
        output.append(cap_output.split("\n"))

        sys.stdout.write("\n")

        result = do_usb_test(
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
            capfd=capfd,
        )

        if result:
            if eval(os.getenv("xcov")):
                # Calculate code coverage for each tests. Exclude test source code.
                coverage = xcov_process(
                    disasm,
                    trace,
                    xcov_dir,
                    excluded_file=["/tests/", "XUD_TestMode"],
                )
                # Generate coverage file for each source code included
                xcov_comb.run_combine(xcov_dir)
                # Delete trace file and disasm file
                if os.path.exists(trace):
                    os.remove(trace)
        assert result


def copy_common_xn_files(
    test_dir,
    common_dir="shared",
    source_dir="src",
    xn_files=XN_FILES,
):
    src_dir = os.path.join(test_dir, source_dir)
    for xn_file in xn_files:
        xn = os.path.join(common_dir, xn_file)
        shutil.copy(xn, src_dir)


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
    if hasattr(request.config, "workerinput"):
        return request.config.workerinput["workerid"]
    # Master means not executing with multiple workers
    return "master"


# Runs after all tests are collected, but before all tests are run
# Note, there is one session per process, so this runs once per process...
@pytest.fixture(scope="session", autouse=True)
def copy_xn_files(worker_id, request):

    # Attempt to only run copy/delete once..
    if worker_id:
        session = request.node
        combine_test.remove_tmp_testresult(combine_test.tpath)
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
def xcoverage_combination(tmp_path_factory, worker_id, request):
    if eval(os.getenv("xcov")):
        # run xcoverage combine test at the end of pytest
        root_tmp_dir = tmp_path_factory.getbasetemp().parent

        fn = root_tmp_dir / "data.json"

        def follow(nfile, n):
            nf = open(nfile, "r")
            lines = len(nf.readlines())
            while lines != n:
                nf.close()
                nf = open(nfile, "r")
                lines = len(nf.readlines())
                time.sleep(0.5)

        def run_at_end():
            wkc = os.getenv("PYTEST_XDIST_WORKER_COUNT")
            if wkc:
                follow(fn, int(wkc))
            coverage = combine_test.do_combine_test(test_dirs)
            combine_test.generate_merge_src()
            # teardowm - remove tmp file
            combine_test.remove_tmp_testresult(combine_test.tpath)

        def status():
            f = open(fn, "a")
            f.write(str(worker_id + "\n"))

        if worker_id == "master":
            request.addfinalizer(run_at_end)
            return

        with FileLock(str(fn) + ".lock"):
            if fn.is_file():
                request.addfinalizer(status)
            else:
                fn.write_text(str(worker_id) + "\n")
                request.addfinalizer(run_at_end)
