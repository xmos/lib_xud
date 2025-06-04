# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
from copy import deepcopy

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import CreateSofToken, TokenPacket, TxDataPacket, USB_PID
from usb_signalling import UsbSuspend, UsbResume

# |SOF MDATA DATA1   |SOF MDATA         | Suspend ... Resume | SOF MDATA DATA1  | SOF MDATA DATA1
# | Receive          |Partial transfer  |                    | Drop             | Receive

# Run at increased system frequency
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"core_freq": [600, 800]})

from usb_phy import USB_PKT_TIMINGS
INTER_TRANSACTION_DELAY = USB_PKT_TIMINGS["TX_TO_TX_PACKET_DELAY"]
def CustomUsbOutTransaction(session,
                            deviceAddress=0,
                            endpointNumber=0,
                            interEventDelay=INTER_TRANSACTION_DELAY,
                            payloads=[],
                            pids=[]
                         ):
    assert len(payloads)
    assert len(pids)
    assert len(payloads) == len(pids)
    for i in range(len(payloads)):
        session.add_event(
            TokenPacket(
                pid=USB_PID["OUT"],
                address=deviceAddress,
                endpoint=endpointNumber,
                interEventDelay=interEventDelay
            )
        )
        session.add_event(
            TxDataPacket(
                dataPayload=payloads[i],
                pid=USB_PID[pids[i]]
            )
        )

@pytest.fixture
def test_session(ep, address, bus_speed, core_freq):
    ep_len = 8
    start_length = 9
    end_length = start_length + 3
    frameNumber = 0
    sof_event_delay = 20
    out_token_event_delay = 15

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )
    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1
    # Send a good transfer. This should be received
    session.add_event(
            UsbTransaction(
                session,
                deviceAddress=address,
                endpointNumber=ep,
                endpointType="ISO",
                transType="OUT",
                dataLength=start_length,
                interEventDelay=out_token_event_delay,
                ep_len=ep_len
            )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1
    # Send partial transfer
    CustomUsbOutTransaction(session,
                        deviceAddress=address,
                        endpointNumber=ep,
                        pids=["MDATA"],
                        payloads=[[0xaa for x in range(ep_len)]]
        )

    # Send suspend followed by resume
    session.add_event(UsbSuspend(350000, suspendedPhy=False))
    session.add_event(UsbResume(suspendedPhy=False))

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # Send good transfer which will be dropped due to device error handling from the previous incomplete transfer
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=start_length+1,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len,
            resend=True
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # Send last transfer which will now be received
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=start_length+1,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len,
        )
    )

    if core_freq == 600:
        pytest.xfail("HBW 2txn test requires a 800MHz part")

    return session
