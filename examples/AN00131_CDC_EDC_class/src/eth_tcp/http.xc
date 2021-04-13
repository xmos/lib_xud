// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <ethernet.h>
#include <print.h>
#include <string.h>
#include <stdio.h>
#include "femtoTCP.h"
#include "queue.h"
#include "packet_buffer.h"

#define STRLEN 16

unsigned char html_buffer[1350];
unsigned char html_data[] = "HTTP/1.0 200 OK\r\nContent-Length: 1181\r\n\r\n\
<!DOCTYPE html>\r\n\
<html>\r\n\
<head>\r\n\
<style>\r\n\
table, th, td {\r\n\
    border: 1px solid black;\r\n\
    border-collapse: collapse;\r\n\
}\r\n\
th, td {\r\n\
    padding: 15px;\r\n\
}\r\n\
</style>\r\n\
</head>\r\n\
\
<body>\r\n\
\
<h2>XMOS USB CDC Ethernet Control Model Class demo</h1>\r\n\
\
<p>This is a demo of the XMOS USB CDC ECM class device implemented using the XMOS USB library.\r\n\
CDC ECM model specification enables Ethernet over USB. This web page is hosted by xCORE-USB \r\n\
sliceKIT that has enumerated as USB CDC ECM device in this host machine and trasmitting and \r\n\
receiving Ethernet frames over USB endpoints.</p>\r\n\
\
<h3>Network Packets statistics</h2>\r\n\
<table>\r\n\
  <tr><td>Total Number of packets received: </td><td>%u</td></tr>\r\n\
  <tr><td>Total Number of packets transmitted: </td><td>%u</td></tr>\r\n\
  <tr><td>Number of ARP packets received: </td><td>%u</td></tr>\r\n\
  <tr><td>Number of TCP packets received: </td><td>%u</td></tr>\r\n\
  <tr><td>Number of UDP packets received: </td><td>%u</td></tr>\r\n\
  <tr><td>Number of ICMP packets received: </td><td>%u</td></tr>\r\n\
  <tr><td>Total Number of bytes received: </td><td>%u</td></tr>\r\n\
  <tr><td>Total Number of bytes transmitted: </td><td>%u</td></tr>\r\n\
</table>\r\n\
</body>\r\n\
</html>\r\n";

void httpProcess(unsigned int packet[], int charOffset, int packetLength, unsigned int rsp_packet[], unsigned &rsp_len) {
    char string[STRLEN];
    char length[6];
    for(int i = 0; i < packetLength && i < STRLEN; i++) {
        string[i] = (packet, unsigned char[])[charOffset + i];
    }
    if (strncmp(string, "GET ", 4) == 0) {

        sprintf(html_buffer, html_data, stats.total_rx_packets, stats.total_tx_packets, stats.arp_rx_packets,
                                        stats.tcp_rx_packets, stats.udp_rx_packets, stats.icmp_rx_packets,
                                        stats.total_rx_bytes, stats.total_tx_bytes);
        sprintf(length, "%d", strlen(html_buffer)-41);
        // Change the 'Content-Length' in HTTP header
        strncpy(html_buffer+33, length, 4);
        tcpString(html_buffer, rsp_packet, rsp_len);

    } else {
        tcpString("HTTP/1.0 404 NOT FOUND\r\n\r\n", rsp_packet, rsp_len);
    }
//    printstrln(string);
}

