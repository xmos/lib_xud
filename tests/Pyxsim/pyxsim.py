# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from ctypes import (
    cdll,
    byref,
    c_void_p,
    c_char_p,
    c_int,
    create_string_buffer,
)
import os
import re
import struct
import sys
import threading
import traceback

from Pyxsim.xe import Xe
from Pyxsim.testers import TestError
from Pyxsim.xmostest_subprocess import platform_is_windows

ALL_BITS = 0xFFFFFF

if platform_is_windows():
    xsi_lib_path = os.path.abspath(
        os.environ["XCC_EXEC_PREFIX"] + "../lib/xsidevice.dll"
    )
else:
    xsi_lib_path = os.path.abspath(
        os.environ["XCC_EXEC_PREFIX"] + "../lib/libxsidevice.so"
    )

xsi_lib = cdll.LoadLibrary(xsi_lib_path)


def xsi_is_valid_port(port):
    return re.match(r"XS1_PORT_\d+\w", port) is not None


def xsi_get_port_width(port):
    if not xsi_is_valid_port(port):
        return None
    return int(re.match(r"^XS1_PORT_(\d+)\w", port).groups(0)[0])


class EnumExceptionSet:
    def __init__(self, enum_list, valid_list=[]):
        self.enum_list = enum_list
        self.valid_list = valid_list

    def __getattr__(self, name):
        if name in self.enum_list:
            return self.enum_list.index(name)
        raise AttributeError

    def is_valid(self, value):
        if value < len(self.enum_list):
            enum = self.enum_list[value]
            return enum in self.valid_list
        raise IndexError

    def error_if_not_valid(self, value):
        if value < len(self.enum_list):
            enum = self.enum_list[value]
            if enum not in self.valid_list:
                raise type("XSI_ERROR_" + enum, (Exception,), {})

    def error(self, value):
        if value < len(self.enum_list):
            enum = self.enum_list[value]
            raise type("XSI_ERROR_" + enum, (Exception,), {})


XsiStatus = EnumExceptionSet(
    [
        "OK",
        "DONE",
        "TIMEOUT",
        "INVALID_FILE",
        "INVALID_INSTANCE",
        "INVALID_TILE",
        "INVALID_PACKAGE",
        "INVALID_PIN",
        "INVALID_PORT",
        "MEMORY_ERROR",
        "PSWITCH_ERROR",
        "INVALID_ARGS",
        "NULL_ARG",
        "INCOMPATIBLE_VERSION",
    ],
    valid_list=["OK", "DONE"],
)


def parse_port(p):
    m = re.match(r"(tile.*)\:([^\.]*)\.?(\d*)", p)
    if m:
        tile = m.groups(0)[0]
        port = m.groups(0)[1]
        bit = m.groups(0)[2]
        if bit == "":
            bit = None
        if bit is not None:
            bit = int(bit)
    else:
        raise TestError("Cannot parse port: %s" % p)
    if bit is not None:
        mask = 1 << bit
    else:
        mask = ALL_BITS
    return (tile, port, bit, mask)


def parse_periph_pin(p):
    m = re.match("^[^_]+_([^_]+)_([^_]+)", p)
    if m:
        perif = m.groups(0)[0]
        pin = m.groups(0)[1]
    else:
        raise TestError("Cannot parse periph pin: %s" % p)
    mask = ALL_BITS
    return (perif, pin, mask)


class SimThreadImpl(threading.Thread):
    def __init__(self, xsi, st, args):
        def _fn(*args):
            st.run(*args)

        super().__init__()
        self._fn = _fn
        self._args = args
        self.get_time = xsi.get_time
        self.resume_event = threading.Event()
        self.complete_event = threading.Event()
        self._xsi = xsi
        self.had_exception = False
        self.terminate_flag = False
        st.xsi = self
        self.resume_condition = None

    def _wait(self, resume_check):
        self.resume_condition = resume_check
        self.complete_event.set()
        self.resume_event.wait()
        self.resume_event.clear()

    def _user_wait(self, resume_check):
        def _resume(xsi):
            return resume_check(self)

        self._wait(_resume)

    def _wait_until(self, time):
        def _resume(xsi):
            return xsi.get_time() >= time

        self._wait(_resume)

    def _wait_for_port_pins_change(self, ps):
        is_driving = []
        vals = []
        ps = [(self._xsi.xe.get_port_pins(p)[0], parse_port(p)) for p in ps]
        for ((package, pin, _), (tile, p, bit, mask)) in ps:
            d = self._xsi.is_pin_driving(package, pin)
            is_driving.append(d)
            if d:
                v = self._xsi.sample_port_pins(tile, p, mask)
                if bit:
                    v = v >> bit
                vals.append(v)
            else:
                vals.append(0)

        def _resume(xsi):
            for i, psval in enumerate(ps):
                (package, pin, _), (tile, p, bit, mask) = psval
                d = xsi.is_pin_driving(package, pin)
                if d != is_driving[i]:
                    return True
                if d:
                    v = xsi.sample_port_pins(tile, p, mask)
                    if bit:
                        v = v >> bit
                else:
                    v = 0
                if v != vals[i]:
                    return True
            return False

        self._wait(_resume)

    def _wait_for_next_cycle(self):
        self._wait(lambda x: True)

    def is_port_driving(self, port):
        (package, pin, _) = self._xsi.xe.get_port_pins(port)[0]
        return self._xsi.is_pin_driving(package, pin)

    def drive_port_pins(self, port, val):
        (tile, p, bit, mask) = parse_port(port)
        if bit:
            val <<= bit
        self._xsi.drive_port_pins(tile, p, mask, val)

    def sample_port_pins(self, port):
        (tile, p, bit, mask) = parse_port(port)
        val = self._xsi.sample_port_pins(tile, p, mask)
        if bit:
            val >>= bit
        return val

    # TODO make this pin*s*
    def drive_periph_pin(self, pin, val):
        (periph, pin, mask) = parse_periph_pin(pin)
        self._xsi.drive_periph_pin(periph, pin, mask, val)

    # TODO make this pin*s*
    def sample_periph_pin(self, pin):
        (periph, pin, mask) = parse_periph_pin(pin)
        return self._xsi.sample_periph_pin(periph, pin, mask)

    def terminate(self):
        self.terminate_flag = True
        self._wait(lambda x: False)

    def run(self):
        args = self._args
        try:
            self._fn(*args)
        except:  ## noqa E722
            self.had_exception = True
            sys.stderr.write("---------Exception in simthread--------------\n")
            traceback.print_exc()
            sys.stderr.write("---------------------------------------------\n")
        self.resume_condition = lambda x: False
        self.complete_event.set()


class Xsi():
    def __init__(self, xe_path=None, simargs=[], appargs=[]):
        self.xsim = c_void_p()
        self.xe_path = xe_path
        args = " ".join(
            ['"{}"'.format(x) for x in simargs + [self.xe_path] + appargs]
        )
        if platform_is_windows():
            args = args.replace("\\", "/")
        c_args = c_char_p(args.encode("utf-8"))
        xsi_lib.xsi_create(byref(self.xsim), c_args)
        self._plugins = []
        self._simthreads = []
        self._time = 0
        self.xe = Xe(self.xe_path)
        self._time_step = 1000.0 / self.xe.freq

    def register_plugin(self, plugin):
        self._plugins.append(plugin)

    def register_simthread(self, fn):
        if isinstance(fn, tuple):
            xs = list(fn)
            fn = xs[0]
            args = xs[1:]
        else:
            args = []

        simthread = SimThreadImpl(self, fn, args)
        simthread.daemon = True
        self._simthreads.append(simthread)

    @staticmethod
    def wait_for_simthread(simthread):
        simthread.complete_event.wait()
        simthread.complete_event.clear()
        if simthread.had_exception:
            raise TestError("Simthread encoutered an exception")

    def clock(self):
        status = xsi_lib.xsi_clock(self.xsim)
        self._time += self._time_step
        if XsiStatus.is_valid(status):
            for plugin in self._plugins:
                plugin.clock(self)
            for simthread in self._simthreads:
                if simthread.resume_condition(self):
                    simthread.resume_event.set()
                    self.wait_for_simthread(simthread)
                    if simthread.terminate_flag:
                        return XsiStatus.DONE

        return status

    def get_time(self):
        return self._time

    def run(self):
        status = XsiStatus.OK
        for simthread in self._simthreads:
            simthread.start()
            self.wait_for_simthread(simthread)

        while status != XsiStatus.DONE:
            status = self.clock()
            XsiStatus.error_if_not_valid(status)

    def terminate(self):
        status = xsi_lib.xsi_terminate(self.xsim)
        XsiStatus.error_if_not_valid(status)

    def sample_pin(self, package, pin):
        c_package = c_char_p(package)
        c_pin = c_char_p(pin)
        c_value = c_int()
        status = xsi_lib.xsi_sample_pin(
            self.xsim, c_package, c_pin, byref(c_value)
        )
        XsiStatus.error_if_not_valid(status)
        return c_value.value

    def sample_port_pins(self, tile, port, mask):
        c_tile = c_char_p(tile.encode("utf-8"))
        c_port = c_char_p(port.encode("utf-8"))
        c_mask = c_int(mask)
        c_value = c_int()
        status = xsi_lib.xsi_sample_port_pins(
            self.xsim, c_tile, c_port, c_mask, byref(c_value)
        )
        XsiStatus.error_if_not_valid(status)
        return c_value.value

    def drive_pin(self, package, pin, value):
        c_package = c_char_p(package)
        c_pin = c_char_p(pin)
        c_value = c_int(value)
        status = xsi_lib.xsi_drive_pin(self.xsim, c_package, c_pin, c_value)
        XsiStatus.error_if_not_valid(status)

    def drive_port_pins(self, tile, port, mask, value):
        c_tile = c_char_p(tile.encode("utf-8"))
        c_port = c_char_p(port.encode("utf-8"))
        c_mask = c_int(mask)
        c_value = c_int(value)
        status = xsi_lib.xsi_drive_port_pins(
            self.xsim, c_tile, c_port, c_mask, c_value
        )
        XsiStatus.error_if_not_valid(status)

    # TOOD make this pin*s*
    def drive_periph_pin(self, periph, pin, mask, value):
        c_periph = c_char_p(periph.encode("utf-8"))
        c_pin = c_char_p(pin.encode("utf-8"))
        c_mask = c_int(mask)
        c_value = c_int(value)
        status = xsi_lib.xsi_drive_periph_pin(
            self.xsim, c_periph, c_pin, c_mask, c_value
        )
        XsiStatus.error_if_not_valid(status)

    # TOOD make this pin*s*
    def sample_periph_pin(self, periph, pin, mask):
        c_periph = c_char_p(periph.encode("utf-8"))
        c_pin = c_char_p(pin.encode("utf-8"))
        c_mask = c_int(mask)
        c_value = c_int()
        status = xsi_lib.xsi_sample_periph_pin(
            self.xsim, c_periph, c_pin, c_mask, byref(c_value)
        )
        XsiStatus.error_if_not_valid(status)
        return c_value.value

    def is_pin_driving(self, package, pin):
        c_package = c_char_p(package)
        c_pin = c_char_p(pin)
        c_value = c_int()
        status = xsi_lib.xsi_is_pin_driving(
            self.xsim, c_package, c_pin, byref(c_value)
        )
        XsiStatus.error_if_not_valid(status)
        return c_value.value

    def is_port_pins_driving(self, tile, port):
        c_tile = c_char_p(tile)
        c_port = c_char_p(port)
        c_value = c_int()
        status = xsi_lib.xsi_is_port_pins_driving(
            self.xsim, c_tile, c_port, byref(c_value)
        )
        XsiStatus.error_if_not_valid(status)
        return c_value.value

    def read_mem(self, tile, address, num_bytes, return_ctype=False):
        c_tile = c_char_p(tile)
        c_address = c_int(address)
        c_num_bytes = c_int(num_bytes)
        buf = create_string_buffer(num_bytes)
        status = xsi_lib.xsi_read_mem(
            self.xsim, c_tile, c_address, c_num_bytes, buf
        )
        XsiStatus.error_if_not_valid(status)
        if return_ctype:
            return buf
        return list(buf)

    def read_symbol_word(self, tile, symbol, offset=0):
        address = self.xe.symtab[tile, symbol]
        address += offset
        buf = self.read_mem(tile, address, 4, return_ctype=True)
        return struct.unpack("<I", buf)

    def read_symbol_byte(self, tile, symbol, offset=0):
        address = self.xe.symtab[tile, symbol]
        address += offset
        buf = self.read_mem(tile, address, 1, return_ctype=True)
        return ord(buf[0])

    def write_mem(self, tile, address, num_bytes, data):
        c_tile = c_char_p(tile)
        c_address = c_int(address)
        c_num_bytes = c_int(num_bytes)
        buf = create_string_buffer(data)
        status = xsi_lib.xsi_write_mem(
            self.xsim, c_tile, c_address, c_num_bytes, buf
        )
        XsiStatus.error_if_not_valid(status)

    def write_symbol_word(self, tile, symbol, value, offset=0):
        address = self.xe.symtab[tile, symbol]
        address += offset
        data = struct.pack("<I", value)
        self.write_mem(tile, address, 4, data)

    def write_symbol_byte(self, tile, symbol, value, offset=0):
        address = self.xe.symtab[tile, symbol]
        address += offset
        data = struct.pack("<c", value)
        self.write_mem(tile, address, 1, data)

    def read_pswitch_reg(self, tile, reg_num):
        c_tile = c_char_p(tile)
        c_reg_num = c_int(reg_num)
        c_value = c_int()
        status = xsi_lib.xsi_read_pswitch_reg(
            self.xsim, c_tile, c_reg_num, byref(c_value)
        )
        XsiStatus.error_if_not_valid(status)
        return c_value.value

    def write_pswitch_reg(self, tile, reg_num, value):
        c_tile = c_char_p(tile)
        c_reg_num = c_int(reg_num)
        c_value = c_int(value)
        status = xsi_lib.xsi_write_pswitch_reg(
            self.xsim, c_tile, c_reg_num, c_value
        )
        XsiStatus.error_if_not_valid(status)


class XsiPlugin():
    def clock(self, xsi):
        pass


class XsiLoopbackPlugin(XsiPlugin):
    def __init__(
        self,
        tile="tile[0]",
        from_port="XS1_PORT_1A",
        to_port="XS1_PORT_1B",
        from_mask=None,
        to_mask=None,
    ):
        self.from_port = from_port
        self.to_port = to_port
        self.tile = tile
        if from_mask is None:
            self.from_mask = (1 << (xsi_get_port_width(from_port))) - 1
        else:
            self.from_mask = from_mask
        if to_mask is None:
            self.to_mask = (1 << (xsi_get_port_width(from_port))) - 1
        else:
            self.to_mask = to_mask

    def clock(self, xsi):
        value = xsi.sample_port_pins(self.tile, self.from_port, self.from_mask)
        xsi.drive_port_pins(self.tile, self.to_port, self.to_mask, value)
