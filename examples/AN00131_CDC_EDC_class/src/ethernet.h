// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _ETHERNET_H_
#define _ETHERNET_H_

#include "xud_ecm.h"

extern int ipAddressServer;
extern int ipAddressClient;
extern const char macAddressServer[6];
extern const char macAddressClient[6];

struct packet_stats_t
{
    unsigned int total_tx_packets;
    unsigned int total_rx_packets;

    unsigned int arp_rx_packets;
    unsigned int tcp_rx_packets;
    unsigned int udp_rx_packets;
    unsigned int icmp_rx_packets;

    unsigned int total_rx_bytes;
    unsigned int total_tx_bytes;
};

extern struct packet_stats_t stats;

void EthernetFrameHandler(client interface usb_cdc_ecm_if cdc_ecm);

void onesChecksum(unsigned int startsum, unsigned short data[], int begin, int end, int to);

void getMacAddressString(unsigned char * unsafe addr);

#endif
