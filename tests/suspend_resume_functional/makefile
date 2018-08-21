LIBDIR = ../../lib_xud

all:
	xcc -target=XCORE-200-EXPLORER -Os -D XUD_SERIES_SUPPORT=4 -D REF_CLK_FREQ=100 -D write_sswitch_reg=test_write_sswitch_reg -I read_sswitch_reg=test_read_sswitch_reg -I ${LIBDIR}/src/user -I ${LIBDIR}/api ${LIBDIR}/src/core/XUD_Main.xc ${LIBDIR}/src/core/XUD_PowerSig.xc ${LIBDIR}/src/core/XUD_Ports.xc test.xc strings.xc stubs.xc
