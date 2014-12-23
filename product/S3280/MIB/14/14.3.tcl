#!/bin/tcl

#Filename: 14.3.tcl
#History:
#        1/14/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

##################Ip Source Guard introduction###########################
#IP traffic is filtered based on the source IP and MA C addresses. The switch forwards traffic only when 
#the source IP and MAC addresses match an entry in the IP source binding table
##################Ip Source Guard introduction###########################tnIPSourceGuardIfMaxDynamicClients(oid)
#Notes:Ip Source Guard Max Dynamic client test 


source ./init.tcl

set phymode $::ixiaphymode
#dut port1 connect ixia ixiap1
#dut port2 connect ixia ixiap2
set port1 $::dutp1
set port2 $::dutp2
setToFactoryDefault $dut1
after 1000
dhcpSnooping::setglobalMode $dut1 enable
dhcpSnooping::setportmode $dut1 $port1 untrust
dhcpSnooping::setportmode $dut1 $port2 trust
IPSG::setglobalMode $dut1 enable
IPSG::setportMode $dut1  $port1 enable
IPSG::setportMode $dut1  $port2 disable

#1.Ip Source Guard Max Dynamic client 0 test 
IPSG::MaxDynaClient  $dut1 $port1 0
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport  -loginname miles   -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

#In order to get a dynaic binding table from DHCP snooping ,simulating  DHCP interactive process  though sendend dhcp packets
#send DHCP discover packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-discover.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
puts "send DHCP discover packets from IXIA port $ixiap1 to dut port $port1"
after 2000
#send DHCP offer packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-offer.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
puts "send DHCP offer packets from IXIA port $ixiap2 to dut port $port2"
after 2000

#send DHCP request packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-request.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
puts "send DHCP request packets from IXIA port $ixiap1 to dut port $port1"
after 2000
#send DHCP ack packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-ack.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
puts "send DHCP ack packets from IXIA port $ixiap2 to dut port $port2"
after 2000

set  entry [IPSG::walkdynamictable $dut1]
if { $entry == 0 } {
    passed  "Ip Source Guard" "Ip Source Guard  Max Dynamic client value 0 test test succeed"
} else { 
    failed  "Ip Source Guard" "Ip Source Guard  Max Dynamic client valude 0 test  test failed"
}



#2.Ip Source Guard Max Dynamic client 1 test 
IPSG::MaxDynaClient  $dut1 $port1 1
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport  -loginname miles   -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

#In order to get a dynaic binding table from DHCP snooping ,simulating  DHCP interactive process  though sendend dhcp packets
#send DHCP discover packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-discover.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
puts "send DHCP discover packets from IXIA port $ixiap1 to dut port $port1"
after 2000
#send DHCP offer packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-offer.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
puts "send DHCP offer packets from IXIA port $ixiap2 to dut port $port2"
after 2000

#send DHCP request packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-request.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
puts "send DHCP request packets from IXIA port $ixiap1 to dut port $port1"
after 2000
#send DHCP ack packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-ack.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
puts "send DHCP ack packets from IXIA port $ixiap2 to dut port $port2"
after 2000

set  entry [IPSG::walkdynamictable $dut1]
if { $entry == 1 } {
    passed  "Ip Source Guard" "Ip Source Guard  Max Dynamic client value 1 test test succeed"
} else { 
    failed  "Ip Source Guard" "Ip Source Guard  Max Dynamic client valude 1 test  test failed"
}

#3.Ip Source Guard Max Dynamic client unlimited test 
IPSG::MaxDynaClient  $dut1 $port1 unlimited
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport  -loginname miles   -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

#In order to get a dynaic binding table from DHCP snooping ,simulating  DHCP interactive process  though sendend dhcp packets
#send DHCP discover packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-discover.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
puts "send DHCP discover packets from IXIA port $ixiap1 to dut port $port1"
after 2000
#send DHCP offer packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-offer.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
puts "send DHCP offer packets from IXIA port $ixiap2 to dut port $port2"
after 2000

#send DHCP request packet from IXIA ixiap1
config_frame  -alias ixiap1 -import DHCP-request.enc 
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 1
puts "send DHCP request packets from IXIA port $ixiap1 to dut port $port1"
after 2000
#send DHCP ack packet from IXIA ixiap2
config_frame  -alias ixiap2 -import DHCP-ack.enc 
config_stream -alias ixiap2 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap2 -actiontype start -time 1
puts "send DHCP ack packets from IXIA port $ixiap2 to dut port $port2"
after 2000

set  entry [IPSG::walkdynamictable $dut1]
if { $entry == 1 } {
    passed  "Ip Source Guard" "Ip Source Guard  Max Dynamic client value unlimited test test succeed"
} else { 
    failed  "Ip Source Guard" "Ip Source Guard  Max Dynamic client valude unlimited test  test failed"
}

#4.Ip Source Guard Max Dynamic 2 test
puts "+++++++++++++++++++++++++++++++++++++"
puts "Note :  There are some limites for these test cases ,because IXIA could only import one discover packet,"
puts "so there is max one bingding entry exit in dynamic binding table.so for Max Dynamic client valude "
puts "are 1 and unlimited test cases are not very accurate "
puts "when Max Dynamic client valude is 2 ,which can not be tested "
puts "+++++++++++++++++++++++++++++++++++++"

clear_ownership -alias allport