#!/usr/bin/env python
import xmostest
import argparse

import helpers

def copy_common_xn_files(args):
    pass

def delete_test_specific_xn_files(args):
    pass

def prologue(args):
    pass

def epilogue(args):
    pass

if __name__ == "__main__":
    global trace
    argparser = argparse.ArgumentParser(description="XMOS lib_xud tests")
    argparser.add_argument('--trace', action='store_true', help='Run tests with simulator and VCD traces')
    argparser.add_argument('--arch', choices=['xs2', 'xs3'], type=str, help='Run tests only on specified xcore architecture')
    argparser.add_argument('--seed', type=int, help='The seed', default=None)
    argparser.add_argument('--verbose', action='store_true', help='Enable verbose tracing in the phys')
    
    helpers.args = xmostest.init(argparser)

    prologue(helpers.args)

    xmostest.register_group("lib_xud",
                            "xud_sim_tests",
                            "XUD simulator tests",
    """
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
    xmostest.runtests()

    xmostest.finish()

    epilogue(helpers.args)
