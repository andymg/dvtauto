#!/bin/tcl

#Filename: 25.4.tcl
#History:
#        1/15/2014- Miles,Created
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



#Note : this test case is to test one source Both direction port  direction



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
mirror::setDestPort $dut1 $port2

#1. test mirroring source port TX direction test 

#check RX 
config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
puts "send traffice from ixia port $ixiap1 to  dut port $port1"
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set Rxget [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destMac  ]
puts "Rx is $Rxget"
#check TX
config_frame  -alias ixiap3 -srcmac $Mac  -dstmac $srcMac   -dbgprt 1
config_stream -alias ixiap3 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap3 -actiontype start -time 2
puts "send traffice from ixia port $ixiap3 to  dut port $port3"
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
get_stat -alias ixiap3 -txframe ixiap3tx
puts "ixiap3_tx_frame: $ixiap3tx, ixiap2_rx_frame: $ixiap2rx"
set Txget [check_capture -alias ixiap2 -srcmac $Mac -dstmac $srcMac  ]
puts "Tx is $Txget"
if { $Txget !=0 && $Rxget != 0 } {
    passed "Mirroring" "Mirroring source port BOTH direction test succeed"
} else { 
    failed  "Mirroring" "Mirroring source port BOTH direction test failed"
}

clear_ownership -alias allport