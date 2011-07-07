.section .dp.data,       "adw", @progbits
.globl Endpoint1_feedback_buffer
.cc_top Endpoint1_feedback_buffer.data, Endpoint1_feedback_buffer
// This should be redefined in the application, only here to
// avoid linkage errors        
Endpoint1_feedback_buffer:
.cc_bottom Endpoint1_feedback_buffer.data
