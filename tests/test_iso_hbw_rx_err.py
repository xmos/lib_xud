# Copyright 2016-2025 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import pytest
from copy import deepcopy

from conftest import PARAMS, test_RunUsbSession  # noqa F401
from usb_session import UsbSession
from usb_transaction import UsbTransaction
from usb_packet import CreateSofToken, TokenPacket, TxDataPacket, USB_PID
# Case1: error at transaction 1, unexpected SOF
# | SOF MDATA | SOF MDATA | SOF MDATA | SOF MDATA | SOF MDATA DATA0 | SOF MDATA DATA1 |
# |   drop    |    drop   |     drop  |     drop  |       drop      |   receive       |

# Case2: error at transaction 1, wrong PID (MDATA)
# | SOF MDATA MDATA | SOF MDATA MDATA | SOF MDATA MDATA | SOF MDATA MDATA | SOF MDATA DATA1 | SOF MDATA DATA1 |
# |   drop          |    drop         |     drop        |     drop        |       drop      |     receive     |

# Case3: error at transaction 1, wrong PID (DATA0)
# | SOF MDATA DATA0 | SOF MDATA DATA0 | SOF MDATA DATA0 | SOF MDATA DATA0 | SOF MDATA DATA1 |
# |   drop          |    drop         |     drop        |     drop        |       receive   |


# Case4: error at transaction 0, missing SOF
# DATA0     DATA0     DATA0     DATA0     | SOF MDATA DATA1 |
# drop      drop      drop      drop      | receive         |

# Case5: error at transaction 0, wrong PID (DATA1)
# | SOF DATA1 | SOF DATA1 | SOF DATA1 | SOF DATA1 | SOF MDATA DATA1 |
# | drop      | drop      | drop      | drop      | receive         |

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

# Run at increased system frequency
PARAMS = deepcopy(PARAMS)
for k in PARAMS:
    PARAMS[k].update({"core_freq": [600, 800]})

@pytest.fixture
def test_session(ep, address, bus_speed, core_freq):
    frameNumber = 0
    ep_len = 8
    pktLength = 12
    num_error_transfers = 4 # No. of errorneous transfers before a correct one is sent
    sof_event_delay = 20
    out_token_event_delay = 15

    session = UsbSession(
        bus_speed=bus_speed, run_enumeration=False, device_address=address
    )

    # Case1: error at transaction 1, unexpected SOF
    # Partial transfers with only MDATA transaction (missing DATA1)
    for _ in range(num_error_transfers):
        session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
        frameNumber += 1
        CustomUsbOutTransaction(session,
                        deviceAddress=address,
                        endpointNumber=ep,
                        pids=["MDATA"],
                        payloads=[[0xaa for x in range(ep_len)]]
        )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # healthy packet, but will be dropped, due to implementation details
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len,
            resend=True
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # healthy packet, this one should be recieved
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len
        )
    )

    # Case2: error at transaction 1, wrong PID (MDATA)
    for _ in range(num_error_transfers):
        session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
        frameNumber += 1

        CustomUsbOutTransaction(session,
                                deviceAddress=address,
                                endpointNumber=ep,
                                interEventDelay=out_token_event_delay,
                                pids=["MDATA", "MDATA"],
                                payloads=[[0xaa for x in range(ep_len)], [0xaa for x in range(ep_len)]]
        )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # healthy packet, but will be dropped, due to implementation details
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength+1,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len,
            resend=True
        )
    )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1
    # healthy packet, this one should be recieved
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength+1,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len,
        )
    )

    # Case3: error at transaction 1, wrong PID (DATA0)
    for _ in range(num_error_transfers):
        session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
        frameNumber += 1
        CustomUsbOutTransaction(session,
                        deviceAddress=address,
                        endpointNumber=ep,
                        interEventDelay=out_token_event_delay,
                        pids=["MDATA", "DATA0"],
                        payloads=[[0xaa for x in range(ep_len)], [0xaa for x in range(ep_len)]]
        )


    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # healthy packet, this one should be recieved
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength+2,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len,
        )
    )

    # Case4: error at transaction 0, no SOF
    # data0 - no sof, should drop
    for _ in range(num_error_transfers):
        CustomUsbOutTransaction(session,
                deviceAddress=address,
                endpointNumber=ep,
                interEventDelay=out_token_event_delay,
                pids=["DATA0"],
                payloads=[[0xaa for x in range(ep_len)]]
        )

    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    # healthy packet, this one should be recieved
    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength + 3,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len
        )
    )

    # Case5: error at transaction 0, wrong PID (DATA1)
    for _ in range(num_error_transfers):
        session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
        frameNumber += 1

        CustomUsbOutTransaction(session,
                deviceAddress=address,
                endpointNumber=ep,
                interEventDelay=out_token_event_delay,
                pids=["DATA1"],
                payloads=[[0xaa for x in range(ep_len)]]
        )

    # healthy packet, this one will be received
    session.add_event(CreateSofToken(frameNumber, interEventDelay=sof_event_delay))
    frameNumber += 1

    session.add_event(
        UsbTransaction(
            session,
            deviceAddress=address,
            endpointNumber=ep,
            endpointType="ISO",
            transType="OUT",
            dataLength=pktLength + 4,
            interEventDelay=out_token_event_delay,
            ep_len=ep_len,
        )
    )

    if core_freq == 600:
        pytest.xfail("HBW 2txn test requires a 800MHz part")

    return session
