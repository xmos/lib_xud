#!/usr/bin/env python
# Copyright (c) 2016-2021, XMOS Ltd, All rights reserved
import xmostest
import argparse
import os
import re
import shutil
import helpers
from helpers import ARCHITECTURE_CHOICES, BUSSPEED_CHOICES

XN_FILES = ["test_xs2.xn", "test_xs3.xn"]

def list_test_dirs(args, path = ".", pattern = '^test_*'):
    dirs = os.listdir(path)
    test_dirs = [dir for dir in dirs if os.path.isdir(dir) and re.match(pattern, dir)]
    return test_dirs

def copy_common_xn_files(args, path = ".", common_dir = "shared_src", source_dir = "src", xn_files = XN_FILES):
    test_dirs = list_test_dirs(args, path)
    for test_dir in test_dirs:
        src_dir = os.path.join(test_dir, source_dir)
        for xn_file in xn_files:
            xn = os.path.join(common_dir, xn_file)
            shutil.copy(xn, src_dir)

def delete_test_specific_xn_files(args, path = ".", source_dir = "src", xn_files = XN_FILES):
    test_dirs = list_test_dirs(args, path)
    for test_dir in test_dirs:
        src_dir = os.path.join(test_dir, source_dir)
        for xn_file in xn_files:
            xn = os.path.join(src_dir, xn_file)
            os.remove(xn)

def prologue(args):
    copy_common_xn_files(args)

def epilogue(args):
    delete_test_specific_xn_files(args)



if __name__ == "__main__":
    global trace
    argparser = argparse.ArgumentParser(description="XMOS lib_xud tests")
    argparser.add_argument('--trace', action='store_true', help='Run tests with simulator and VCD traces')
    argparser.add_argument('--arch', choices=ARCHITECTURE_CHOICES, type=str, help='Run tests only on specified xcore architecture')
    argparser.add_argument('--seed', type=int, help='The seed', default=None)
    argparser.add_argument('--verbose', action='store_true', help='Enable verbose tracing in the phys')
    argparser.add_argument('--busspeed', choices=BUSSPEED_CHOICES, type=str, help='Speed of USB to run test at')

    
    helpers.args = xmostest.init(argparser)

    prologue(helpers.args)

    try:
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

    finally:
        epilogue(helpers.args)
