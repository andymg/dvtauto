#!/bin/tcl

#Filename: 13.10.tcl
#History:
#        12/29/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

##################Arp inspection introduction###########################
# Arp inspection  check the ARP body for invalid and  unexpected IP addresses. Addresses 
# include 0.0.0.0, 255.255.255.255, and all IP multicast addresses. Sender IP 
# addresses are checked in all ARP requests  and responses, and target IP addresses 
# are checked only in ARP responses
##################Arp inspection introduction###########################
#Notes:
#The target of following test cases  is  test sender and/or targert protocol address is multicast 224.0.1.1  in arp request packet
#DUT should drop this kind of packets 





source ./init.tcl
set phymode $::ixiaphymode
#port1 and port2 are connected to ixia port1 and ixia port2
set port1 $::dutp1
set port2 $::dutp2


setToFactoryDefault $dut1
puts "start connect_ixia"
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

set srcMac "00 00 00 33 33 33"
set destBroMac  "ff ff ff ff ff ff"
set destMac "00 00 00 44 44 44"
set unkonwMac "00 00 00 00 00 00"
set sendIp "192.168.1.1"
set targIp "192.168.1.2"
set errIp1 "0.0.0.0"
set errIp2 "255.255.255.255"
set multi1 "224.0.1.1"
set ethtype ethernetii

#enable arp inspection
arpInspec::globalMode $dut1 enable
arpInspec::portMode $dut1  $port1 enable
arpInspec::portMode $dut1  $port2 disable

#.1 unexpected sender protocol address 0.0.0.0  in arp request packets  test 

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac -frametype $ethtype -protocol arp -operation arpRequest -sendHardAdd  $srcMac  \
-sendProtAdd $multi1 -targetHardAdd $unkonwMac -targetProtAdd $targIp   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destBroMac  ]
puts "get captured $getCaptured"
if { $getCaptured == 0 } {
    passed  "Arp Inspection" "Arp Inspection  error sender protocol ip address 224.0.1.1  in arp Request packets test succeed"
} else { 
    failed  "Arp Inspection" "Arp Inspection  error sender protocol ip address 224.0.1.1  in arp Request packets test"
}


#.2 unexpected target protocol address 224.0.1.1  in arp request packets  test 

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac -frametype ethernetii -protocol arp -operation arpRequest -sendHardAdd  $srcMac  \
-sendProtAdd $sendIp -targetHardAdd $unkonwMac -targetProtAdd $multi1  -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destBroMac  ]
puts "get captured $getCaptured"
if { $getCaptured == 0 } {
    passed "Arp Inspection" "arp inspection  error target protocol ip address 0.0.0.0  in arp Request packets test succeed"
} else { 
    failed  "Arp Inspection" "arp inspection  error target protocol ip address 0.0.0.0  in arp Request packets test"
}



#.3 unexpected sender and target  protocol address 224.0.1.1  in arp request packets  test 

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac -frametype ethernetii -protocol arp -operation arpRequest -sendHardAdd  $srcMac  \
-sendProtAdd $multi1 -targetHardAdd $unkonwMac -targetProtAdd $errIp1   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destBroMac  ]
puts "get captured $getCaptured"
if { $getCaptured == 0 } {
    passed "Arp Inspection" "arp inspection  error sender and target protocol ip address 224.0.1.1  in arp Request packets test succeed"
} else { 
    failed  "Arp Inspection" "arp inspection  error sender and target protocol ip address 224.0.1.1  in arp Request packets test"
}

clear_ownership -alias allport