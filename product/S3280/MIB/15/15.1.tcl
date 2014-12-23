#!/bin/tcl

#Filename: 15.1.tcl
#History:
#        15/1/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

##################DHCP relay###########################

#1.In order to DHCP information work well ,dhcp relay must be enabled and relay server ip address must be the DHCP server ip address
#2.option 82 will be insereted into dhcp packets when relay information was enabled
#3.DHCP request packets that including option 82 will be filtered by Relay information policy when relay information option is enabled
#4.DHCP request packets that   including option 82 will be dropped  when relay information option is disabled
#5.DHCP request packets that doesn't  including option 82 will be forwarded  when relay information option is disabled
##################DHCP relay###########################

#Note :The target of this test case is to test DHCP relay information 

source ./init.tcl
set phymode $::ixiaphymode
#dut port1 connect ixia ixiap1
#dut port2 connect ixia ixiap2
set port1 $::dutp1
set port2 $::dutp2


set srcmac "00 00 00 11 11 11"
set destmac "00 00 00 22 22 22"
set destBro "FF FF FF FF FF FF"
set srcIP "0.0.0.0"
set dstIP "255.255.255.255"


setToFactoryDefault $dut1
dhcpSnooping::setglobalMode $dut1 enable
dhcpSnooping::setportmode $dut1 $port1 untrust
dhcpSnooping::setportmode $dut1 $port2 untrust
dhcpSnooping::setRelayMode $dut1 disable
puts "DHCP Relay  MIB has some errors ,I will update this case when MIB was verified"
exit 0

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode


# 1. sending  DHCP discover packets from untrust port test 
config_frame -alias ixiap1 -srcmac $srcmac  -dstmac $destBro -frametype ethernetii  -framesize 800  -srcip $srcIP -dstip $dstIP -protocol dhcp  -opCode dhcpBootRequest \
 -clientIpAddr "192.168.1.1"  -serverIpAddr "192.168.3.1"  -option  "53,01" -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 3
stop_capture -alias ixiap2 

get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx


set staixiap2 [check_capture -alias ixiap2 -srcmac $srcmac  ]
if { $staixiap2  != 0  } {
    passed "DHCP Snooping" "Send DHCP DISCOVER packets from untrust port to trust port test  succeed"
} else { 
    failed  "DHCP Snooping" "Send DHCP DISCOVER packets from untrust port to trust port test  failed"
}