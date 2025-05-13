# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
from copy import deepcopy

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransactionHbw
from usb_packet import CreateSofToken, TokenPacket, TxDataPacket, USB_PID

# Only run for HS
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"bus_speed": ["HS"]})

@pytest.fixture
def test_session(ep, address, bus_speed):

    frameNumber = 0
    ep_len = 8
    pktLength = 12

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=50))
    frameNumber += 1

    # Send first MDATA
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
        )
    )
    payload = [1 for x in range(ep_len)]
    session.add_event(
        TxDataPacket(
            dataPayload=payload,
            pid=USB_PID["MDATA"]
        )
    )

    # lost DATA0 packet, should drop MDATA data

    session.add_event(CreateSofToken(frameNumber, interEventDelay=50))
    frameNumber += 1

    # healthy packet, but will be dropped, due to implementation details
    session.add_event(
        UsbTransactionHbw(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=70,
            ep_len=ep_len,
            resend=True
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=50))
    frameNumber += 1

    # healthy packet, this one should be recieved
    session.add_event(
        UsbTransactionHbw(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=70,
            ep_len=ep_len
        )
    )

    # data0 - no sof, should drop
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
            interEventDelay=50
        )
    )
    payload = [2 for x in range(ep_len)]
    session.add_event(
        TxDataPacket(
            dataPayload=payload,
            pid=USB_PID["DATA0"]
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=50))
    frameNumber += 1

    # healthy packet, this one should be recieved
    session.add_event(
        UsbTransactionHbw(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength + 1,
            interEventDelay=70,
            ep_len=ep_len
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=50))
    frameNumber += 1

    # data1 - wrong pid
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
        )
    )
    payload = [3 for x in range(ep_len)]
    session.add_event(
        TxDataPacket(
            dataPayload=payload,
            pid=USB_PID["DATA1"]
        )
    )

    # healthy packet, this one will be dropped
    session.add_event(CreateSofToken(frameNumber, interEventDelay=50))
    frameNumber += 1

    session.add_event(
        UsbTransactionHbw(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength + 2,
            interEventDelay=70,
            ep_len=ep_len,
        )
    )

    return session
