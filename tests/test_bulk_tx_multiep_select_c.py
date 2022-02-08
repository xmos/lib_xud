# Copyright 2022 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from copy import deepcopy

import pytest
import random

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction

# EP numbers currently fixed for this test - set in params
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"ep": [3]})

from test_bulk_tx_multiep_select import test_session
