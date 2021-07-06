#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import Pyxsim
from Pyxsim import testers
import os
import random
import sys
from usb_clock import Clock
from usb_phy import UsbPhy
from usb_phy_shim import UsbPhyShim
from usb_phy_utmi import UsbPhyUtmi
from usb_packet import RxPacket, USB_DATA_VALID_COUNT

ARCHITECTURE_CHOICES = ["xs2", "xs3"]
BUSSPEED_CHOICES = ["FS", "HS"]
args = {"arch": "xs3"}
clean_only = False


def create_if_needed(folder):
    if not os.path.exists(folder):
        os.makedirs(folder)
    return folder


def get_usb_clk_phy(
    coreFreqMhz,
    verbose=True,
    test_ctrl=None,
    do_timeout=True,
    complete_fn=None,
    expect_loopback=False,
    dut_exit_time=350000,
    arch="xs2",
):

    if arch == "xs2":
        clk = Clock("XS1_USB_CLK", Clock.CLK_60MHz, coreFreqMhz)
        phy = UsbPhyUtmi(
            "XS1_USB_RXD",
            "XS1_USB_RXA",  # rxa
            "XS1_USB_RXV",  # rxv
            "XS1_USB_RXE",  # rxe
            "tile[0]:XS1_PORT_8A",  # txd
            "tile[0]:XS1_PORT_1K",  # txv
            "tile[0]:XS1_PORT_1H",  # txrdy
            "XS1_USB_LS",
            "XS1_USB_XCVRSEL",
            "XS1_USB_TERMSEL",
            clk,
            verbose=verbose,
            test_ctrl=test_ctrl,
            do_timeout=do_timeout,
            complete_fn=complete_fn,
            expect_loopback=expect_loopback,
            dut_exit_time=dut_exit_time,
        )

    elif arch == "xs3":
        clk = Clock("XS1_USB_CLK", Clock.CLK_60MHz, coreFreqMhz)
        phy = UsbPhyUtmi(
            "XS1_USB_RXD",
            "XS1_USB_RXA",  # rxa
            "XS1_USB_RXV",  # rxv
            "XS1_USB_RXE",  # rxe
            "tile[0]:XS1_PORT_8A",  # txd
            "tile[0]:XS1_PORT_1K",  # txv
            "tile[0]:XS1_PORT_1H",  # txrdy
            "XS1_USB_LS",
            "XS1_USB_XCVRSEL",
            "XS1_USB_TERMSEL",
            clk,
            verbose=verbose,
            test_ctrl=test_ctrl,
            do_timeout=do_timeout,
            complete_fn=complete_fn,
            expect_loopback=expect_loopback,
            dut_exit_time=dut_exit_time,
        )

    else:
        raise ValueError("Invalid architecture: " + arch)

    return (clk, phy)


def run_on_simulator(xe, simthreads, **kwargs):
    for k in ["do_xe_prebuild", "build_env", "clean_before_build"]:
        if k in kwargs:
            kwargs.pop(k)
    return Pyxsim.run_with_pyxsim(xe, simthreads, **kwargs)


def run_on(**kwargs):

    for name, value in kwargs.items():
        arg_value = args.get(name)
        if arg_value is not None and value != arg_value:
            return False

    return True


FIXTURE_TO_DEFINE = {
    "core_freq": "TEST_FREQ",
    "arch": "TEST_ARCH",
    "dummy_threads": "TEST_DTHREADS",
    "ep": "TEST_EP_NUM",
    "address": "XUD_STARTUP_ADDRESS",
}


def do_usb_test(
    arch,
    ep,
    address,
    bus_speed,
    dummy_threads,
    core_freq,
    clk,
    phy,
    sessions,
    test_file,
    seed,
    level="nightly",
    extra_tasks=[],
    verbose=False,
):
    build_options = []

    # Flags for makefile
    for k, v in FIXTURE_TO_DEFINE.items():
        build_options += [str(v) + "=" + str(locals()[k])]

    # Defines for DUT code
    # TODO shoud the makefile set thease based on the above?
    build_options_str = "CFLAGS="
    for k, v in FIXTURE_TO_DEFINE.items():
        build_options_str += "-D" + str(v) + "=" + str(locals()[k]) + " "

    build_options = build_options + [build_options_str]

    """Shared test code for all RX tests using the test_rx application."""
    testname, extension = os.path.splitext(os.path.basename(test_file))
    tester_list = []

    binary = "{testname}/bin/{arch}_{core_freq}_{dummy_threads}_{ep}/{testname}_{arch}_{core_freq}_{dummy_threads}_{ep}.xe".format(
        testname=testname,
        arch=arch,
        core_freq=core_freq,
        dummy_threads=dummy_threads,
        ep=ep,
    )

    # Do not need to clean since different build will different params go to separate binaries
    build_success, build_output = Pyxsim._build(
        binary, do_clean=False, build_options=build_options
    )

    assert len(sessions) == 1, "Multiple sessions not yet supported"
    if build_success:
        for session in sessions:

            phy.session = session

            expect_folder = create_if_needed("expect")
            expect_filename = "{folder}/{test}_{arch}_{usb_speed}.expect".format(
                folder=expect_folder,
                test=testname,
                phy=phy.name,
                clk=clk.get_name(),
                arch=arch,
                usb_speed=bus_speed,
            )

            create_expect(arch, session, expect_filename, verbose=verbose)

            tester = testers.ComparisonTester(
                open(expect_filename),
                "lib_xud",
                "xud_sim_tests",
                testname,
                {"clk": clk.get_name(), "arch": arch, "speed": bus_speed},
            )

            tester_list.append(tester)
            simargs = get_sim_args(testname, clk, phy, arch)
            simthreads = [clk, phy] + extra_tasks
            run_on_simulator(binary, simthreads, simargs=simargs)
    else:
        tester_list.append("Build Failed")

    return tester_list


def create_expect(arch, session, filename, verbose=False):

    events = session.events

    """ Create the expect file for what packets should be reported by the DUT
    """
    with open(filename, "w") as f:

        packet_offset = 0

        if verbose:
            print("EXPECTED OUTPUT:")
        for i, event in enumerate(events):

            expect_str = event.expected_output(session.bus_speed, offset=packet_offset)
            packet_offset += event.event_count

            if verbose:
                print(str(expect_str), end=" ")

            f.write(str(expect_str))

        f.write("Test done\n")

        if verbose:
            print("Test done\n")


def get_sim_args(testname, clk, phy, arch="xs2"):
    sim_args = []

    if bool(os.getenv("enabletracing")):
        log_folder = create_if_needed("logs")

        filename = "{log}/xsim_trace_{test}_{clk}_{arch}".format(
            log=log_folder, test=testname, clk=clk.get_name(), phy=phy.name, arch=arch
        )

        sim_args += ["--trace-to", "{0}.txt".format(filename), "--enable-fnop-tracing"]

        vcd_args = "-o {0}.vcd".format(filename)
        vcd_args += (
            " -tile tile[0] -ports -ports-detailed -instructions"
            " -functions -cycles -clock-blocks -pads -cores -usb"
        )

        sim_args += ["--vcd-tracing", vcd_args]

    return sim_args


def move_to_next_valid_packet(phy):
    while (
        phy.expect_packet_index < phy.num_expected_packets
        and phy.expected_packets[phy.expect_packet_index].dropped
    ):
        phy.expect_packet_index += 1


def check_received_packet(packet, phy):
    if phy.expected_packets is None:
        return

    move_to_next_valid_packet(phy)

    if phy.expect_packet_index < phy.num_expected_packets:
        expected = phy.expected_packets[phy.expect_packet_index]
        if packet != expected:
            print(
                "ERROR: packet {n} does not match expected packet".format(
                    n=phy.expect_packet_index
                )
            )

            print("Received:")
            sys.stdout.write(packet.dump())
            print("Expected:")
            sys.stdout.write(expected.dump())

        print("Received packet {} ok".format(phy.expect_packet_index))
        # Skip this packet
        phy.expect_packet_index += 1

        # Skip on past any invalid packets
        move_to_next_valid_packet(phy)

    else:
        print("ERROR: received unexpected packet from DUT")
        print("Received:")
        sys.stdout.write(packet.dump())

    if phy.expect_packet_index >= phy.num_expected_packets:
        print("Test done")
        phy.xsi.terminate()
