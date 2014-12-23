#!/bin/tcl
#Filename: 9.2.tcl
#History:
#        12/10/2013- Andy,Created
#
#Copyright(c): Transition Networks, Inc.2013
##########################################################################################
#  Test points:
#  1. check v1/v2 report packet received on DUT with VID
#  2. check v2 leave packet
##########################################################################################
variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set group1 "228.0.0.11"
set group2 "228.0.0.12"
set group3 "228.0.0.13"
set group4 "235.0.2.14"

setToFactoryDefault $::dut
after 1000
# Enable IGMP snooping and add new IGMP vlan entries
ipmc::ipmcSnoopingEnable IGMP True
ipmc::vlanSnoopingAdd IGMP 100 True
ipmc::vlanSnoopingAdd IGMP $::dutP1 True


connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

####################################################################################################
set desc "IGMP test report packet with vlanid 100, vlan 100 is not added"
after 500
clear_stat -alias allport
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 True
config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype v1report -groupip $group1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start
set groups [ipmc::ipmcGroupGet]
puts "Current group1 $groups "
if {[llength $groups] == 0} {
	passed "9.2.1" $desc
} else {
	failed "9.2.1" $desc
}

####################################################################################################
set desc "IGMP test v1 report packet with vlanid 100, vlan 100 is created already"
after 500
# add vlan 100 in DUT 
vlan::vlanadd 100 [port2Portlist "$::dutP1 $::dutP2"]
# set dutP1 and dutP2 to cport
after 500
vlan::porttypeSet $::dutP1 cport
vlan::porttypeSet $::dutP2 cport
clear_stat -alias allport
config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype v1report -groupip $group1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start -time 1

set groups [ipmc::ipmcGroupGet]
puts "Current group1 $groups "
puts "[lindex [split $groups " "] 3]"
if {[llength $groups] == 1} {
	passed "9.2.2" $desc
} else {
	failed "9.2.2" $desc
}

####################################################################################################
set desc "IGMP test v2 report packet with vlanid 100, vlan 100 is created already"
after 500
clear_stat -alias allport
config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.62 -dstip 225.0.0.5 -igmptype v2report -groupip $group2
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start -time 1

set groups [ipmc::ipmcGroupGet]
puts "Current group1 $groups "
if {[string first "228.0.0.12" $groups] > 1} {
	passed "9.2.3" $desc
} else {
	failed "9.2.3" $desc
}

####################################################################################################
set desc "IGMP test v2 report packet with vlanid 100, vlan 100 is created already"

after 500
clear_stat -alias allport
config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v2report -groupip $group3
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start -time 1

set groups [ipmc::ipmcGroupGet]
puts "Current groups $groups"
if {[string first $group3 $groups] > 1 } {
	passed "9.2.4" $desc
} else {
	failed "9.2.4" $desc
}

####################################################################################################
set desc "IGMP test v2 report packet with vlanid 100 to a router port"

after 500
clear_stat -alias allport
ipmc::ipmcRouterPortSet IGMP $::dutP2 True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v2report -groupip 226.0.0.9
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap2 -actiontype start -time 1

set groups [ipmc::ipmcGroupGet]
puts "Current groups $groups"
if {[string first "226.0.0.9" $groups] > 1 } {
	passed "9.2.5" $desc
} else {
	failed "9.2.5" $desc
}
##################################################################################
set desc "IGMP test v2 report packet vlan none, check report packet"

after 500
clear_stat -alias allport
#config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v2report -groupip $group4
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v2report -groupip $group4
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2

set getCaptured [check_capture -alias ixiap2 -srcmac $::ixiaMac3 ]
puts "get $getCaptured IGMP v2 report packets"
set groups [ipmc::ipmcGroupGet]
puts "Current groups $groups"
if {[string first $group4 $groups] > 1 && $getCaptured == 1} {
	passed "9.2.6" $desc
} else {
	failed "9.2.6" $desc
}

##################################################################################
set desc "IGMP test v2 report packet vlan none, check leave packet"

after 500
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 True
clear_stat -alias allport
#config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -srcmac $::ixiaMac3 -dstmac $::ixiaMac2 -srcip 192.168.3.63 -dstip 224.0.0.2 -igmptype leave -groupip $group4
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac2 -srcip 192.168.3.63 -dstip 224.0.0.2 -igmptype leave -groupip $group4
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2

after 1000
set getCaptured [check_capture -alias ixiap2 -srcmac $::ixiaMac3]
puts "get $getCaptured IGMP v2 report packets"
set groups [ipmc::ipmcGroupGet]
puts "Current groups $groups"
if {[string first $group4 $groups] < 0 && $getCaptured == 1} {
	passed "9.2.7" $desc
} else {
	failed "9.2.7" $desc
}