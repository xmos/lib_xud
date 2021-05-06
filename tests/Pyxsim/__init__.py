
"""
Pyxsim pytest framework

This module provides functions to run tests for XMOS applications and libraries.
"""
import sys
import Pyxsim.pyxsim
import platform
import multiprocessing


def do_run_pyxsim(xe, simargs, appargs, simthreads):
    xsi = pyxsim.Xsi(xe_path=xe, simargs=simargs, appargs=appargs)
    for x in simthreads:
        xsi.register_simthread(x)
    xsi.run()
    xsi.terminate()

def run_with_pyxsim(xe, simthreads, xscope_io = False, loopback=[],
            		simargs=[], appargs=[],
            		suppress_multidrive_messages=False, tester=None, timeout=600,
            		initial_delay=None, start_after_started=[],
            		start_after_completed=[]):
       
        p = multiprocessing.Process(target=do_run_pyxsim, args=(xe, simargs, appargs, simthreads))
        p.start() 
        p.join(timeout=timeout)
        if p.is_alive():
            sys.stderr.write("Simulator timed out\n")
            p.terminate()
        return None

def run_tester(caps, tester_list):
    separate_word = [index for index, element in enumerate(caps) if element.strip() == "Test done"]
    result = []
    if len(separate_word) > 1:
        i = 0
        start = 0
        stop = 0
        while(i<len(separate_word)):
            if i == 0:
                stop = separate_word[i]+1
            else:
                start = separate_word[i-1]+1
                stop = separate_word[i]+1
            re_cap = caps[start:stop]
            result.append(tester_list[i].run(re_cap)) 
            i += 1
    else:
        result.append(tester_list[0].run(caps[:separate_word[0]+1])) 
    return result

class SimThread(object):
    def run(self, xsi):
        pass

    def wait(self, f):
        self.xsi._user_wait(f)

    def wait_for_port_pins_change(self, ps):
        self.xsi._wait_for_port_pins_change(ps)

    def wait_for_next_cycle(self):
        self.xsi._wait_for_next_cycle()

    def wait_until(self, t):
        self.xsi._wait_until(t)
