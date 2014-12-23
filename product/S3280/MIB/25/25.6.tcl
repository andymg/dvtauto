#!/bin/tcl

#Filename: 25.6.tcl
#History:
#        1/16/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

##################--Mirroring introduction--###########################
# 1. When creating ACL rules, the traffic that falls into a particular flow can also be mirrored. 
# 2. The source and mirror ports must be located on the same switch. 
# 3. You can mirror the ingress or egress traffic of the source ports, or both. 
# 4. You can select more than one source port at a time
# 5. when a port become mirror destination port ,which port can not be source port any more.In turn,It has the same result
# 6. mirroring destination port can not send and receive any traffic except STP packets ,but it can mirror its rx direction packets
# 7. For a given port, a frame is only transmitted once. It is therefore not possible to mirror mirror port Tx frames. Because of this, mode for the selected mirror port is limited to Disabled or Rx only.  
# 8. direction introduction :
#    Rx :only Frames received on this port are mirrored on the mirror port. Frames transmitted are not mirrored.
#    Tx :only Frames transmitted on this port are mirrored on the mirror port. Frames received are not mirrored.
#    Disabled : Neither frames transmitted nor frames received are mirrored.
#    Enabled : Frames received and frames transmitted are mirrored on the mirror port. 
#    
##################--Mirroring introduction--###########################

#Note : this test case is to test mirror source and destination port are the same port 

source ./init.tcl



source ./init.tcl
set phymode $::ixiaphymode
#port1 and port2 are connected to ixia port1 and ixia port2
set port1 $::dutp1
set port2 $::dutp2


setToFactoryDefault $dut1
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode


set srcMac "00 00 00 33 33 33"
set destMac "00 00 00 44 44 44"

#1. when source and destination port are the same ,but source port mode is disable test 
mirror::setSourcePort $dut1 $port1 disable
mirror::setDestPort $dut1 $port1

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap1 -actiontype start -time 2
puts "send traffice from ixia port $ixiap1 to  dut port $port1"
stop_capture -alias ixiap1
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap1 -rxframe ixiap1rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap1_rx_frame: $ixiap1rx"
set getCaptured [check_capture -alias ixiap1 -srcmac $srcMac -dstmac $destMac  ]
puts "get captured $getCaptured"
if { $getCaptured == 0 } {
    passed "Mirroring" "Source and destination port are the same ,but the source port mode is disable  test succeed"
} else { 
    failed  "Mirroring" "Source and destination port are the same ,but the source port mode is disable  test failed"
}






#2. when source and destination port are the same ,but source port mode is RX test
mirror::setSourcePort $dut1 $port1 rx 
config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap1 -actiontype start -time 2
puts "send traffice from ixia port $ixiap1 to  dut port $port1"
stop_capture -alias ixiap1
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap1 -rxframe ixiap1rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap1_rx_frame: $ixiap1rx"
set getCaptured [check_capture -alias ixiap1 -srcmac $srcMac -dstmac $destMac  ]
puts "get captured $getCaptured"
if { $getCaptured != 0 } {
    passed "Mirroring" "Source and destination port are the same ,but the source port mode is RX  test succeed"
} else { 
    failed  "Mirroring" "Source and destination port are the same ,but the source port mode is RX  test failed"
}

clear_ownership -alias allport