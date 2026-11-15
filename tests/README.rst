lib_xud tests
=============

The tests run ``lib_xud`` in the simulator against a Python model of a USB
host and PHY, using ``test_support``. They need the XTC Tools environment and
a Python virtual environment.

Set up
......

From this directory, inside a virtual environment::

    python -m pip install -r requirements.txt

Each test's application has a ``CMakeLists.txt`` that includes the shared
``test_app.cmake``. That declares one build configuration for each
combination of test parameters. The core frequency selects the XN file, so
configure one build directory for each frequency the tests use::

    cmake -G "Unix Makefiles" -B build_600 -DTEST_FREQ=600
    cmake -G "Unix Makefiles" -B build_800 -DTEST_FREQ=800

Nothing is compiled at this point. Each test builds the configuration it is
about to run, the first time it needs it.

Running
.......

To run all tests::

    pytest -n auto --testlevel=<level>

To run one test file::

    pytest -n auto --testlevel=<level> <test_name>.py

``<level>`` is ``smoke``, ``default`` or ``extended``, in increasing order of
the number of parameter combinations; the default is ``default``.
``--enabletracing`` writes instruction traces to ``logs``.
