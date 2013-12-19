XMOS USB Device (XUD) Library Change Log
========================================

HEAD
----
    * ADDED:        Re-instated G library

1.0.1
-----
    * CHANGE:     Power signalling state machines simplified in order to reduce memory usage.
    * RESOLVED:   (Minor) Reduced delay before transmitting k-chirp for high-speed mode, this improves high-speed handshake reliability on some hosts
    * RESOLVED:   (Major) Resolved a compatibility issue with Intel USB 3.0 xHCI host controllers relating to tight inter-packet timing resulting in packet loss

1.0.0
-----
    * Initial release
