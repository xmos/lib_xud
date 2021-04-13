# Copyright (c) 2016-2019, XMOS Ltd, All rights reserved
import random
import xmostest
import sys
import zlib
from usb_packet import RxPacket, TokenPacket
import usb_packet

class UsbPhy(xmostest.SimThread):

    # Time in ns from the last packet being sent until the end of test is signalled to the DUT
    END_OF_TEST_TIME = 5000

    def __init__(self, name, rxd, rxa, rxdv, rxer, txd, txv, txrdy, ls0, ls1, clock, initial_delay, verbose,
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
        self.ls0 = ls0
        self.ls1 = ls1
        self._packets = []
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

    def start_test(self):
        self.wait_until(self.xsi.get_time() + self._initial_delay)
        self.wait(lambda x: self._clock.is_high())
        self.wait(lambda x: self._clock.is_low())

    def end_test(self):
        if self._verbose:
            print("All packets sent")

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

            print("ERROR: Test timed out")
            self.xsi.terminate()

    def set_clock(self, clock):
        self._clock = clock

    def set_packets(self, packets):
        self._packets = packets

    def drive_error(self, value):
        self.xsi.drive_port_pins(self._rxer, value)

    def run(self):

        xsi = self.xsi

        self.start_test()

        for i,packet in enumerate(self._packets):
            
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
                        print("Receiving packet {}".format(i))
                        in_rx_packet = True
                        break
            
                if in_rx_packet == False:
                    print("ERROR: Timed out waiting for packet")
                else:
                    while in_rx_packet == True:
                        
                        # TODO txrdy pulsing
                        xsi.drive_port_pins(self._txrdy, 1)
                        data = xsi.sample_port_pins(self._txd)
                       
                        print("Received byte: {0:#x}".format(data))
                        rx_packet.append(data)

                        self.wait(lambda x: self._clock.is_high())
                        self.wait(lambda x: self._clock.is_low())

                        if xsi.sample_port_pins(self._txv) == 0:
                            #print "TXV low, breaking out of loop"
                            in_rx_packet = False
                    
                    # End of packet
                    xsi.drive_port_pins(self._txrdy, 0)

                    # Check packet against expected
                    expected = packet.get_bytes(do_tokens=self._do_tokens)
                    if len(expected) != len(rx_packet):
                        print("ERROR: Rx packet length bad. Expecting: {} actual: {}".format(len(expected), len(rx_packet)))
                
                    # Check packet data against expected
                    if expected != rx_packet:
                        print("ERROR: Rx Packet Error. Expected:")
                        for item in expected:
                            print("{0:#x}".format(item))

                        print("Received:") 
                        for item in rx_packet:
                            print("{0:#x}".format(item))

            else:

                #TxPacket (which could be a TxToken or TxDataPacket)
                
                # xCore should not be trying to send if we are trying to send..
                if xsi.sample_port_pins(self._txv) == 1:
                    print("ERROR: Unexpected packet from xCORE")

                rxv_count = packet.get_data_valid_count();

                #print "Waiting for inter_pkt_gap: {i}".format(i=packet.inter_frame_gap)
                self.wait_until(xsi.get_time() + packet.inter_pkt_gap)

                print("Phy transmitting packet {} PID: {} ({})".format(i, packet.get_pid_pretty(), packet.pid))
                if self._verbose:
                    sys.stdout.write(packet.dump())

                # Set RXA high
                #xsi.drive_port_pins(self._rxa, 1)
                xsi.drive_periph_pin(self._rxa, 1)

                # Wait for RXA start delay
                rxa_start_delay = usb_packet.RXA_START_DELAY;

                while rxa_start_delay != 0:
                    self.wait(lambda x: self._clock.is_high())
                    self.wait(lambda x: self._clock.is_low())
                    rxa_start_delay = rxa_start_delay- 1;

                for (i, byte) in enumerate(packet.get_bytes(do_tokens = self._do_tokens)):
                
                    # xCore should not be trying to send if we are trying to send..
                    if xsi.sample_port_pins(self._txv) == 1:
                        print("ERROR: Unexpected packet from xCORE")

                    self.wait(lambda x: self._clock.is_low())

                    self.wait(lambda x: self._clock.is_high())
                    self.wait(lambda x: self._clock.is_low())
                    xsi.drive_periph_pin(self._rxdv, 1)
                    xsi.drive_periph_pin(self._rxd, byte)
 
                    if (packet.rxe_assert_time != 0) and (packet.rxe_assert_time == i):
                        #xsi.drive_port_pins(self._rxer, 1)
                        xsi.drive_periph_pin(self._rxer, 1)

                    while rxv_count != 0:
                        self.wait(lambda x: self._clock.is_high())
                        self.wait(lambda x: self._clock.is_low())
                        xsi.drive_periph_pin(self._rxdv, 0)
                        rxv_count = rxv_count - 1

                        # xCore should not be trying to send if we are trying to send..
                        if xsi.sample_port_pins(self._txv) == 1:
                            print("ERROR: Unexpected packet from xCORE")

                    #print "Sending byte {0:#x}".format(byte)

                    rxv_count = packet.get_data_valid_count();

                # Wait for last byte
                self.wait(lambda x: self._clock.is_high())
                self.wait(lambda x: self._clock.is_low())

                xsi.drive_periph_pin(self._rxdv, 0)
                xsi.drive_periph_pin(self._rxer, 0)

                rxa_end_delay = packet.rxa_end_delay
                while rxa_end_delay != 0:
                    # Wait for RXA fall delay TODO, this should be configurable 
                    self.wait(lambda x: self._clock.is_high())
                    self.wait(lambda x: self._clock.is_low())
                    rxa_end_delay = rxa_end_delay - 1
               
                    # xCore should not be trying to send if we are trying to send..
                    if xsi.sample_port_pins(self._txv) == 1:
                        print("ERROR: Unexpected packet from xCORE")

                #xsi.drive_port_pins(self._rxa, 0)
                xsi.drive_periph_pin(self._rxa, 0)

                #if self._verbose:
                    #print "Sent"

        print("Test done")
        self.end_test()







