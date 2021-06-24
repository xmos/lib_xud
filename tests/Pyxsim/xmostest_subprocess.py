# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import platform
import re
import subprocess
import sys
import tempfile
import multiprocessing
import time
import os
import signal
import errno
from Pyxsim.testers import TestError


def pstreekill(process):
    pid = process.pid
    if platform_is_windows():
        # Try allowing a clean shutdown first
        subprocess.call(["taskkill", "/t", "/pid", str(pid)])
        confirmed_termination = False
        timeout = time.time() + 10  # Timeout in seconds
        while time.time() < timeout:
            # Check the current status of the process
            status = subprocess.call(["tasklist", "/nh", "/fi", '"PID eq %s"' % pid])
            if status.startswith(
                "INFO: No tasks are running which match the specified criteria"
            ):
                # Process has shutdown
                confirmed_termination = True
                break
            time.sleep(0.1)  # Avoid spinning too fast while in the timeout loop
        if not confirmed_termination:
            # If the process hasn't shutdown politely yet kill it
            sys.stdout.write("Force kill PID %d that hasn't responded to kill\n" % pid)
            subprocess.call(["taskkill", "/t", "/f", "/pid", str(pid)])
    else:
        # Send SIGINT to the process group to notify all processes that we
        # are going down now
        os.killpg(os.getpgid(pid), signal.SIGINT)

        # Now terminate and join the main process.  If the join has not returned
        # within 10 seconds then we will have to forcibly kill the process group
        process.terminate()
        process.join(timeout=10)

        if process.is_alive():
            # If the process hasn't shutdown politely yet kill it
            try:
                sys.stderr.write(
                    "Sending SIGKILL to PID %d that hasn't responded to SIGINT\n" % pid
                )
                os.killpg(os.getpgid(pid), signal.SIGKILL)
            except OSError as err:
                # ESRCH == No such process - presumably exited since timeout...
                if err.errno != errno.ESRCH:
                    raise


## Annoying OS incompatability, not sure why this is needed


def log_debug(msg):
    pass


def platform_is_osx():
    ostype = platform.system()
    if re.match(".*Darwin.*", ostype):
        return True
    else:
        return False


def platform_is_windows():
    ostype = platform.system()
    if not re.match(".*Darwin.*", ostype) and re.match(".*[W|w]in.*", ostype):
        return True
    else:
        return False


if platform_is_windows():
    concat_args = True
    use_shell = True
    # Windows version of Python 2.7 doesn't support SIGINT
    if sys.version_info < (3, 0):
        raise TestError(
            "Doesn't support Python version < 3, please upgrade to Python 3 or higher."
        )
    SIGINT = signal.SIGTERM
else:
    concat_args = False
    use_shell = False
    SIGINT = signal.SIGINT


def quote_string(s):
    """For Windows need to put quotes around arguments with spaces in them"""
    if re.search(r"\s", s):
        return '"%s"' % s
    else:
        return s


def Popen(*args, **kwargs):
    kwargs["shell"] = use_shell
    if concat_args:
        args = (" ".join([quote_string(arg) for arg in args[0]]),) + args[1:]
        cmd = args[0]
    else:
        cmd = " ".join(args[0])

    log_debug("Run '%s' in %s" % (cmd, kwargs.get("cwd", ".")))
    return subprocess.Popen(*args, **kwargs)


def wait_with_timeout(p_and_sig, timeout):
    (ev, pidv, process) = p_and_sig
    process.start()
    try:
        if timeout:
            finished = ev.wait(timeout)
            if not finished:
                pstreekill(process)
            return (not finished, 0)
        else:
            ev.wait()
            return (False, 0)
    except KeyboardInterrupt:
        pstreekill(process)

    return (False, 0)


def do_cmd(ev, pidv, *args, **kwargs):
    if not platform_is_windows():
        os.setpgid(os.getpid(), 0)
    if "stdout_fname" in kwargs:
        fname = kwargs.pop("stdout_fname")
        kwargs["stdout"] = open(fname, "w")
    if "stderr_fname" in kwargs:
        fname = kwargs.pop("stderr_fname")
        kwargs["stderr"] = open(fname, "w")
    process = Popen(*args, **kwargs)
    pidv.value = process.pid
    try:
        process.wait()
    except KeyboardInterrupt:
        # Catch the KeyboardInterrupt raised due to the SIGINT signal
        # sent by pstreekill()
        pass
    ev.set()


def create_cmd_process(*args, **kwargs):
    ev = multiprocessing.Event()
    pidv = multiprocessing.Value("d", 0)
    args = tuple([ev, pidv] + list(args))
    process = multiprocessing.Process(target=do_cmd, args=args, kwargs=kwargs)

    return (ev, pidv, process)


def remove(name):
    """On windows, OS.remove() will cause an exception if the file is still in use.
    It is assumed there is a release race, hence the multiple attempts here.
    """
    attempt = 0
    while attempt < 3:
        try:
            os.remove(name)
            return
        except OSError:
            attempt = attempt + 1
            time.sleep(0.1 * attempt)
    sys.stdout.write("ERROR: Unable to remove file `%s`\n" % name)


def call(*args, **kwargs):
    """If silent, then create temporary files to pass stdout and stderr to since
    on Windows the less/more-like behaviour waits for a keypress if it goes to stdout.
    """
    silent = kwargs.pop("silent", False)
    retval = 0
    timeout = None
    if "timeout" in kwargs:
        timeout = kwargs["timeout"]
        kwargs.pop("timeout")

    if silent:
        out = tempfile.NamedTemporaryFile(delete=False)
        kwargs["stdout_fname"] = out.name
        kwargs["stderr"] = subprocess.STDOUT

        process = create_cmd_process(*args, **kwargs)
        (timed_out, retval) = wait_with_timeout(process, timeout)
        out.seek(0)
        stdout_lines = out.readlines()
        out.close()
        remove(out.name)
        for line in stdout_lines:
            line = line.decode("utf-8")
            log_debug("     " + line.rstrip())
    else:
        process = create_cmd_process(*args, **kwargs)
        (timed_out, retval) = wait_with_timeout(process, timeout)
        # Ensure spawned processes are not left running past this point
        # There should be no children running now (as they would be orphaned)
        process[2].terminate()
        process[2].join(timeout=0.1)  # Avoid always printing wait message
        while process[2].is_alive():
            sys.stdout.write("Waiting for PID %d to terminate\n" % process[2].pid)
            process[2].join(timeout=1.0)

    if timeout:
        return (timed_out, retval)
    else:
        return retval


def call_get_output(*args, **kwargs):
    """Create temporary files to pass stdout and stderr to since on Windows the
    less/more-like behaviour waits for a keypress if it goes to stdout.
    """
    merge = kwargs.pop("merge_out_and_err", False)

    out = tempfile.NamedTemporaryFile(delete=False)
    kwargs["stdout_fname"] = out.name
    timeout = None
    if "timeout" in kwargs:
        timeout = kwargs["timeout"]
        kwargs.pop("timeout")

    if merge:
        kwargs["stderr"] = subprocess.STDOUT
    else:
        err = tempfile.NamedTemporaryFile(delete=False)
        stderr_fname = err.name
        kwargs["stderr_fname"] = stderr_fname
        err.close()

    process = create_cmd_process(*args, **kwargs)
    (timed_out, retval) = wait_with_timeout(process, timeout)
    out.seek(0)
    stdout_lines = out.readlines()
    out.close()
    remove(out.name)

    for line in stdout_lines:
        line = line.decode("utf-8")
        log_debug("     " + line.rstrip())

    if not merge:
        err = open(stderr_fname, "r")
        stderr_lines = err.readlines()
        err.close()
        remove(stderr_fname)
        for line in stderr_lines:
            line = line.decode("utf-8")
            log_debug("     err:" + line.rstrip())

    if merge:
        if timeout:
            return (timed_out, stdout_lines)
        else:
            return stdout_lines

    else:
        if timeout:
            return (timed_out, stdout_lines, stderr_lines)
        else:
            return (stdout_lines, stderr_lines)
