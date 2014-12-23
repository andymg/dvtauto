#!/bin/tcl

#Filename: 13.12.tcl
#History:
#        12/29/2013- Miles,Created
#        1/8/2014  - Miles,Updated
#Copyright(c): Transition Networks, Inc.2013


#Notes:
#The target of following test cases  is  test chage dynamic binding table to static table 


source ./init.tcl
source  $path/../base/dhcpSnooping.tcl


set phymode $::ixiaphymode
#dut port1 connect ixia ixiap1
#dut port2 connect ixia ixiap2
set port1 $::dutp1
set port2 $::dutp2
setToFactoryDefault $dut1
dhcpSnooping::setglobalMode $dut1 enable
dhcpSnooping::setportmode $dut1 $port1 untrust
dhcpSnooping::setportmode $dut1 $port1 trust
arpInspec::globalMode $dut1 enable
arpInspec::portMode $dut1  $port1 enable
arpInspec::portMode $dut1  $port2 disable


connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport  -loginname miles   -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

#In order to get a dynaic binding table from DHCP snooping ,simulating  DHCP interactive process  though sendend dhcp packets

#send DHCP discover packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-discover.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
after 2000
#send DHCP offer packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-offer.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
after 2000

#send DHCP request packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-request.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
after 2000
#send DHCP ack packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-ack.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
after 2000

puts "Note:please  make sure ARP Inspection binding entry must be as following ,any other binding entries are not supported"
puts "  PORT        VLAN            MAC                    IP "
puts "  $port1           1         00 14 22 8c 3b b9      192.168.100.2"

arpInspec::walkdynamictable $dut1
arpInspec::transDtoS  $dut1 enable

set srcMac "00 14 22 8c 3b b9"
set destBroMac  "ff ff ff ff ff ff"
set destMac "00 00 00 44 44 44"
set unkonwMac "00 00 00 00 00 00"
set mac1 "00 00 00 55 55 55"
set mac2 "00 00 00 66 66 66"
set sendIp "1192.168.100.2"
set targIp "192.168.100.3"
set ip1   "192.168.1.3"
set ethtype ethernetii



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
    passed  "Arp Inspection" "Arp Request packets that matched static table (change dynamic to static)  from the Ingress test succeed"
} else { 
    failed  "Arp Inspection" "Arp Request packets that matched static table (change dynamic to static)  from the Ingress test  failed"
}


#.2  Arp Reply packets that Matched the arp inspection dynamic table from the Ingress port  test 

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac -frametype $ethtype -protocol arp -operation arpReply -sendHardAdd  $srcMac \
-sendProtAdd $sendIp -targetHardAdd $destMac -targetProtAdd $targIp   -dbgprt 1
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
    passed  "Arp Inspection" "Arp Reply packets that matched static table (change dynamic to static) from the Ingress test succeed"
} else { 
    failed  "Arp Inspection" "Arp Reply packets that matched static table (change dynamic to static) from the Ingress test  failed"
}

clear_ownership -alias allport
