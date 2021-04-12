// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xclib.h>
#include <print.h>
#include <stdio.h>
#include <assert.h>
#include "packet_buffer.h"
#include "ethernet.h"
#include "femtoIP.h"
#include "femtoUDP.h"
#include "femtoTCP.h"
#include "dhcp.h"

/* IP Addresses of the USB device (Server) and the Host PC (Client) */
int ipAddressServer   = 0xA9FE5555;
int ipAddressClient = 0xA9FEAAAA;
unsigned char ipAddressServerArray[4] = {169, 254, 85, 85};
unsigned char ipAddressClientArray[4] = {169, 254, 170, 170};

/* MAC Addresses of the USB device and the Host PC */
const char macAddressServer[6] = {0x00, 0x22, 0x97, 0x08, 0xA0, 0x02};
const char macAddressClient[6] = {0x00, 0x22, 0x97, 0x08, 0xA0, 0x03};

/* Server name as found in the DNS query */
unsigned char localName[] = "\x08xmos-cdc\x05local";

struct packet_stats_t stats;

void initPacketStats()
{
    stats.total_tx_packets = 0;
    stats.total_rx_packets = 0;
    stats.arp_rx_packets = 0;
    stats.tcp_rx_packets = 0;
    stats.udp_rx_packets = 0;
    stats.icmp_rx_packets = 0;
    stats.total_rx_bytes = 0;
    stats.total_tx_bytes = 0;
}

void getMacAddressString(unsigned char * unsafe addr) {
    unsafe {
    for(int i = 0; i < 6; i++) {
        sprintf(addr + (2*i), "%.2x", macAddressClient[i]);
    }
    }
}

void onesChecksum(unsigned int sum, unsigned short data[], int begin, int end, int to) {
    for(int i = begin; i <= end; i++) {
        sum += byterev(data[i]) >> 16;
    }
    sum = (sum & 0xffff) + (sum >> 16);
    sum = (sum & 0xffff) + (sum >> 16);
    data[to] = byterev((~sum) & 0xffff) >> 16;
}

static int makeGratuitousArp(unsigned int packet[]) {
    packet[0] = 0xffffffff;
    packet[1] = 0xffffffff;
    packet[3] = 0x01000608;
    packet[4] = 0x04060008;
    packet[5] = 0x00000100;
    packet[7] = byterev(ipAddressServer);
    packet[8] = 0;
    packet[9] = ((unsigned)byterev(ipAddressServer)) << 16;
    packet[10] = ((unsigned)byterev(ipAddressServer)) >> 16;
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressServer[i];
        (packet, char[])[22+i] = macAddressServer[i];
    }
    return 42;
}

static int makeOrdinaryArp(unsigned int packet[]) {
    packet[0] = 0xffffffff;
    packet[1] = 0xffffffff;
    packet[3] = 0x01000608;
    packet[4] = 0x04060008;
    packet[5] = 0x00000200;
    packet[7] = byterev(ipAddressServer);
    packet[8] = 0;
    packet[9] = ((unsigned)byterev(ipAddressClient)) << 16;
    packet[10] = ((unsigned)byterev(ipAddressClient)) >> 16;
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressServer[i];
        (packet, char[])[22+i] = macAddressServer[i];
    }
    return 42;
}

static int makeICMPReply(unsigned int rxbuf[], unsigned int txbuf[]) {
    unsigned icmp_checksum;
    int datalen;
    int totallen;
    const int ttl = 0x40;
    int pad;

    // Precomputed empty IP header checksum (inverted, bytereversed and shifted right)
    unsigned ip_checksum = 0x0185;

    for (int i = 0; i < 6; i++)
    {
        (txbuf, unsigned char[])[i] = (rxbuf, unsigned char[])[6 + i];
    }
    for (int i = 0; i < 4; i++)
    {
        (txbuf, unsigned char[])[30 + i] = (rxbuf, unsigned char[])[26 + i];
    }
    icmp_checksum = byterev((rxbuf, const unsigned[])[9]) >> 16;
    for (int i = 0; i < 4; i++)
    {
        (txbuf, unsigned char[])[38 + i] = (rxbuf, unsigned char[])[38 + i];
    }
    totallen = byterev((rxbuf, const unsigned[])[4]) >> 16;
    datalen = totallen - 28;

    for (int i = 0; i < datalen; i++)
    {
          (txbuf, unsigned char[])[42 + i] = (rxbuf, unsigned char[])[42+i];
    }

    for (int i = 0; i < 6; i++)
    {
      (txbuf, unsigned char[])[6 + i] = macAddressServer[i];
    }
    (txbuf, unsigned[])[3] = 0x00450008;
    totallen = byterev(28 + datalen) >> 16;
    (txbuf, unsigned[])[4] = totallen;
    ip_checksum += totallen;
    (txbuf, unsigned[])[5] = 0x01000000 | (ttl << 16);
    (txbuf, unsigned[])[6] = 0;
    for (int i = 0; i < 4; i++)
    {
      (txbuf, unsigned char[])[26 + i] = ipAddressServerArray[i];
    }
    ip_checksum += (ipAddressServerArray[0] | ipAddressServerArray[1] << 8);
    ip_checksum += (ipAddressServerArray[2] | ipAddressServerArray[3] << 8);
    ip_checksum += (txbuf, unsigned char[])[30] | ((txbuf, unsigned char[])[31] << 8);
    ip_checksum += (txbuf, unsigned char[])[32] | ((txbuf, unsigned char[])[33] << 8);

    (txbuf, unsigned char[])[34] = 0x00;
    (txbuf, unsigned char[])[35] = 0x00;

    icmp_checksum = (icmp_checksum + 0x0800);
    icmp_checksum += icmp_checksum >> 16;
    (txbuf, unsigned char[])[36] = icmp_checksum >> 8;
    (txbuf, unsigned char[])[37] = icmp_checksum & 0xFF;

    while (ip_checksum >> 16)
    {
      ip_checksum = (ip_checksum & 0xFFFF) + (ip_checksum >> 16);
    }
    ip_checksum = byterev(~ip_checksum) >> 16;
    (txbuf, unsigned char[])[24] = ip_checksum >> 8;
    (txbuf, unsigned char[])[25] = ip_checksum & 0xFF;

    for (pad = 42 + datalen; pad < 64; pad++)
    {
      (txbuf, unsigned char[])[pad] = 0x00;
    }
    return pad;
}

static int makeMDNSResponse(unsigned int packet[]) {
    int k;
    packet[10] = 0x00000000;
    packet[11] = 0x00000084;
    packet[12] = 0x00000100;
    packet[13] = 0x00000100;
    k = 54;
    for(int i = 0; i < sizeof(localName); i++) {
        (packet, char[])[k++] = localName[i];
    }
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0x80;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 255; // TTL2
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 4;
    (packet, char[])[k++] = ipAddressServer >> 24;
    (packet, char[])[k++] = ipAddressServer >> 16;
    (packet, char[])[k++] = ipAddressServer >> 8;
    (packet, char[])[k++] = ipAddressServer >> 0;


    for(int i = 0; i < sizeof(localName); i++) {
        (packet, char[])[k++] = localName[i];
    }
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 47;
    (packet, char[])[k++] = 0x80;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 255; // TTL2
    (packet, char[])[k++] = 0; // data length
    (packet, char[])[k++] = 10; // data length
    (packet, char[])[k++] = 5;
    (packet, char[])[k++] = 'l';
    (packet, char[])[k++] = 'o';
    (packet, char[])[k++] = 'c';
    (packet, char[])[k++] = 'a';
    (packet, char[])[k++] = 'l';
    (packet, char[])[k++] = 0; // Domain name end
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0x40;


    (packet, char[])[k] = 0x00;

    patchUDPHeader(packet, k, 0xe00000fb, 0xe914, 0xe914);
    return k;
}


/* Task to handle Ethernet frames received from USB endpoints */
void EthernetFrameHandler(client interface usb_cdc_ecm_if cdc_ecm)
{
    unsigned int rx_buf[MAX_FRAME_SIZE/sizeof(int)];
    unsigned rx_len;

    unsigned int tx_buf[MAX_FRAME_SIZE/sizeof(int)];
    unsigned tx_len;

    printstrln("--XMOS USB CDC-ECM Class demo--");
    printstr("\nServer IP Address: ");
    for(int i = 0; i < 4; i++) {
        printint(ipAddressServerArray[i]);
        if(i != 3) printchar('.');
    }
    printstrln("");
    printstrln("Server URL: http://xmos-cdc.local");
    while(1) {
        /* Blocking wait call to read a received ethernet frame */
        cdc_ecm.read_frame((rx_buf, unsigned char[]), rx_len);
        stats.total_rx_packets++;
        stats.total_rx_bytes += rx_len;

        /* Get packet type */
        int type = (rx_buf, short[])[6];

        if (type == 0x0608) { // ARP packet
            stats.arp_rx_packets++;
            if ((rx_buf, short[])[14] == (rx_buf, short[])[19] &&
                (rx_buf, short[])[15] == (rx_buf, short[])[20]) {

                int ip = byterev((rx_buf, unsigned int[])[7]);
                if (ip != ipAddressClient) {     // They missed DHCP and fell back to link local
                    ipAddressClient = ip;
                    if (ip == ipAddressServer) {   // Bum - they grabbed our address.
                        ipAddressServer = ip+1;
                    }
                }

                tx_len = makeGratuitousArp((tx_buf, unsigned int[]));
                cdc_ecm.send_frame((tx_buf, unsigned char[]), tx_len);
                stats.total_tx_packets++;
                stats.total_tx_bytes += tx_len;
                tx_len = 0;
                continue;
            }
            if ((rx_buf, short[])[20] == -1 ||
                (rx_buf, short[])[20] == (byterev(ipAddressServer)>>16) ) {
                tx_len = makeOrdinaryArp((tx_buf, unsigned int[]));
                cdc_ecm.send_frame((tx_buf, unsigned char[]), tx_len);
                stats.total_tx_packets++;
                stats.total_tx_bytes += tx_len;
                tx_len = 0;
            }

        } else if (type == 0x0008) { // IP packet
            int protocol = (rx_buf, unsigned char[])[23];

            if (protocol == 0x11) { // UDP
                stats.udp_rx_packets++;
                int destPort = (rx_buf, unsigned short[])[18];
                int srcPort = (rx_buf, unsigned short[])[17];
                if (destPort == 0x4300 && srcPort == 0x4400) {          // DHCP
                    /* Handle DHCP request from Host */
                    processDHCPPacket(rx_buf, rx_len, tx_buf, tx_len);
                    if(tx_len) {
                        cdc_ecm.send_frame((tx_buf, unsigned char[]), tx_len);
                        stats.total_tx_packets++;
                        stats.total_tx_bytes += tx_len;
                        tx_len = 0;
                        continue;
                    }

                } else if (destPort == 0xe914 && srcPort == 0xe914) {   // MDNS
                    /* Handle DNS query from Host */
                    int flags = (rx_buf, short[])[22];
                    int queries = byterev((rx_buf, short[])[23]) >> 16;
                    int index = 54;
                    if (flags == 0) {
                        for(int i = 0; i < queries; i++) {
                            int qType, qFlag;
                            int j = 0, matcher;
                            for(j = 0; j < sizeof(localName); j++) {
                                matcher = (rx_buf, unsigned char[])[index+j];
                                if (matcher == 0 || matcher != localName[j]) {
                                    break;
                                }
                            }
                            if (matcher) {
                                do {
                                    j++;
                                    matcher = (rx_buf, unsigned char[])[index+j];
                                } while(matcher != 0);
                                index += 4 + j;
                                continue;
                            }
                            index += j+1;
                            if ((rx_buf, unsigned char[])[index] == 0 &&
                                (rx_buf, unsigned char[])[index+1] == 1 &&
                                (rx_buf, unsigned char[])[index+2] == 0 &&
                                (rx_buf, unsigned char[])[index+3] == 1) {

                                tx_len = makeMDNSResponse(tx_buf);
                                cdc_ecm.send_frame((tx_buf, unsigned char[]), tx_len);
                                stats.total_tx_packets++;
                                stats.total_tx_bytes += tx_len;
                                tx_len = 0;
                            }
                            index += 4;
                        }
                    }
                }
            } else if (protocol == 0x6) { // TCP
                stats.tcp_rx_packets++;
                processTCPPacket(rx_buf, rx_len, tx_buf, tx_len);
                if(tx_len) {
                    cdc_ecm.send_frame((tx_buf, unsigned char[]), tx_len);
                    stats.total_tx_packets++;
                    stats.total_tx_bytes += tx_len;
                    tx_len = 0;
                }
            } else if (protocol == 0x01) { // ICMP packet
                stats.icmp_rx_packets++;
                if(((rx_buf, unsigned int[])[3] == 0x00450008) &&
                        (((rx_buf, unsigned int[])[8] >> 16) == (0x0008))){

                    /* Check if the IP address is ours */
                    unsigned int ip = (((unsigned int)(rx_buf, unsigned short[])[16]) << 16) | (rx_buf, unsigned short[])[15];
                    if(byterev(ip) == ipAddressServer) {
                        tx_len = makeICMPReply(rx_buf, tx_buf);
                        cdc_ecm.send_frame((tx_buf, unsigned char[]), tx_len);
                        stats.total_tx_packets++;
                        stats.total_tx_bytes += tx_len;
                        tx_len = 0;
                    }
                }
            }
        }
    }
}
