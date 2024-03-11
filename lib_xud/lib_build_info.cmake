set(LIB_NAME lib_xud)
set(LIB_VERSION 2.3.1)
set(LIB_INCLUDES api src/user api/legacy src/core src/user/class)
set(LIB_DEPENDENT_MODULES "")
set(LIB_OPTIONAL_HEADERS xud_conf.h)
set(LIB_ASM_SRCS src/core/XUD_IoLoop.S
                 src/core/XUD_TestMode.S
                 src/core/XUD_CRC5_Table.S
                 src/core/XUD_USBTile_Support.S
                 src/core/XUD_CRC5_Table_Addr.S
                 src/user/client/XUD_EpFuncs.S)

set(LIB_COMPILER_FLAGS -O3
                       -fasm-linenum
                       -fcomment-asm
                       -DXUD_FULL_PIDTABLE=1
                       -g)

set(LIB_COMPILER_FLAGS_XUD_IoLoop.S   ${LIB_COMPILER_FLAGS} -fschedule)

set(LIB_COMPILER_FLAGS_endpoint0.xc   ${LIB_COMPILER_FLAGS} -Os)
set(LIB_COMPILER_FLAGS_dfu.xc         ${LIB_COMPILER_FLAGS} -Os)
set(LIB_COMPILER_FLAGS_dfu_flash.xc   ${LIB_COMPILER_FLAGS} -Os)

set(LIB_COMPILER_FLAGS_XUD_Client.xc         ${LIB_COMPILER_FLAGS} -mno-dual-issue)
set(LIB_COMPILER_FLAGS_XUD_Main.xc           ${LIB_COMPILER_FLAGS} -mno-dual-issue)
set(LIB_COMPILER_FLAGS_XUD_PhyResetUser.xc   ${LIB_COMPILER_FLAGS} -mno-dual-issue)
set(LIB_COMPILER_FLAGS_XUD_Support.xc        ${LIB_COMPILER_FLAGS} -mno-dual-issue)
set(LIB_COMPILER_FLAGS_XUD_IOLoopCall.xc     ${LIB_COMPILER_FLAGS} -mno-dual-issue)
set(LIB_COMPILER_FLAGS_XUD_Signalling.xc     ${LIB_COMPILER_FLAGS} -mno-dual-issue -Wno-return-type)
set(LIB_COMPILER_FLAGS_XUD_TestMode.xc       ${LIB_COMPILER_FLAGS} -mno-dual-issue)
set(LIB_COMPILER_FLAGS_XUD_SetCrcTableAddr.c ${LIB_COMPILER_FLAGS} -mno-dual-issue)
set(LIB_COMPILER_FLAGS_XUD_User.c            ${LIB_COMPILER_FLAGS} -mno-dual-issue)

XMOS_REGISTER_MODULE()
