#!/usr/bin/env python
# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import xmostest
import argparse

import helpers

if __name__ == "__main__":
    global trace
    argparser = argparse.ArgumentParser(description="XMOS lib_xud tests")
    argparser.add_argument('--trace', action='store_true', help='Run tests with simulator and VCD traces')
    argparser.add_argument('--arch', choices=['xs1', 'xs2'], type=str, help='Run tests only on specified xcore architecture')
    argparser.add_argument('--clk', choices=['25Mhz', '125Mhz'], type=str, help='Run tests only at specified clock speed')
    argparser.add_argument('--mac', choices=['rt', 'rt_hp', 'standard'], type=str, help='Run tests only on specified MAC')
    argparser.add_argument('--seed', type=int, help='The seed', default=None)
    argparser.add_argument('--verbose', action='store_true', help='Enable verbose tracing in the phys')

    argparser.add_argument('--num-packets', type=int, help='Number of packets in the test', default='100')
    argparser.add_argument('--data-len-min', type=int, help='Minimum packet data bytes', default='46')
    argparser.add_argument('--data-len-max', type=int, help='Maximum packet data bytes', default='500')
    
    helpers.args = xmostest.init(argparser)

   # xmostest.register_group("lib_xud",
   #                         "xud_sim_tests",
   #                         "XUD simulator tests",
   # """
#Tests are performed by running the GPIO library connected to a simulator model
#(written as a python plugin to xsim). The simulator model checks that the pins
#are driven and read by the ports as expected. Tests are run to test the
#following features:
#
#    * Inputting on a multibit port with multiple clients using the default pin map
#    * Inputting on a multibit port with multiple clients using a specified pin map
#    * Inputting on a 1bit port
#    * Inputting with timestamps
#    * Eventing on a multibit input port
#    * Eventing on a 1bit input port
#    * Outputting on a multibit port with multiple clients using the default pin map
#    * Outputting on a multibit port with multiple clients using a specified pin map
#    * Outputting with timestamps
#""")
#'''
  #  xmostest.runtests()

    xmostest.finish()
