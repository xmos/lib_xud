set(XUD_XC_SRCS
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_Main.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_DeviceAttach.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_HAL.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_Signalling.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_IOLoopCall.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_Support.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_User.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_UserResume.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_TestMode.xc
  
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/user/control/xud_device.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/user/control/xud_std_requests.xc

  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/user/client/XUD_EpFunctions.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/user/client/XUD_SetDevAddr.xc
)
set(XUD_C_SRCS
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_Default.c
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_SetCrcTableAddr.c
)
set(XUD_ASM_SRCS
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/user/client/XUD_EpFuncs.S
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_USBTile_Support.S
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_IoLoop.S
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_CRC5_Table_Addr.S
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_CRC5_Table.S
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_User.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_UserResume.xc
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core/XUD_TestMode.S
)
set(XUD_SRCS ${XUD_XC_SRCS} ${XUD_C_SRCS} ${XUD_ASM_SRCS})
set(SUD_INCLUDE_DIRS
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/api
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/core
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/user
  ${CMAKE_BINARY_DIR}/lib_xud/lib_xud/src/user/class
)
