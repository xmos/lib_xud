LIBDIR = ../../lib_xud

all:
	xcc -target=XCORE-200-EXPLORER -Os -D XUD_SERIES_SUPPORT=4 -DT_WTRSTFS=0 -D SUSPEND_VBUS_POLL_TIMER_TICKS=0 -D write_sswitch_reg=test_write_sswitch_reg -I read_sswitch_reg=test_read_sswitch_reg -I ${LIBDIR}/src/user -I ${LIBDIR}/api ${LIBDIR}/src/core/XUD_Main.xc ${LIBDIR}/src/core/XUD_PowerSig.xc ${LIBDIR}/src/core/XUD_Ports.xc test.xc strings.xc stubs.xc
	xobjdump -d a.xe > objdump
