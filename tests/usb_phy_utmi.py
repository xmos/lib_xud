import random
import xmostest
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

        super(UsbPhyUtmi, self).__init__('mii', rxd, rxa, rxdv, rxer, txd, txv, txrdy, ls0, ls1, clock,
                                             initial_delay, verbose, test_ctrl,
                                             do_timeout, complete_fn, expect_loopback, dut_exit_time)
    def run(self):
        xsi = self.xsi

        self.start_test()

        for i,packet in enumerate(self._packets):
            
            #if isinstance(packet, BusReset):

             #  print "BUS RESET" 


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
                    expected = packet.get_bytes(do_tokens=False)
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

                #TxPacket (which could be a TxToken or TxDataPacket)
                
                # xCore should not be trying to send if we are trying to send..
                if xsi.sample_port_pins(self._txv) == 1:
                    print "ERROR: Unexpected packet from xCORE"

                rxv_count = packet.get_data_valid_count();

                #print "Waiting for inter_pkt_gap: {i}".format(i=packet.inter_frame_gap)
                self.wait_until(xsi.get_time() + packet.inter_pkt_gap)

                print "Phy transmitting packet {} PID: {} ({})".format(i, packet.get_pid_pretty(), packet.pid)
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

                for (i, byte) in enumerate(packet.get_bytes()):

                    # xCore should not be trying to send if we are trying to send..
                    if xsi.sample_port_pins(self._txv) == 1:
                        print "ERROR: Unexpected packet from xCORE"

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
                            print "ERROR: Unexpected packet from xCORE"

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
                        print "ERROR: Unexpected packet from xCORE"

                #xsi.drive_port_pins(self._rxa, 0)
                xsi.drive_periph_pin(self._rxa, 0)

                #if self._verbose:
                    #print "Sent"

        print "Test done"
        self.end_test()



