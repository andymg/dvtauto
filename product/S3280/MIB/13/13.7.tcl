#!/bin/tcl

#Filename: 13.7.tcl
#History:
#        12/27/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

##################Arp inspection static table ###########################
# 1.Verifies that each of these intercepted packets has a valid IP-to-MAC address binding before 
#updating the local ARP cache or before forwarding the packet to the appropriate destination 
# 2. If the ingress and egress  arp packets didn't match the dynamic or static matching map ,Dropping invalid ARP packets
# 3.vitesse chip supports Ingress and Egress control
# 4. static table IP-to-MAC means :check sender mac address and sender ip address in arp  header  ,which not the the mac address in frame header
##################Arp inspection static table ###########################


#Notes:
#The target of following test cases  is  test ARP Inspection static table in vlan 1  worked well or not.
#test Arp Request packets from the Egress port 





source ./init.tcl
source  $path/../base/vlan.tcl
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
set mac1 "00 00 00 55 55 55"
set mac2 "00 00 00 66 66 66"
set sendIp "192.168.1.1"
set targIp "192.168.1.2"
set ip1   "192.168.1.3"
set ethtype ethernetii

#enable arp inspection
arpInspec::globalMode $dut1 enable
arpInspec::portMode $dut1  $port1 disable
arpInspec::portMode $dut1  $port2 enable
#create an ARP Inspection static entry
arpInspec::createStaticTable $dut1  $port1 1  $srcMac $sendIp


#.1  Arp Request packets that Matched the arp inspection static table from the Egress port  test 

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac -frametype $ethtype -protocol arp -operation arpRequest -sendHardAdd  $srcMac \
-sendProtAdd $sendIp -targetHardAdd $unkonwMac -targetProtAdd $targIp   -dbgprt 1
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
if { $getCaptured != 0 } {
    passed  "Arp Inspection" "Arp Request packets that matched static table  from the Egress test succeed"
} else { 
    failed  "Arp Inspection" "Arp Request packets that matched static table from the Egress test  failed"
}


#.2  Arp Request packets that didn't match sender mac address  ( match  vlan ,ip sender ip address and port) in static table from the Egress test  

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac -frametype $ethtype -protocol arp -operation arpRequest -sendHardAdd  $mac1  \
-sendProtAdd $sendIp -targetHardAdd $unkonwMac -targetProtAdd $targIp   -dbgprt 1
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
    passed  "Arp Inspection" "Arp Request packets that didn't match vlan in  static table  from the Egress test succeed"
} else { 
    failed  "Arp Inspection" "Arp Request packets that didn't match vlan in  static table  from the Egress test  failed"
}


#.3  Arp Request packets that didn't sender ip address  ( match  vlan ,ip sender ip address and port) in static table from the Egress test  

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac -frametype $ethtype -protocol arp -operation arpRequest -sendHardAdd  $srcMac  \
-sendProtAdd $ip1 -targetHardAdd $unkonwMac -targetProtAdd $targIp   -dbgprt 1
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
    passed  "Arp Inspection" "Arp Request packets that didn't match sender ip address  in  static table  from the Egress test succeed"
} else { 
    failed  "Arp Inspection" "Arp Request packets that didn't match sender ip address  in  static table  from the Egress test  failed"
}

#.4  Arp Request packets that didn't match vlan ( match sender mac address ,ip sender ip address and port) in static table from the Egress test  

set portlist  [port2Portlist "$port1 $port2"]
puts "portlist is $portlist"
vlan::vlanadd 2  $portlist  $dut1


config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac  -vlanmode  singlevlan -vlanid  2 -frametype  $ethtype -protocol arp -operation arpRequest -sendHardAdd  $srcMac  \
-sendProtAdd $sendIp -targetHardAdd $unkonwMac -targetProtAdd $targIp   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destBroMac -vlanid 2 ]
puts "get captured $getCaptured"
if { $getCaptured == 0 } {
    passed  "Arp Inspection" "Arp Request packets that didn't match vlan in static table  from the Egress test succeed"
} else { 
    failed  "Arp Inspection" "Arp Request packets that didn't match vlan  in static table  from the Egress test  failed"
}

clear_ownership -alias allport