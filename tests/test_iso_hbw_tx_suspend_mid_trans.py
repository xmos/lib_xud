# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
from copy import deepcopy

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_packet import CreateSofToken, TokenPacket, USB_PID, RxDataPacket
from usb_transaction import UsbTransaction
from usb_signalling import UsbSuspend, UsbResume

# SOF DATA1 DATA0 | SOF DATA1         | Suspend ... Resume | SOF DATA0           | SOF DATA1 DATA0
# good frame      | partial transfer  |                    | detect error at     | good frame
#                 |                   |                    | the this            |
#                 |                   |                    | transaction finish  |

# Run at increased system frequency
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"core_freq": [600, 800]})

@pytest.fixture
def test_session(ep, address, bus_speed, core_freq):
    start_length = 9
    end_length = 10
    frameNumber = 0
    ep_len = 8
    sof_event_delay = 20
    in_token_event_delay = 30

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # Receive a good transfer
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="IN",
            dataLength=start_length,
            interEventDelay=in_token_event_delay,
            ep_len=ep_len
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1
    # Do partial transfer
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
            interEventDelay=in_token_event_delay
        )
    )
    payload = session.getPayload_in(ep, ep_len)
    session.add_event(RxDataPacket(dataPayload=payload, pid=USB_PID["DATA1"]))

    # Send suspend followed by resume
    session.add_event(UsbSuspend(350000, suspendedPhy=False))
    session.add_event(UsbResume(suspendedPhy=False))

    # TODO Why is such a big interEventDelay needed after suspend/resume
    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay+80))
    frameNumber += 1

    # Do remaining transfer
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
            interEventDelay=in_token_event_delay
        )
    )
    payload = session.getPayload_in(ep, start_length + 1 - ep_len)
    session.add_event(RxDataPacket(dataPayload=payload, pid=USB_PID["DATA0"]))

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # Receive a good transfer
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="IN",
            dataLength=start_length+2,
            interEventDelay=in_token_event_delay,
            ep_len=ep_len
        )
    )

    if core_freq == 600:
        pytest.xfail("HBW 2txn test requires a 800MHz part")

    return session
