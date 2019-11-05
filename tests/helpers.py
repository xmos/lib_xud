#!/usr/bin/env python
import xmostest
import os
import random
import sys
from usb_clock import Clock
from usb_phy import UsbPhy
from usb_phy_shim import UsbPhyShim
from usb_phy_utmi import UsbPhyUtmi
from usb_packet import RxPacket
from usb_packet import BusReset

args = None

def create_if_needed(folder):
    if not os.path.exists(folder):
        os.makedirs(folder)
    return folder

#todo
dut_address = 1

def get_usb_clk_phy(verbose=True, test_ctrl=None, do_timeout=True,
                       complete_fn=None, expect_loopback=False,
                       dut_exit_time=350000, arch='xs2'):

    if arch=='xs2':
        clk = Clock('tile[0]:XS1_PORT_1J', Clock.CLK_60MHz)
        phy = UsbPhyShim('tile[0]:XS1_PORT_8B',
                         'tile[0]:XS1_PORT_1F', #rxa
                         'tile[0]:XS1_PORT_1I', #rxv
                         'tile[0]:XS1_PORT_1G', #rxe
                         'tile[0]:XS1_PORT_1E', #vld
                         'tile[0]:XS1_PORT_8A', #txd
                         'tile[0]:XS1_PORT_1K', #txv
                         'tile[0]:XS1_PORT_1H', #txrdy
                         clk,
                         verbose=verbose, test_ctrl=test_ctrl,
                         do_timeout=do_timeout, complete_fn=complete_fn,
                         expect_loopback=expect_loopback,
                         dut_exit_time=dut_exit_time)
 
    elif arch=='xs3':
        #clk = Clock('tile[0]:XS1_PORT_1J', Clock.CLK_60MHz)
        clk = Clock('XS1_USB_CLK', Clock.CLK_60MHz)
        phy = UsbPhyUtmi('XS1_USB_RXD',
                         'XS1_USB_RXA', #rxa
                         'XS1_USB_RXV', #rxv
                         'XS1_USB_RXE', #rxe
                         'tile[0]:XS1_PORT_8A', #txd
                         'tile[0]:XS1_PORT_1K', #txv
                         'tile[0]:XS1_PORT_1H', #txrdy
                         'XS1_USB_LS0', 
                         'XS1_USB_LS1',
                         clk,
                         verbose=verbose, test_ctrl=test_ctrl,
                         do_timeout=do_timeout, complete_fn=complete_fn,
                         expect_loopback=expect_loopback,
                         dut_exit_time=dut_exit_time)


    elif arch=='xs1':
        clk = Clock('tile[0]:XS1_PORT_1J', Clock.CLK_60MHz)
        phy = UsbPhyShim('tile[0]:XS1_PORT_8C',
                         'tile[0]:XS1_PORT_1O', #rxa
                         'tile[0]:XS1_PORT_1M', #rxv
                         'tile[0]:XS1_PORT_1P', #rxe
                         'tile[0]:XS1_PORT_1N', #vld
                         'tile[0]:XS1_PORT_8A', #txd
                         'tile[0]:XS1_PORT_1K', #txv
                         'tile[0]:XS1_PORT_1H', #txrdy
                         clk,
                         verbose=verbose, test_ctrl=test_ctrl,
                         do_timeout=do_timeout, complete_fn=complete_fn,
                         expect_loopback=expect_loopback,
                         dut_exit_time=dut_exit_time)
        
    return (clk, phy)

def run_on(**kwargs):
    if not args:
        return True

    for name,value in kwargs.iteritems():
        arg_value = getattr(args,name)
        if arg_value is not None and value != arg_value:
            return False

    return True

def runall_rx(test_fn):
   
    if run_on(arch='xs3'):
        (clk_60, usb_phy) = get_usb_clk_phy(verbose=False, arch='xs3')
        seed = args.seed if args.seed else random.randint(0, sys.maxint)
        test_fn('xs3', clk_60, usb_phy, seed)
    
    if run_on(arch='xs2'):
        (clk_60, usb_phy) = get_usb_clk_phy(verbose=False, arch='xs2')
        seed = args.seed if args.seed else random.randint(0, sys.maxint)
        test_fn('xs2', clk_60, usb_phy, seed)


def do_usb_test(arch, clk, phy, packets, test_file, seed,
               level='nightly', extra_tasks=[]):

    """ Shared test code for all RX tests using the test_rx application.
    """
    testname,extension = os.path.splitext(os.path.basename(test_file))

    resources = xmostest.request_resource("xsim")

    binary = '{testname}/bin/{arch}/{testname}_{arch}.xe'.format(testname=testname, arch=arch)

    print binary

    if xmostest.testlevel_is_at_least(xmostest.get_testlevel(), level):
        print "Running {test}: {arch} arch sending {n} packets at {clk} (seed {seed})".format(
            test=testname, n=len(packets),
            arch=arch, clk=clk.get_name(), seed=seed)

    phy.set_packets(packets)

    expect_folder = create_if_needed("expect")
    expect_filename = '{folder}/{test}_{arch}.expect'.format(
        folder=expect_folder, test=testname, phy=phy.get_name(), clk=clk.get_name(), arch=arch)
    create_expect(arch, packets, expect_filename)

    tester = xmostest.ComparisonTester(open(expect_filename),
                                      'lib_xud', 'xud_sim_tests', testname,
                                     {'clk':clk.get_name(), 'arch':arch})

    tester.set_min_testlevel(level)

    simargs = get_sim_args(testname, clk, phy, arch)
    xmostest.run_on_simulator(resources['xsim'], binary,
                              simthreads=[clk, phy] + extra_tasks,
                              tester=tester,
                              simargs=simargs)

def create_expect(arch, packets, filename):
    do_tokens = (arch == "xs2")
   
    """ Create the expect file for what packets should be reported by the DUT
    """
    with open(filename, 'w') as f:
        for i,packet in enumerate(packets):
            #if not packet.dropped:
            if isinstance(packet, RxPacket):
                f.write("Receiving packet {}\n".format(i))

                for (i, byte) in enumerate(packet.get_bytes(do_tokens=do_tokens)):
                    f.write("Received byte: {0:#x}\n".format(byte))
            
            else:  
                f.write("Phy transmitting packet {} PID: {} ({})\n".format(i, packet.get_pid_pretty(), packet.pid))
        
        f.write("Test done\n")

def get_sim_args(testname, clk, phy, arch='xs2'):
    sim_args = []

    if args and args.trace:
        log_folder = create_if_needed("logs")

        filename = "{log}/xsim_trace_{test}_{clk}_{arch}".format(
            log=log_folder, test=testname,
            clk=clk.get_name(), phy=phy.get_name(), arch=arch)

        sim_args += ['--trace-to', '{0}.txt'.format(filename), '--enable-fnop-tracing']

        vcd_args  = '-o {0}.vcd'.format(filename)
        vcd_args += (' -tile tile[0] -ports -ports-detailed -instructions'
                     ' -functions -cycles -clock-blocks -pads -cores')

        sim_args += ['--vcd-tracing', vcd_args]
#        sim_args += ['--xscope', '-offline logs/xscope.xmt']

    return sim_args

def packet_processing_time(phy, data_bytes):
    """ Returns the time it takes the DUT to process a given frame
    """
    return 6000 * phy.get_clock().get_bit_time()

#def get_dut_address():
#    """ Returns the busaddress of the DUT
#    """
#    #TODO, we need the ability to config this
#    return 1

def choose_small_frame_size(rand):
    """ Choose the size of a frame near the minimum size frame (46 data bytes)
    """
    return rand.randint(46, 54)

def move_to_next_valid_packet(phy):
    while (phy.expect_packet_index < phy.num_expected_packets and
           phy.expected_packets[phy.expect_packet_index].dropped):
        phy.expect_packet_index += 1

def check_received_packet(packet, phy):
    if phy.expected_packets is None:
        return

    move_to_next_valid_packet(phy)

    if phy.expect_packet_index < phy.num_expected_packets:
        expected = phy.expected_packets[phy.expect_packet_index]
        if packet != expected:
            print "ERROR: packet {n} does not match expected packet".format(
                n=phy.expect_packet_index)

            print "Received:"
            sys.stdout.write(packet.dump())
            print "Expected:"
            sys.stdout.write(expected.dump())

        print "Received packet {} ok".format(phy.expect_packet_index)
        # Skip this packet
        phy.expect_packet_index += 1

        # Skip on past any invalid packets
        move_to_next_valid_packet(phy)

    else:
        print "ERROR: received unexpected packet from DUT"
        print "Received:"
        sys.stdout.write(packet.dump())

    if phy.expect_packet_index >= phy.num_expected_packets:
        print "Test done"
        phy.xsi.terminate()

