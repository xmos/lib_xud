# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import random
import xmostest
import sys
import zlib
from usb_packet import RxPacket, TokenPacket

class TxPhy(xmostest.SimThread):

   
    # Time in ns from the last packet being sent until the end of test is signalled to the DUT
    END_OF_TEST_TIME = 5000

    def __init__(self, name, rxd, rxa, rxdv, rxer, vld, txd, txv, txrdy, clock, initial_delay, verbose,
                 test_ctrl, do_timeout, complete_fn, expect_loopback, dut_exit_time):
        self._name = name
        self._test_ctrl = test_ctrl
        self._rxd = rxd    #Rx data
        self._rxa = rxa    #Rx Active
        self._rxdv = rxdv  #Rx valid
        self._rxer = rxer  #Rx Error
        self._vld = vld
        self._txd = txd
        self._txv = txv
        self._txrdy = txrdy
        self._packets = []
        self._clock = clock
        self._initial_delay = initial_delay
        self._verbose = verbose
        self._do_timeout = do_timeout
        self._complete_fn = complete_fn
        self._expect_loopback = expect_loopback
        self._dut_exit_time = dut_exit_time

    def get_name(self):
        return self._name

    def get_clock(self):
        return self._clock

    def start_test(self):
        self.wait_until(self.xsi.get_time() + self._initial_delay)
        self.wait(lambda x: self._clock.is_high())
        self.wait(lambda x: self._clock.is_low())

    def end_test(self):
        if self._verbose:
            print "All packets sent"

        if self._complete_fn:
            self._complete_fn(self)

        # Give the DUT a reasonable time to process the packet
        self.wait_until(self.xsi.get_time() + self.END_OF_TEST_TIME)

        if self._do_timeout:
            # Allow time for a maximum sized packet to arrive
            timeout_time = (self._clock.get_bit_time() * 1522 * 8)

            if self._expect_loopback:
                # If looping back then take into account all the data
                total_packet_bytes = sum([len(packet.get_bytes()) for packet in self._packets])
                total_data_bits = total_packet_bytes * 8

                # Allow 2 cycles per bit
                timeout_time += 2 * total_data_bits

                # The clock ticks are 2ns long
                timeout_time *= 2

                # The packets are copied to and from the user application
                timeout_time *= 2

            self.wait_until(self.xsi.get_time() + timeout_time)

            if self._test_ctrl:
                # Indicate to the DUT that the test has finished
                self.xsi.drive_port_pins(self._test_ctrl, 1)

            # Allow time for the DUT to exit
            self.wait_until(self.xsi.get_time() + self._dut_exit_time)

            print "ERROR: Test timed out"
            self.xsi.terminate()

    def set_clock(self, clock):
        self._clock = clock

    def set_packets(self, packets):
        self._packets = packets

    def drive_error(self, value):
        self.xsi.drive_port_pins(self._rxer, value)


class UsbPhy(TxPhy):

    def __init__(self, rxd, rxa, rxdv, rxer, vld, txd, txv, txrdy, clock,
                 initial_delay=85000, verbose=False, test_ctrl=None,
                 do_timeout=True, complete_fn=None, expect_loopback=True,
                 dut_exit_time=25000):
        super(UsbPhy, self).__init__('mii', rxd, rxa, rxdv, rxer, vld, txd, txv, txrdy, clock,
                                             initial_delay, verbose, test_ctrl,
                                             do_timeout, complete_fn, expect_loopback,
                                             dut_exit_time)

    def run(self):
        xsi = self.xsi

        self.start_test()

        for i,packet in enumerate(self._packets):
            #error_nibbles = packet.get_error_nibbles()
            
            if isinstance(packet, RxPacket):
 
                timeout = packet.get_timeout()
               
                #print "Expecting pkt. Timeout in: {i}".format(i=timeout)

                in_rx_packet = False
                rx_packet = []

                while timeout != 0:

                    self.wait(lambda x: self._clock.is_high())
                    self.wait(lambda x: self._clock.is_low())

                    timeout = timeout - 1
                    #print "{i}".format(i=timeout)

                    #sample TXV for new packet
                    if xsi.sample_port_pins(self._txv) == 1:
                        print "Receiving packet {}".format(i)
                        in_rx_packet = True
                        break
            
                if in_rx_packet == False:
                    print "ERROR: Timed out waiting for packet"

                else:
                    #print "in packet"
                    while in_rx_packet == True:
                        
                        # TODO txrdy pulsing
                        xsi.drive_port_pins(self._txrdy, 1)
                        data = xsi.sample_port_pins(self._txd)
                       
                        print "Received byte: {0:#x}".format(data)
                        rx_packet.append(data)

                        self.wait(lambda x: self._clock.is_high())
                        self.wait(lambda x: self._clock.is_low())

                        if xsi.sample_port_pins(self._txv) == 0:
                            #print "TXV low, breaking out of loop"
                            in_rx_packet = False
                   
                        

                    # End of packet
                    xsi.drive_port_pins(self._txrdy, 0)

                    # Check packet agaist expected
                    expected = packet.get_bytes()
                    if len(expected) != len(rx_packet):
                        print "ERROR: Rx packet length bad. Expecting: {} actual: {}".format(len(expected), len(rx_packet))
                
                    # Check packet data against expected
                    if cmp(expected, rx_packet):
                        print "ERROR: Rx Packet Error. Expected:"
                        for item in expected:
                            print "{0:#x}".format(item)

                        print "Received:" 
                        for item in rx_packet:
                            print "{0:#x}".format(item)
            else:

                
                # xCore should not be trying to send if we are trying to send..
                if xsi.sample_port_pins(self._txv) == 1:
                    print "ERROR: Unexpected packet from xCORE"

                rxv_count = packet.get_data_valid_count();

                #print "Waiting for inter_pkt_gap: {i}".format(i=packet.inter_frame_gap)
                self.wait_until(xsi.get_time() + packet.inter_pkt_gap)

                print "Sending packet {}".format(i)
                if self._verbose:
                    sys.stdout.write(packet.dump())

                # Set RXA high
                xsi.drive_port_pins(self._rxa, 1)

                # Wait for RXA rise delay TODO, this should be configurable 
                self.wait(lambda x: self._clock.is_high())
                self.wait(lambda x: self._clock.is_low())

                #if isinstance(packet, TokenPacket):
                 #   print "Token packet, clear valid token"
                xsi.drive_port_pins(self._vld, 0)

                for (i, byte) in enumerate(packet.get_bytes()):

                    # xCore should not be trying to send if we are trying to send..
                    if xsi.sample_port_pins(self._txv) == 1:
                        print "ERROR: Unexpected packet from xCORE"

                    self.wait(lambda x: self._clock.is_low())

                    self.wait(lambda x: self._clock.is_high())
                    self.wait(lambda x: self._clock.is_low())
                    xsi.drive_port_pins(self._rxdv, 1)
                    xsi.drive_port_pins(self._rxd, byte)
 
                    if (packet.rxe_assert_time != 0) and (packet.rxe_assert_time == i):
                        xsi.drive_port_pins(self._rxer, 1)

                    while rxv_count != 0:
                        self.wait(lambda x: self._clock.is_high())
                        self.wait(lambda x: self._clock.is_low())
                        xsi.drive_port_pins(self._rxdv, 0)
                        rxv_count = rxv_count - 1

                        # xCore should not be trying to send if we are trying to send..
                        if xsi.sample_port_pins(self._txv) == 1:
                            print "ERROR: Unexpected packet from xCORE"

                    #print "Sending byte {0:#x}".format(byte)

                    rxv_count = packet.get_data_valid_count();

                    if isinstance(packet, TokenPacket):
                        #print "Token packet, driving valid"
                        if packet.get_token_valid():
                            xsi.drive_port_pins(self._vld, 1)
                        else:
                            xsi.drive_port_pins(self._vld, 0)

                # Wait for last byte
                self.wait(lambda x: self._clock.is_high())
                self.wait(lambda x: self._clock.is_low())

                xsi.drive_port_pins(self._rxdv, 0)
                xsi.drive_port_pins(self._rxer, 0)

                rxa_end_delay = packet.rxa_end_delay
                while rxa_end_delay != 0:
                    # Wait for RXA fall delay TODO, this should be configurable 
                    self.wait(lambda x: self._clock.is_high())
                    self.wait(lambda x: self._clock.is_low())
                    rxa_end_delay = rxa_end_delay - 1
               
                    # xCore should not be trying to send if we are trying to send..
                    if xsi.sample_port_pins(self._txv) == 1:
                        print "ERROR: Unexpected packet from xCORE"

                xsi.drive_port_pins(self._rxa, 0)

                #if self._verbose:
                    #print "Sent"

        print "Test done"
        self.end_test()


class RxPhy(xmostest.SimThread):

    def __init__(self, name, txd, txen, clock, print_packets, packet_fn, verbose, test_ctrl):
        self._name = name
        self._txd = txd
        self._txen = txen
        self._clock = clock
        self._print_packets = print_packets
        self._verbose = verbose
        self._test_ctrl = test_ctrl
        self._packet_fn = packet_fn

        self.expected_packets = None
        self.expect_packet_index = 0
        self.num_expected_packets = 0

        self.expected_packets = None
        self.expect_packet_index = 0
        self.num_expected_packets = 0

    def get_name(self):
        return self._name

    def get_clock(self):
        return self._clock

    def set_expected_packets(self, packets):
        self.expect_packet_index = 0;
        self.expected_packets = packets
        if self.expected_packets is None:
            self.num_expected_packets = 0
        else:
            self.num_expected_packets = len(self.expected_packets)

class MiiReceiver(RxPhy):

    def __init__(self, txd, txen, clock, print_packets=False,
                 packet_fn=None, verbose=False, test_ctrl=None):
        super(MiiReceiver, self).__init__('mii', txd, txen, clock, print_packets,
                                          packet_fn, verbose, test_ctrl)

    def run(self):
        xsi = self.xsi
        self.wait(lambda x: xsi.sample_port_pins(self._txen) == 0)

        # Need a random number generator for the MiiPacket constructor but it shouldn't
        # have any affect as only blank packets are being created
        rand = random.Random()

        packet_count = 0
        last_frame_end_time = None
        while True:
            # Wait for TXEN to go high
            if self._test_ctrl is None:
                self.wait(lambda x: xsi.sample_port_pins(self._txen) == 1)
            else:
                self.wait(lambda x: xsi.sample_port_pins(self._txen) == 1 or \
                                    xsi.sample_port_pins(self._test_ctrl) == 1)

                if (xsi.sample_port_pins(self._txen) == 0 and
                      xsi.sample_port_pins(self._test_ctrl) == 1):
                    xsi.terminate()

            # Start with a blank packet to ensure they are filled in by the receiver
            packet = MiiPacket(rand, blank=True)

            frame_start_time = self.xsi.get_time()
            in_preamble = True

            if last_frame_end_time:
                ifgap = frame_start_time - last_frame_end_time
                packet.inter_frame_gap = ifgap

            while True:
                # Wait for a falling clock edge or enable low
                self.wait(lambda x: self._clock.is_low() or \
                                   xsi.sample_port_pins(self._txen) == 0)

                if xsi.sample_port_pins(self._txen) == 0:
                    last_frame_end_time = self.xsi.get_time()
                    break

                nibble = xsi.sample_port_pins(self._txd)
                if in_preamble:
                    if nibble == 0xd:
                        packet.set_sfd_nibble(nibble)
                        in_preamble = False
                    else:
                        packet.append_preamble_nibble(nibble)
                else:
                    packet.append_data_nibble(nibble)

                self.wait(lambda x: self._clock.is_high())

            packet.complete()

            if self._print_packets:
                sys.stdout.write(packet.dump())

            if self._packet_fn:
                self._packet_fn(packet, self)

            # Perform packet checks
            packet.check(self._clock)


