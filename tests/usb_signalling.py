
from usb_event import UsbEvent
from usb_phy import USB_LINESTATE, USB_TIMINGS



class UsbSuspend(UsbEvent): 

    # TODO create instance of Suspend with duracton in seconds and convert to clks?
    def __init__(self, duration, interEventDelay=0):
        self._duration = duration
        super().__init__(interEventDelay=interEventDelay)

    def expected_output(self, offset = 0):
        expected_output = "SUSPEND START. WAITING FOR DUT TO ENTER FS\n"
        expected_output += "DEVICE ENTERED FS\n"
        expected_output += "SUSPEND END\n"
        #for i in range(0, self._duration): 
        #    expected_output += "Suspend: {}\n".format(self._duration - i)
        return expected_output
        
    def __str__(self):
        return  "UsbSuspend: " + str(self._duration)

    @property
    def event_count(self):
        return 1

    def drive(self, usb_phy):

        xsi = usb_phy.xsi
        wait = usb_phy.wait


         # xCore should not be trying to send if we are trying to send..
        if xsi.sample_port_pins(usb_phy._txv) == 1:
            print("ERROR: Unexpected packet from xCORE")

        usb_phy.wait_until(xsi.get_time() + self.interEventDelay)

        # Drive IDLE state onto LS pins 
        xsi.drive_periph_pin(usb_phy._ls, USB_LINESTATE['IDLE'])
       
        # Within X uS device should transition to FS
        clocks_min = int(usb_phy.us_to_clocks(USB_TIMINGS['IDLE_TO_FS_MIN_US']))
        clocks_max = int(usb_phy.us_to_clocks(USB_TIMINGS['IDLE_TO_FS_MAX_US']))
        
        print("SUSPEND START. WAITING FOR DUT TO ENTER FS")
       
        print("clocks_min: " + str(clocks_min)) 
        print("clocks_max: " + str(clocks_max))

        clock_count = 0
        #for _ in range(0, clocks_max):
        while True: 

            wait(lambda x: usb_phy._clock.is_high())
            wait(lambda x: usb_phy._clock.is_low())
            
            # TODO check other pins
            if xsi.sample_port_pins(usb_phy._txv) == 1:
                print("ERROR: Unexpected packet from xCORE")

            xcvr = xsi.sample_periph_pin(usb_phy._xcvrsel)
            termsel = xsi.sample_periph_pin(usb_phy._termsel)

            clock_count+=1
            if xcvr == 1 and termsel == 1:
                print("DEVICE ENTERED FS AFTER " + str(clock_count) + "CLOCKS  (" + str(int((clock_count*usb_phy.clock.period_us))) + " uS)") 
                
                # Drive J state onto LS pins - replicate pullup 
                xsi.drive_periph_pin(usb_phy._ls, USB_LINESTATE['FS_J'])
                
                break

        print("SUSPEND END")

