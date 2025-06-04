# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
from copy import deepcopy

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_packet import CreateSofToken, TokenPacket, RxDataPacket, USB_PID
from usb_transaction import UsbTransaction

# Tested sequence
# SOF DATA1 | SOF DATA0            | SOF DATA1 DATA0 | DATA0        | SOF DATA0 DATA1
#           | Unexpected SOF       |  Good transfer  | Missing SOF  | Good transfer
#           |                      |                 |              |
#           | XUD_SetBuffer_Finish |                 | Will attempt | Resend DATA0
#           | returns XUD_RES_ERR  |                 | to sync with | from last
#           | to client            |                 | SOF          | transaction


# Run at increased system frequency
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"core_freq": [600, 800]})

@pytest.fixture
def test_session(ep, address, bus_speed, core_freq):

    frameNumber = 0
    ep_len = 8
    pktLength = 12

    sof_event_delay = 20
    in_token_event_delay = 30

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # starting normally
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
        )
    )
    payload = session.getPayload_in(ep, ep_len)
    session.add_event(RxDataPacket(dataPayload=payload, pid=USB_PID["DATA1"]))

    # sof before data0, oops
    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # will have to recive the remaining data0
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
        )
    )
    payload = session.getPayload_in(ep, pktLength - ep_len)
    session.add_event(RxDataPacket(dataPayload=payload, pid=USB_PID["DATA0"]))

    # at this point host sees data0 and should either discard it or do something else
    # but data0 always marks the last transaction, so sending sof
    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # after the sof the host will recieve a new frame
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="IN",
            dataLength=pktLength + 1,
            interEventDelay=in_token_event_delay,
            ep_len=8
        )
    )

    # no sof here, should send data1
    # generous delay here due app error handling
    session.add_event(
        TokenPacket(
            pid=USB_PID["IN"],
            address=address,
            endpoint=ep,
            interEventDelay=55
        )
    )
    payload = session.getPayload_in(ep, ep_len, resend=True)
    session.add_event(RxDataPacket(dataPayload=payload, pid=USB_PID["DATA1"]))

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # next packet after sof should be normal and resend the old data
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="IN",
            dataLength=pktLength + 2,
            interEventDelay=in_token_event_delay,
            ep_len=8
        )
    )

    if core_freq == 600:
        pytest.xfail("HBW 2txn test requires a 800MHz part")

    return session
