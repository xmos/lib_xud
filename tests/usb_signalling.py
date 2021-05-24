# Copyright 2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from usb_event import UsbEvent
from usb_phy import USB_LINESTATE, USB_TIMINGS


class UsbResume(UsbEvent):
    def __init__(self, duration=USB_TIMINGS["RESUME_FSK_MIN_US"], interEventDelay=0):
        self._duration = duration
        super().__init__(interEventDelay=interEventDelay)

    def expected_output(self, bus_speed, offset=0):
        expected_output = "RESUME\n"
        expected_output += "RESUME END\n"

        if bus_speed == "HS":
            expected_output += (
                "DUT ENTERED HS MODE\n"  # TODO only if was in HS pre-suspend
            )

        return expected_output

    def __str__(self):
        return "UsbResume: " + str(self._duration)

    @property
    def event_count(self):
        return 1

    def drive(self, usb_phy, bus_speed):
        xsi = usb_phy.xsi
        wait = usb_phy.wait

        # xCore should not be trying to send if we are trying to send..
        if xsi.sample_port_pins(usb_phy._txv) == 1:
            print("ERROR: Unexpected packet from xCORE")

        resumeStartTime_ns = xsi.get_time()

        # print("RESUME: " + str(resumeStartTime_ns))
        print("RESUME")

        # Drive resume signalling
        xsi.drive_periph_pin(usb_phy._ls, USB_LINESTATE["FS_K"])

        while True:
            wait(lambda x: usb_phy._clock.is_high())
            wait(lambda x: usb_phy._clock.is_low())

            currentTime_ns = xsi.get_time()
            if currentTime_ns >= resumeStartTime_ns + (
                USB_TIMINGS["RESUME_FSK_MIN_US"] * 1000
            ):
                break

        endResumeStartTime_ns = xsi.get_time()
        # print("TB SE0: " + str(endResumeStartTime_ns))
        xsi.drive_periph_pin(usb_phy._ls, USB_LINESTATE["IDLE"])

        while True:
            wait(lambda x: usb_phy._clock.is_high())
            wait(lambda x: usb_phy._clock.is_low())

            currentTime_ns = xsi.get_time()
            if currentTime_ns >= endResumeStartTime_ns + (
                USB_TIMINGS["RESUME_SE0_US"] * 1000
            ):
                break

        print("RESUME END")
        # print("RESUME END: " + str(currentTime_ns))

        if bus_speed == "HS":
            # Check that the DUT has re-entered HS
            xcvrsel = xsi.sample_periph_pin(usb_phy._xcvrsel)
            termsel = xsi.sample_periph_pin(usb_phy._termsel)

            if xcvrsel == 1:
                print("ERROR: DUT did not enter HS after resume (XCVRSel)")

            if termsel == 1:
                print("ERROR: DUT did not enter HS after resume (TermSel)")

            print("DUT ENTERED HS MODE")


class UsbSuspend(UsbEvent):

    # TODO create instance of Suspend with duracton in seconds and convert to clks?
    def __init__(self, duration_ns, interEventDelay=0):
        self._duration_ns = duration_ns
        super().__init__(interEventDelay=interEventDelay)

    def expected_output(self, bus_speed, offset=0):
        expected_output = "SUSPEND START. WAITING FOR DUT TO ENTER FS\n"
        expected_output += "DEVICE ENTERED FS MODE\n"
        expected_output += "SUSPEND END\n"
        return expected_output

    def __str__(self):
        return "UsbSuspend: " + str(self._duration_ns)

    @property
    def event_count(self):
        return 1

    def drive(self, usb_phy, bus_speed):

        xsi = usb_phy.xsi
        wait = usb_phy.wait

        # xCore should not be trying to send if we are trying to send..
        if xsi.sample_port_pins(usb_phy._txv) == 1:
            print("ERROR: Unexpected packet from xCORE")

        suspendStartTime_ns = xsi.get_time()
        # print("SUSPEND START TIME: " + str(suspendStartTime_ns))

        assert self.interEventDelay == 0

        # Drive IDLE state onto LS pins
        xsi.drive_periph_pin(usb_phy._ls, USB_LINESTATE["IDLE"])

        # Within X uS device should transition to FS
        print("SUSPEND START. WAITING FOR DUT TO ENTER FS")

        while True:

            wait(lambda x: usb_phy._clock.is_high())
            wait(lambda x: usb_phy._clock.is_low())

            # TODO check other pins
            if xsi.sample_port_pins(usb_phy._txv) == 1:
                print("ERROR: Unexpected packet from xCORE")

            xcvr = xsi.sample_periph_pin(usb_phy._xcvrsel)
            termsel = xsi.sample_periph_pin(usb_phy._termsel)

            # Wait for DUT to move into FS mode
            if xcvr == 1 and termsel == 1:

                fsTime_ns = xsi.get_time()
                timeToFs_ns = fsTime_ns - suspendStartTime_ns
                # print("DEVICE ENTERED FS AT TIME " + str(fsTime_ns/1000) + "(after " + str(timeToFs_ns/1000) +" uS)")
                print("DEVICE ENTERED FS MODE")

                if bus_speed == "HS":
                    if timeToFs_ns < (USB_TIMINGS["IDLE_TO_FS_MIN_US"] * 1000):
                        print("ERROR: DUT ENTERED FS MODE TOO SOON")

                # Drive J state onto LS pins - replicate pullup
                xsi.drive_periph_pin(usb_phy._ls, USB_LINESTATE["FS_J"])
                break

            time_ns = xsi.get_time() - suspendStartTime_ns
            if time_ns > (USB_TIMINGS["IDLE_TO_FS_MAX_US"] * 1000):
                print("ERROR: DUT DID NOT ENTER FS MODE IN TIME")

        # Wait for end of suspend
        while True:

            wait(lambda x: usb_phy._clock.is_high())
            wait(lambda x: usb_phy._clock.is_low())

            # xCore should not be trying to send if we are trying to send..
            if xsi.sample_port_pins(usb_phy._txv) == 1:
                print("ERROR: Unexpected packet from xCORE")

            xcvr = xsi.sample_periph_pin(usb_phy._xcvrsel)
            termsel = xsi.sample_periph_pin(usb_phy._termsel)

            # Wait for DUT to move into FS mode
            if not (xcvr == 1 and termsel == 1):
                print("ERROR: DUT moved out of FS mode unexpectly during suspend")

            time_ns = xsi.get_time() - suspendStartTime_ns
            if time_ns == self._duration_ns:
                # print("SUSPEND END: " + str(xsi.get_time()))
                print("SUSPEND END")
                break
