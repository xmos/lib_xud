

from usb_event import UsbEvent

class UsbSuspend(UsbEvent): 

    # TODO create instance of Suspend with duracton in seconds and convert to clks?
    def __init__(self, duration, interEventDelay=1):
        self._duration = duration
        super().__init__(interEventDelay=interEventDelay)

    def expected_output(self, offset = 0):
        expected_output = ""
        for i in range(0, self._duration): 
            expected_output += "Suspend: {}\n".format(self._duration - i)
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

        # Drive J state onto LS pins 
        xsi.drive_periph_pin(usb_phy._ls, 1)
        
        duration = self._duration_clks
      
        while duration > 0: 
            print("Suspend: {0})".format(duration))
            wait(lambda x: usb_phy._clock.is_high())
            wait(lambda x: usb_phy._clock.is_low())
            duration = duraton -1 
