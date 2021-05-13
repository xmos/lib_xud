# Copyright 2015-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import usb.core
import usb.util

# Find XMOS USBTMC test device
dev = usb.core.find(idVendor=0x20B1, idProduct=0x2337)


import usbtmc

instr = usbtmc.Instrument(0x20B1, 0x2337)

# Test SCPI commands
# ------------------

print("Starting basic SCPI commands testing...")
print("")

# Request device identification details
print(instr.ask("*IDN?"))

# Reset device; this command is not implemented!
print(instr.ask("*RST"))
print("")

# Fetch DC voltage value from the device
print(instr.ask("*MEASure:VOLTage:DC?"))


print("Exiting...")
