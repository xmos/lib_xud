// Copyright 2011-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#if defined (__XS2A__)

//  PID jump table
.section .dp.data, "adw", @progbits

.globl PidJumpTable
.type PidJumpTable, @object

.cc_top PidJumpTable.func, PidJumpTable
.align 4
PidJumpTable:
.word Pid_Reserved        // 0   0x00
.word Pid_Out             // 1   0x01
.word Pid_Ack             // 2   0x02
.word Pid_Data0           // 3   0x03
.word Pid_Ping            // 4   0x04
.word Pid_Sof             // 5   0x05
.word Pid_Nyet            // 6   0x06
.word Pid_Data2           // 7   0x07
.word Pid_Split           // 8   0x08
.word Pid_In              // 9   0x09
.word Pid_Nak             // 10   0x0a
.word Pid_Data1           // 11   0x0b
.word Pid_Pre             // 12   0x0c
.word Pid_Setup           // 13   0x0d
.word Pid_Stall           // 14   0x0e
.word Pid_Datam           // 15   0x0f
#if defined(XUD_DEBUG_VERSION) || defined(XUD_FULL_PIDTABLE)
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad       //31
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad
.word Pid_Bad

#endif

.size PidJumpTable, .-PidJumpTable
.cc_bottom PidJumpTable.func

#endif

#if !defined(__XS2A__)
// Generated using genpidtable.c
.section .dp.data, "adw", @progbits
.globl PidJumpTable
.type PidJumpTable, @function

//.cc_top PidJumpTable.func, PidJumpTableFull
.cc_top PidJumpTable.func, PidJumpTable
.align 4

PidJumpTable:
.word Pid_Bad    // 0   0x00
.word Pid_Bad    // 1   0x01
.word Pid_Bad    // 2   0x02
.word Pid_Bad    // 3   0x03
.word Pid_Bad    // 4   0x04
.word Pid_Bad    // 5   0x05
.word Pid_Bad    // 6   0x06
.word Pid_Bad    // 7   0x07
.word Pid_Bad    // 8   0x08
.word Pid_Bad    // 9   0x09
.word Pid_Bad    // 10   0x0a
.word Pid_Bad    // 11   0x0b
.word Pid_Bad    // 12   0x0c
.word Pid_Bad    // 13   0x0d
.word Pid_Bad    // 14   0x0e
.word Pid_MData    // 15   0x0f
.word Pid_Bad    // 16   0x10
.word Pid_Bad    // 17   0x11
.word Pid_Bad    // 18   0x12
.word Pid_Bad    // 19   0x13
.word Pid_Bad    // 20   0x14
.word Pid_Bad    // 21   0x15
.word Pid_Bad    // 22   0x16
.word Pid_Bad    // 23   0x17
.word Pid_Split    // 24   0x1
.word Pid_Bad    // 25   0x19
.word Pid_Bad    // 26   0x1a
.word Pid_Bad    // 27   0x1b
.word Pid_Bad    // 28   0x1c
.word Pid_Bad    // 29   0x1d
.word Pid_Stall    // 30   0x1e
.word Pid_Bad    // 31   0x1f
.word Pid_Bad    // 32   0x20
.word Pid_Bad    // 33   0x21
.word Pid_Bad    // 34   0x22
.word Pid_Bad    // 35   0x23
.word Pid_Bad    // 36   0x24
.word Pid_Bad    // 37   0x25
.word Pid_Bad    // 38   0x26
.word Pid_Bad    // 39   0x27
.word Pid_Bad    // 40   0x28
.word Pid_Bad    // 41   0x29
.word Pid_Bad    // 42   0x2a
.word Pid_Bad    // 43   0x2b
.word Pid_Bad    // 44   0x2c
.word Pid_Setup   // 45   0x2d
.word Pid_Bad    // 46   0x2e
.word Pid_Bad    // 47   0x2f
.word Pid_Bad    // 48   0x30
.word Pid_Bad    // 49   0x31
.word Pid_Bad    // 50   0x32
.word Pid_Bad    // 51   0x33
.word Pid_Bad    // 52   0x34
.word Pid_Bad    // 53   0x35
.word Pid_Bad    // 54   0x36
.word Pid_Bad    // 55   0x37
.word Pid_Bad    // 56   0x38
.word Pid_Bad    // 57   0x39
.word Pid_Bad    // 58   0x3a
.word Pid_Bad    // 59   0x3b
.word Pid_Pre    // 60   0x3c
.word Pid_Bad    // 61   0x3d
.word Pid_Bad    // 62   0x3e
.word Pid_Bad    // 63   0x3f
.word Pid_Bad    // 64   0x40
.word Pid_Bad    // 65   0x41
.word Pid_Bad    // 66   0x42
.word Pid_Bad    // 67   0x43
.word Pid_Bad    // 68   0x44
.word Pid_Bad    // 69   0x45
.word Pid_Bad    // 70   0x46
.word Pid_Bad    // 71   0x47
.word Pid_Bad    // 72   0x48
.word Pid_Bad    // 73   0x49
.word Pid_Bad    // 74   0x4a
.word Pid_Data1    // 75   0x4b
.word Pid_Bad    // 76   0x4c
.word Pid_Bad    // 77   0x4d
.word Pid_Bad    // 78   0x4e
.word Pid_Bad    // 79   0x4f
.word Pid_Bad    // 80   0x50
.word Pid_Bad    // 81   0x51
.word Pid_Bad    // 82   0x52
.word Pid_Bad    // 83   0x53
.word Pid_Bad    // 84   0x54
.word Pid_Bad    // 85   0x55
.word Pid_Bad    // 86   0x56
.word Pid_Bad    // 87   0x57
.word Pid_Bad    // 88   0x58
.word Pid_Bad    // 89   0x59
.word Pid_Nak    // 90   0x5a
.word Pid_Bad    // 91   0x5b
.word Pid_Bad    // 92   0x5c
.word Pid_Bad    // 93   0x5d
.word Pid_Bad    // 94   0x5e
.word Pid_Bad    // 95   0x5f
.word Pid_Bad    // 96   0x60
.word Pid_Bad    // 97   0x61
.word Pid_Bad    // 98   0x62
.word Pid_Bad    // 99   0x63
.word Pid_Bad    // 100   0x64
.word Pid_Bad    // 101   0x65
.word Pid_Bad    // 102   0x66
.word Pid_Bad    // 103   0x67
.word Pid_Bad    // 104   0x68
.word Pid_In    // 105   0x69
.word Pid_Bad    // 106   0x6a
.word Pid_Bad    // 107   0x6b
.word Pid_Bad    // 108   0x6c
.word Pid_Bad    // 109   0x6d
.word Pid_Bad    // 110   0x6e
.word Pid_Bad    // 111   0x6f
.word Pid_Bad    // 112   0x70
.word Pid_Bad    // 113   0x71
.word Pid_Bad    // 114   0x72
.word Pid_Bad    // 115   0x73
.word Pid_Bad    // 116   0x74
.word Pid_Bad    // 117   0x75
.word Pid_Bad    // 118   0x76
.word Pid_Bad    // 119   0x77
.word Pid_Bad    // 120   0x78
.word Pid_Bad    // 121   0x79
.word Pid_Bad    // 122   0x7a
.word Pid_Bad    // 123   0x7b
.word Pid_Bad    // 124   0x7c
.word Pid_Bad    // 125   0x7d
.word Pid_Bad    // 126   0x7e
.word Pid_Bad    // 127   0x7f
.word Pid_Bad    // 128   0x80
.word Pid_Bad    // 129   0x81
.word Pid_Bad    // 130   0x82
.word Pid_Bad    // 131   0x83
.word Pid_Bad    // 132   0x84
.word Pid_Bad    // 133   0x85
.word Pid_Bad    // 134   0x86
.word Pid_Data2    // 135   0x87
.word Pid_Bad    // 136   0x88
.word Pid_Bad    // 137   0x89
.word Pid_Bad    // 138   0x8a
.word Pid_Bad    // 139   0x8b
.word Pid_Bad    // 140   0x8c
.word Pid_Bad    // 141   0x8d
.word Pid_Bad    // 142   0x8e
.word Pid_Bad    // 143   0x8f
.word Pid_Bad    // 144   0x90
.word Pid_Bad    // 145   0x91
.word Pid_Bad    // 146   0x92
.word Pid_Bad    // 147   0x93
.word Pid_Bad    // 148   0x94
.word Pid_Bad    // 149   0x95
.word Pid_NYet    // 150   0x96
.word Pid_Bad    // 151   0x97
.word Pid_Bad    // 152   0x98
.word Pid_Bad    // 153   0x99
.word Pid_Bad    // 154   0x9a
.word Pid_Bad    // 155   0x9b
.word Pid_Bad    // 156   0x9c
.word Pid_Bad    // 157   0x9d
.word Pid_Bad    // 158   0x9e
.word Pid_Bad    // 159   0x9f
.word Pid_Bad    // 160   0xa0
.word Pid_Bad    // 161   0xa1
.word Pid_Bad    // 162   0xa2
.word Pid_Bad    // 163   0xa3
.word Pid_Bad    // 164   0xa4
.word Pid_Sof    // 165   0xa5
.word Pid_Bad    // 166   0xa6
.word Pid_Bad    // 167   0xa7
.word Pid_Bad    // 168   0xa8
.word Pid_Bad    // 169   0xa9
.word Pid_Bad    // 170   0xaa
.word Pid_Bad    // 171   0xab
.word Pid_Bad    // 172   0xac
.word Pid_Bad    // 173   0xad
.word Pid_Bad    // 174   0xae
.word Pid_Bad    // 175   0xaf
.word Pid_Bad    // 176   0xb0
.word Pid_Bad    // 177   0xb1
.word Pid_Bad    // 178   0xb2
.word Pid_Bad    // 179   0xb3
.word Pid_Ping    // 180   0xb4
.word Pid_Bad    // 181   0xb5
.word Pid_Bad    // 182   0xb6
.word Pid_Bad    // 183   0xb7
.word Pid_Bad    // 184   0xb8
.word Pid_Bad    // 185   0xb9
.word Pid_Bad    // 186   0xba
.word Pid_Bad    // 187   0xbb
.word Pid_Bad    // 188   0xbc
.word Pid_Bad    // 189   0xbd
.word Pid_Bad    // 190   0xbe
.word Pid_Bad    // 191   0xbf
.word Pid_Bad    // 192   0xc0
.word Pid_Bad    // 193   0xc1
.word Pid_Bad    // 194   0xc2
.word Pid_Data0    // 195   0xc3
.word Pid_Bad    // 196   0xc4
.word Pid_Bad    // 197   0xc5
.word Pid_Bad    // 198   0xc6
.word Pid_Bad    // 199   0xc7
.word Pid_Bad    // 200   0xc8
.word Pid_Bad    // 201   0xc9
.word Pid_Bad    // 202   0xca
.word Pid_Bad    // 203   0xcb
.word Pid_Bad    // 204   0xcc
.word Pid_Bad    // 205   0xcd
.word Pid_Bad    // 206   0xce
.word Pid_Bad    // 207   0xcf
.word Pid_Bad    // 208   0xd0
.word Pid_Bad    // 209   0xd1
.word Pid_Ack    // 210   0xd2
.word Pid_Bad    // 211   0xd3
.word Pid_Bad    // 212   0xd4
.word Pid_Bad    // 213   0xd5
.word Pid_Bad    // 214   0xd6
.word Pid_Bad    // 215   0xd7
.word Pid_Bad    // 216   0xd8
.word Pid_Bad    // 217   0xd9
.word Pid_Bad    // 218   0xda
.word Pid_Bad    // 219   0xdb
.word Pid_Bad    // 220   0xdc
.word Pid_Bad    // 221   0xdd
.word Pid_Bad    // 222   0xde
.word Pid_Bad    // 223   0xdf
.word Pid_Bad    // 224   0xe0
.word Pid_Out    // 225   0xe1
.word Pid_Bad    // 226   0xe2
.word Pid_Bad    // 227   0xe3
.word Pid_Bad    // 228   0xe4
.word Pid_Bad    // 229   0xe5
.word Pid_Bad    // 230   0xe6
.word Pid_Bad    // 231   0xe7
.word Pid_Bad    // 232   0xe8
.word Pid_Bad    // 233   0xe9
.word Pid_Bad    // 234   0xea
.word Pid_Bad    // 235   0xeb
.word Pid_Bad    // 236   0xec
.word Pid_Bad    // 237   0xed
.word Pid_Bad    // 238   0xee
.word Pid_Bad    // 239   0xef
.word Pid_Bad    // 240   0xf0
.word Pid_Bad    // 241   0xf1
.word Pid_Bad    // 242   0xf2
.word Pid_Bad    // 243   0xf3
.word Pid_Bad    // 244   0xf4
.word Pid_Bad    // 245   0xf5
.word Pid_Bad    // 246   0xf6
.word Pid_Bad    // 247   0xf7
.word Pid_Bad    // 248   0xf8
.word Pid_Bad    // 249   0xf9
.word Pid_Bad    // 250   0xfa
.word Pid_Bad    // 251   0xfb
.word Pid_Bad    // 252   0xfc
.word Pid_Bad    // 253   0xfd
.word Pid_Bad    // 254   0xfe
.word Pid_Bad    // 255   0xff

.size PidJumpTable, .-PidJumpTable
.cc_bottom PidJumpTable.func
//.cc_bottom PidJumpTableFull.func

#endif
