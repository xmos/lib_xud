// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
.globl SetupChannelVectorsOverride.nstackwords
.globl SetupChannelVectorsOverride.maxthreads
.globl SetupChannelVectorsOverride.maxtimers
.globl SetupChannelVectorsOverride.maxchanends

.linkset SetupChannelVectorsOverride.nstackwords, 0
.linkset SetupChannelVectorsOverride.maxchanends, 0
.linkset SetupChannelVectorsOverride.maxtimers, 0
.linkset SetupChannelVectorsOverride.maxthreads, 0

.globl SetupChannelVectorsOverride
.type SetupChannelVectorsOverride, @function
.text
.cc_top SetupChannelVectorsOverride.func, SetupChannelVectorsOverride

// This function can be redefined by the client
SetupChannelVectorsOverride:
        retsp 0
.size SetupChannelVectorsOverride, .-SetupChannelVectorsOverride
.cc_bottom SetupChannelVectorsOverride.func
