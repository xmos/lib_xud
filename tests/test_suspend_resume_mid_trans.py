# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_packet import CreateSofToken
from usb_signalling import UsbSuspend, UsbResume
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_phy import USB_PKT_TIMINGS
from usb_packet import TokenPacket, USB_PID


@pytest.fixture
def test_session(ep, address, bus_speed):

    pktLength = 10
    frameNumber = 52  # Note, for frame number 52 we expect A5 34 40 on the bus

    interEventDelay = USB_PKT_TIMINGS["TX_TO_TX_PACKET_DELAY"]

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=0,
        )
    )

    session.add_event(CreateSofToken(frameNumber))

    # Simulate suspend (or unplug?) mid trans
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep,
        )
    )

    session.add_event(UsbSuspend(350000, suspendedPhy=False))
    session.add_event(UsbResume(suspendedPhy=False))

    frameNumber = frameNumber + 1
    session.add_event(CreateSofToken(frameNumber, interEventDelay=2000))

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="BULK",
            transType="OUT",
            dataLength=pktLength + 1,
            interEventDelay=interEventDelay,
        )
    )
    '''
    TODO Sending an extra packet as a hack workaround the issue where got_sof is seen as 0 in XUD_GetBuffer_Finish()
    for the first OUT packet received after resume.
    This is because a the driver sets sp[STACK_SOF_FRAME] after a suspend while ep->saved_frame which is the last seen
    value of sp[STACK_SOF_FRAME] in XUD_GetBuffer_Finish() is not reset and continues to be 1. Since sp[STACK_SOF_FRAME]
    is reset after suspend, the sp[STACK_SOF_FRAME] value after suspend -> resume -> sof -> out packet is 1 which is the same
    as ep->saved_frame, so the OUT packet after suspend sees got_sof = 0 and is dropped.
    To workaround this, I send one more packet before suspend, so ep->saved_frame can be 2 and doesn't match sp[STACK_SOF_FRAME] = 1
    after suspend and the OUT packet is not dropped.

    Note: this is only a temporary hack and needs to be fixed!!
    '''
    # Also check Iso EP
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep + 1,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=500,
        )
    )

    frameNumber = frameNumber + 1
    session.add_event(CreateSofToken(frameNumber))

    # Also check Iso EP
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep + 1,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength+1,
            interEventDelay=500,
        )
    )

    frameNumber = frameNumber + 1
    session.add_event(CreateSofToken(frameNumber))

    # Simulate suspend (or unplug?) mid trans
    session.add_event(
        TokenPacket(
            pid=USB_PID["OUT"],
            address=address,
            endpoint=ep + 1,
        )
    )

    session.add_event(UsbSuspend(350000, suspendedPhy=False))
    session.add_event(UsbResume(suspendedPhy=False))

    frameNumber = frameNumber + 1
    session.add_event(CreateSofToken(frameNumber, interEventDelay=2000))

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep + 1,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength + 2,
            interEventDelay=100,
        )
    )

    return session
