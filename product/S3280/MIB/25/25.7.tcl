#!/bin/tcl

#Filename: 25.7.tcl
#History:
#        1/16/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

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



#Note : this test case is to test more than one soure ports test



source ./init.tcl
set phymode $::ixiaphymode
#port1 and port2 are connected to ixia port1 and ixia port2
set port1 $::dutp1
set port2 $::dutp2
set port3 $::dutp3



setToFactoryDefault $dut1

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode
config_portprop -alias ixiap3 -autonego enable -phymode $phymode

set srcMac "00 00 00 33 33 33"
set destMac "00 00 00 44 44 44"
set Mac "00 00 00 55 55 55"

mirror::setSourcePort $dut1 $port1 both
mirror::setSourcePort $dut1 $port2 both
mirror::setDestPort $dut1 $port3



#1. send traffice from one port and another port could receive that's traffic test 


config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 2
puts "send traffice from ixia port $ixiap1 to  dut port $port1"
stop_capture -alias ixiap2 
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
get_stat -alias ixiap2 -rxframe ixiap3rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx,ixiap3_rx_frame: $ixiap3rx"
set Tx1get $ixiap1tx
set Rx2get [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destMac  ]
set Rx3get [check_capture -alias ixiap3 -srcmac $srcMac -dstmac $destMac  ]
puts "ixia port $ixiap1 send packets: $Tx1get"
puts "ixia port $ixiap2 receive packets: $Rx2get"
puts "ixia port $ixiap3 receive packets: $Rx3get"
if { $Tx1get == $Rx2get && $Rx2get == $Rx3get } {
    passed "Mirroring" "More than one source ports and send traffic only from one source test succeed"
} else { 
    failed  "Mirroring" "More than one source ports and send traffic only from one source test  failed"
}




#2. send traffice from all source ports  test 

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac   -dbgprt 1
config_frame  -alias ixiap2 -srcmac $srcMac  -dstmac $destMac   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 2
puts "send traffice from ixia port $ixiap1 to  dut port $port1"
send_traffic -alias ixiap2 -actiontype start -time 2
puts "send traffice from ixia port $ixiap2 to  dut port $port2"
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap2 -rxframe ixiap3rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_tx_frame: $ixiap2tx,ixiap3_rx_frame: $ixiap3rx"
set Tx1get $ixiap1tx
set Tx2get $ixiap2tx
set Rx3get [check_capture -alias ixiap3 -srcmac $srcMac -dstmac $destMac  ]
puts "ixia port $ixiap1 send packets: $Tx1get"
puts "ixia port $ixiap2 sedn packets: $Tx2get"
puts "ixia port $ixiap3 receive packets: $Rx3get"
if { [expr $Tx1get + $Tx2get] ==  $Rx3get } {
    passed "Mirroring" "More than one source ports and send traffic from all source ports test succeed"
} else { 
    failed  "Mirroring" "More than one source ports and send traffic from source ports test failed"
}


#3. receiving traffic from all source ports  test 


puts "+++++++++++++++++++++++++++++++++++++++"
puts "Test case :receiving traffic from all source ports  test "
puts "Note :Receiving traffic from all source ports  test  need at least 4 IXIA ports "
puts "but currently only 3 IXIA ports connected DUT ,so this test case can not be processed"
puts "+++++++++++++++++++++++++++++++++++++++"

clear_ownership -alias allport