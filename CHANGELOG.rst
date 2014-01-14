XMOS USB Device (XUD) Library Change Log
========================================

1.0.3
-----
    * RESOLVED:   (Minor) ULPI data-lines driven hard low and XMOS pull-up on STP line disabled
                  before taking the USB phy out of reset. Previously the phy could clock in 
                  erroneous data before the XMOS ULPI interface was initialised causing potential 
                  connection issues on initial startup. This affects L/G series libraries only.

1.0.2
-----
    * ADDED:      Re-instated support for G devices (xud_g library)

1.0.1
-----
    * CHANGE:     Power signalling state machines simplified in order to reduce memory usage
    * RESOLVED:   (Minor) Reduced delay before transmitting k-chirp for high-speed mode, this 
                  improves high-speed handshake reliability on some hosts
    * RESOLVED:   (Major) Resolved a compatibility issue with Intel USB 3.0 xHCI host 
                  controllers relating to tight inter-packet timing resulting in packet loss

1.0.0
-----
    * Initial stand-alone release
