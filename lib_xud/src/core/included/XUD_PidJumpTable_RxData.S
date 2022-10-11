// Copyright 2011-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#if defined (__XS2A__)

//  PID jump table
.section .dp.data, "adw", @progbits

.globl PidJumpTable_RxData
.type PidJumpTable_RxData, @object

.cc_top PidJumpTable_RxData.func, PidJumpTable_RxData
.align 4
PidJumpTable_RxData:
.word Pid_Reserved        // 0   0x00
.word Pid_Out              // 1   0x01
.word Pid_Ack             // 2   0x02
.word Pid_Data0_RxData          // 3   0x03
.word Pid_Ping            // 4   0x04
.word Pid_Sof             // 5   0x05
.word Pid_Nyet            // 6   0x06
.word Pid_Data2_RxData           // 7   0x07
.word Pid_Split           // 8   0x08
.word Pid_In              // 9   0x09
.word Pid_Nak             // 10   0x0a
.word Pid_Data1_RxData           // 11   0x0b
.word Pid_Pre             // 12   0x0c
.word Pid_Setup           // 13   0x0d
.word Pid_Stall           // 14   0x0e
.word Pid_Datam_RxData          // 15   0x0f
#if defined(XUD_DEBUG_VERSION) || defined(XUD_FULL_PIDTABLE)
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData
.word Pid_Bad_RxData

#endif

.size PidJumpTable_RxData, .-PidJumpTable_RxData
.cc_bottom PidJumpTable_RxData.func

#endif

#if !defined(__XS2A__)
// Generated using genpidtable.c
.section .dp.data, "adw", @progbits
.globl PidJumpTable_RxData
.type PidJumpTable_RxData, @function

.cc_top PidJumpTable_RxData.func, PidJumpTable_RxData
.align 4

PidJumpTable_RxData:
.word Pid_Bad_RxData    // 0   0x00
.word Pid_Bad_RxData    // 1   0x01
.word Pid_Bad_RxData    // 2   0x02
.word Pid_Bad_RxData    // 3   0x03
.word Pid_Bad_RxData    // 4   0x04
.word Pid_Bad_RxData    // 5   0x05
.word Pid_Bad_RxData    // 6   0x06
.word Pid_Bad_RxData    // 7   0x07
.word Pid_Bad_RxData    // 8   0x08
.word Pid_Bad_RxData    // 9   0x09
.word Pid_Bad_RxData    // 10   0x0a
.word Pid_Bad_RxData    // 11   0x0b
.word Pid_Bad_RxData    // 12   0x0c
.word Pid_Bad_RxData    // 13   0x0d
.word Pid_Bad_RxData    // 14   0x0e
.word Pid_MData    // 15   0x0f
.word Pid_Bad_RxData    // 16   0x10
.word Pid_Bad_RxData    // 17   0x11
.word Pid_Bad_RxData    // 18   0x12
.word Pid_Bad_RxData    // 19   0x13
.word Pid_Bad_RxData    // 20   0x14
.word Pid_Bad_RxData    // 21   0x15
.word Pid_Bad_RxData    // 22   0x16
.word Pid_Bad_RxData    // 23   0x17
.word Pid_Bad_RxData    // 24   0x1
.word Pid_Bad_RxData    // 25   0x19
.word Pid_Bad_RxData    // 26   0x1a
.word Pid_Bad_RxData    // 27   0x1b
.word Pid_Bad_RxData    // 28   0x1c
.word Pid_Bad_RxData    // 29   0x1d
.word Pid_Bad_RxData    // 30   0x1e
.word Pid_Bad_RxData    // 31   0x1f
.word Pid_Bad_RxData    // 32   0x20
.word Pid_Bad_RxData    // 33   0x21
.word Pid_Bad_RxData    // 34   0x22
.word Pid_Bad_RxData    // 35   0x23
.word Pid_Bad_RxData    // 36   0x24
.word Pid_Bad_RxData    // 37   0x25
.word Pid_Bad_RxData    // 38   0x26
.word Pid_Bad_RxData    // 39   0x27
.word Pid_Bad_RxData    // 40   0x28
.word Pid_Bad_RxData    // 41   0x29
.word Pid_Bad_RxData    // 42   0x2a
.word Pid_Bad_RxData    // 43   0x2b
.word Pid_Bad_RxData    // 44   0x2c
.word Pid_Bad_RxData    // 45   0x2d
.word Pid_Bad_RxData    // 46   0x2e
.word Pid_Bad_RxData    // 47   0x2f
.word Pid_Bad_RxData    // 48   0x30
.word Pid_Bad_RxData    // 49   0x31
.word Pid_Bad_RxData    // 50   0x32
.word Pid_Bad_RxData    // 51   0x33
.word Pid_Bad_RxData    // 52   0x34
.word Pid_Bad_RxData    // 53   0x35
.word Pid_Bad_RxData    // 54   0x36
.word Pid_Bad_RxData    // 55   0x37
.word Pid_Bad_RxData    // 56   0x38
.word Pid_Bad_RxData    // 57   0x39
.word Pid_Bad_RxData    // 58   0x3a
.word Pid_Bad_RxData    // 59   0x3b
.word Pid_Bad_RxData    // 60   0x3c
.word Pid_Bad_RxData    // 61   0x3d
.word Pid_Bad_RxData    // 62   0x3e
.word Pid_Bad_RxData    // 63   0x3f
.word Pid_Bad_RxData    // 64   0x40
.word Pid_Bad_RxData    // 65   0x41
.word Pid_Bad_RxData    // 66   0x42
.word Pid_Bad_RxData    // 67   0x43
.word Pid_Bad_RxData    // 68   0x44
.word Pid_Bad_RxData    // 69   0x45
.word Pid_Bad_RxData    // 70   0x46
.word Pid_Bad_RxData    // 71   0x47
.word Pid_Bad_RxData    // 72   0x48
.word Pid_Bad_RxData    // 73   0x49
.word Pid_Bad_RxData    // 74   0x4a
.word Pid_Data1_RxData    // 75   0x4b
.word Pid_Bad_RxData    // 76   0x4c
.word Pid_Bad_RxData    // 77   0x4d
.word Pid_Bad_RxData    // 78   0x4e
.word Pid_Bad_RxData    // 79   0x4f
.word Pid_Bad_RxData    // 80   0x50
.word Pid_Bad_RxData    // 81   0x51
.word Pid_Bad_RxData    // 82   0x52
.word Pid_Bad_RxData    // 83   0x53
.word Pid_Bad_RxData    // 84   0x54
.word Pid_Bad_RxData    // 85   0x55
.word Pid_Bad_RxData    // 86   0x56
.word Pid_Bad_RxData    // 87   0x57
.word Pid_Bad_RxData    // 88   0x58
.word Pid_Bad_RxData    // 89   0x59
.word Pid_Bad_RxData    // 90   0x5a
.word Pid_Bad_RxData    // 91   0x5b
.word Pid_Bad_RxData    // 92   0x5c
.word Pid_Bad_RxData    // 93   0x5d
.word Pid_Bad_RxData    // 94   0x5e
.word Pid_Bad_RxData    // 95   0x5f
.word Pid_Bad_RxData    // 96   0x60
.word Pid_Bad_RxData    // 97   0x61
.word Pid_Bad_RxData    // 98   0x62
.word Pid_Bad_RxData    // 99   0x63
.word Pid_Bad_RxData    // 100   0x64
.word Pid_Bad_RxData    // 101   0x65
.word Pid_Bad_RxData    // 102   0x66
.word Pid_Bad_RxData    // 103   0x67
.word Pid_Bad_RxData    // 104   0x68
.word Pid_Bad_RxData    // 105   0x69
.word Pid_Bad_RxData    // 106   0x6a
.word Pid_Bad_RxData    // 107   0x6b
.word Pid_Bad_RxData    // 108   0x6c
.word Pid_Bad_RxData    // 109   0x6d
.word Pid_Bad_RxData    // 110   0x6e
.word Pid_Bad_RxData    // 111   0x6f
.word Pid_Bad_RxData    // 112   0x70
.word Pid_Bad_RxData    // 113   0x71
.word Pid_Bad_RxData    // 114   0x72
.word Pid_Bad_RxData    // 115   0x73
.word Pid_Bad_RxData    // 116   0x74
.word Pid_Bad_RxData    // 117   0x75
.word Pid_Bad_RxData    // 118   0x76
.word Pid_Bad_RxData    // 119   0x77
.word Pid_Bad_RxData    // 120   0x78
.word Pid_Bad_RxData    // 121   0x79
.word Pid_Bad_RxData    // 122   0x7a
.word Pid_Bad_RxData    // 123   0x7b
.word Pid_Bad_RxData    // 124   0x7c
.word Pid_Bad_RxData    // 125   0x7d
.word Pid_Bad_RxData    // 126   0x7e
.word Pid_Bad_RxData    // 127   0x7f
.word Pid_Bad_RxData    // 128   0x80
.word Pid_Bad_RxData    // 129   0x81
.word Pid_Bad_RxData    // 130   0x82
.word Pid_Bad_RxData    // 131   0x83
.word Pid_Bad_RxData    // 132   0x84
.word Pid_Bad_RxData    // 133   0x85
.word Pid_Bad_RxData    // 134   0x86
.word Pid_Data2         // 135   0x87
.word Pid_Bad_RxData    // 136   0x88
.word Pid_Bad_RxData    // 137   0x89
.word Pid_Bad_RxData    // 138   0x8a
.word Pid_Bad_RxData    // 139   0x8b
.word Pid_Bad_RxData    // 140   0x8c
.word Pid_Bad_RxData    // 141   0x8d
.word Pid_Bad_RxData    // 142   0x8e
.word Pid_Bad_RxData    // 143   0x8f
.word Pid_Bad_RxData    // 144   0x90
.word Pid_Bad_RxData    // 145   0x91
.word Pid_Bad_RxData    // 146   0x92
.word Pid_Bad_RxData    // 147   0x93
.word Pid_Bad_RxData    // 148   0x94
.word Pid_Bad_RxData    // 149   0x95
.word Pid_Bad_RxData    // 150   0x96
.word Pid_Bad_RxData    // 151   0x97
.word Pid_Bad_RxData    // 152   0x98
.word Pid_Bad_RxData    // 153   0x99
.word Pid_Bad_RxData    // 154   0x9a
.word Pid_Bad_RxData    // 155   0x9b
.word Pid_Bad_RxData    // 156   0x9c
.word Pid_Bad_RxData    // 157   0x9d
.word Pid_Bad_RxData    // 158   0x9e
.word Pid_Bad_RxData    // 159   0x9f
.word Pid_Bad_RxData    // 160   0xa0
.word Pid_Bad_RxData    // 161   0xa1
.word Pid_Bad_RxData    // 162   0xa2
.word Pid_Bad_RxData    // 163   0xa3
.word Pid_Bad_RxData    // 164   0xa4
.word Pid_Bad_RxData    // 165   0xa5
.word Pid_Bad_RxData    // 166   0xa6
.word Pid_Bad_RxData    // 167   0xa7
.word Pid_Bad_RxData    // 168   0xa8
.word Pid_Bad_RxData    // 169   0xa9
.word Pid_Bad_RxData    // 170   0xaa
.word Pid_Bad_RxData    // 171   0xab
.word Pid_Bad_RxData    // 172   0xac
.word Pid_Bad_RxData    // 173   0xad
.word Pid_Bad_RxData    // 174   0xae
.word Pid_Bad_RxData    // 175   0xaf
.word Pid_Bad_RxData    // 176   0xb0
.word Pid_Bad_RxData    // 177   0xb1
.word Pid_Bad_RxData    // 178   0xb2
.word Pid_Bad_RxData    // 179   0xb3
.word Pid_Bad_RxData    // 180   0xb4
.word Pid_Bad_RxData    // 181   0xb5
.word Pid_Bad_RxData    // 182   0xb6
.word Pid_Bad_RxData    // 183   0xb7
.word Pid_Bad_RxData    // 184   0xb8
.word Pid_Bad_RxData    // 185   0xb9
.word Pid_Bad_RxData    // 186   0xba
.word Pid_Bad_RxData    // 187   0xbb
.word Pid_Bad_RxData    // 188   0xbc
.word Pid_Bad_RxData    // 189   0xbd
.word Pid_Bad_RxData    // 190   0xbe
.word Pid_Bad_RxData    // 191   0xbf
.word Pid_Bad_RxData    // 192   0xc0
.word Pid_Bad_RxData    // 193   0xc1
.word Pid_Bad_RxData    // 194   0xc2
.word Pid_Data0_RxData    // 195   0xc3
.word Pid_Bad_RxData    // 196   0xc4
.word Pid_Bad_RxData    // 197   0xc5
.word Pid_Bad_RxData    // 198   0xc6
.word Pid_Bad_RxData    // 199   0xc7
.word Pid_Bad_RxData    // 200   0xc8
.word Pid_Bad_RxData    // 201   0xc9
.word Pid_Bad_RxData    // 202   0xca
.word Pid_Bad_RxData    // 203   0xcb
.word Pid_Bad_RxData    // 204   0xcc
.word Pid_Bad_RxData    // 205   0xcd
.word Pid_Bad_RxData    // 206   0xce
.word Pid_Bad_RxData    // 207   0xcf
.word Pid_Bad_RxData    // 208   0xd0
.word Pid_Bad_RxData    // 209   0xd1
.word Pid_Bad_RxData    // 210   0xd2
.word Pid_Bad_RxData    // 211   0xd3
.word Pid_Bad_RxData    // 212   0xd4
.word Pid_Bad_RxData    // 213   0xd5
.word Pid_Bad_RxData    // 214   0xd6
.word Pid_Bad_RxData    // 215   0xd7
.word Pid_Bad_RxData    // 216   0xd8
.word Pid_Bad_RxData    // 217   0xd9
.word Pid_Bad_RxData    // 218   0xda
.word Pid_Bad_RxData    // 219   0xdb
.word Pid_Bad_RxData    // 220   0xdc
.word Pid_Bad_RxData    // 221   0xdd
.word Pid_Bad_RxData    // 222   0xde
.word Pid_Bad_RxData    // 223   0xdf
.word Pid_Bad_RxData    // 224   0xe0
.word Pid_Bad_RxData   // 225   0xe1
.word Pid_Bad_RxData    // 226   0xe2
.word Pid_Bad_RxData    // 227   0xe3
.word Pid_Bad_RxData    // 228   0xe4
.word Pid_Bad_RxData    // 229   0xe5
.word Pid_Bad_RxData    // 230   0xe6
.word Pid_Bad_RxData    // 231   0xe7
.word Pid_Bad_RxData    // 232   0xe8
.word Pid_Bad_RxData    // 233   0xe9
.word Pid_Bad_RxData    // 234   0xea
.word Pid_Bad_RxData    // 235   0xeb
.word Pid_Bad_RxData    // 236   0xec
.word Pid_Bad_RxData    // 237   0xed
.word Pid_Bad_RxData    // 238   0xee
.word Pid_Bad_RxData    // 239   0xef
.word Pid_Bad_RxData    // 240   0xf0
.word Pid_Bad_RxData    // 241   0xf1
.word Pid_Bad_RxData    // 242   0xf2
.word Pid_Bad_RxData    // 243   0xf3
.word Pid_Bad_RxData    // 244   0xf4
.word Pid_Bad_RxData    // 245   0xf5
.word Pid_Bad_RxData    // 246   0xf6
.word Pid_Bad_RxData    // 247   0xf7
.word Pid_Bad_RxData    // 248   0xf8
.word Pid_Bad_RxData    // 249   0xf9
.word Pid_Bad_RxData    // 250   0xfa
.word Pid_Bad_RxData    // 251   0xfb
.word Pid_Bad_RxData    // 252   0xfc
.word Pid_Bad_RxData    // 253   0xfd
.word Pid_Bad_RxData    // 254   0xfe
.word Pid_Bad_RxData    // 255   0xff

.size PidJumpTable_RxData, .-PidJumpTable_RxData
.cc_bottom PidJumpTable_RxData.func

#endif
