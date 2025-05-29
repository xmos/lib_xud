# Copyright 2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

import pytest
from copy import deepcopy

from conftest import PARAMS, test_RunUsbSession  # noqa F401

PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    # fixing everything but the arch
    # none of these are used in the test
    PARAMS[k].update({"ep" : [1]})
    PARAMS[k].update({"address" : [1]})
    PARAMS[k].update({"bus_speed" : ["HS"]})
    PARAMS[k].update({"dummy_threads" : [5]})
    PARAMS[k].update({"core_freq" : [600]})

@pytest.fixture
def test_session(ep, address, bus_speed):
    return None
