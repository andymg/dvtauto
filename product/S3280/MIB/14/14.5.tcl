
#!/bin/tcl

#Filename: 14.5.tcl
#History:
#        1/14/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

##################Ip Source Guard introduction###########################
#IP traffic is filtered based on the source IP and MA C addresses. The switch forwards traffic only when 
#the source IP and MAC addresses match an entry in the IP source binding table
##################Ip Source Guard introduction###########################tnIPSourceGuardIfMaxDynamicClients(oid)
#Notes:Ip Source Guard dynamic binding table test 


source ./init.tcl
set phymode $::ixiaphymode
#dut port1 connect ixia ixiap1
#dut port2 connect ixia ixiap2
set port1 $::dutp1
set port2 $::dutp2
setToFactoryDefault $dut1
after 1000
IPSG::setglobalMode $dut1 enable
IPSG::setportMode $dut1  $port1 enable
IPSG::setportMode $dut1  $port2 disable
dhcpSnooping::setglobalMode $dut1 enable
dhcpSnooping::setportmode $dut1 $port1 untrust
dhcpSnooping::setportmode $dut1 $port2 trust
set srcMac "00 14 22 8c 3b b9 "
set destMac "00 00 00 44 44 44"
set sendIp "192.168.100.2"
set targIp "192.168.100.1"
set ethtype ethernetii

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport  -loginname miles   -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode


#without any static binding table
config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac -frametype $ethtype -srcip $sendIp -dstip $targIp   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destMac  ]
set a $getCaptured
puts "get captured $a"

#create a dynamic binding table

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

IPSG::walkdynamictable $dut1

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac -frametype $ethtype -srcip $sendIp -dstip $targIp   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destMac  ]
set b $getCaptured
puts "get captured $b"
if { $a == 0 && $b != 0 } {
	puts "DUT forwards $a IP packets when Ip Source Guard dynamic table is empty"
	puts "DUT forwards $b IP packets when IP packets meatched the dynamic table"
    passed  "Ip Source Guard" "Ip Source Guard  dynamic binding table test succeed"
} else { 
	puts "DUT forwards $a IP packets when Ip Source Guard dynamic table is empty"
	puts "DUT forwards $b IP packets when IP packets meatched the dynamic table"
    failed  "Ip Source Guard" "Ip Source Guard  dynamic binding table test  failed"
}
clear_ownership -alias allport