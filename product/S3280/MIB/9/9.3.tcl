#!/bin/tclsh
#Filename: 9.3.tcl
#History:
#        12/10/2013- Andy,Created
#
#Copyright(c): Transition Networks, Inc.2013
##########################################################################################
#  Test points:
#  1. Check the IGMP leave proxy
#  2. Check the IGMP proxy
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
ipmc::vlanSnoopingAdd IGMP 1 True


connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

###############################################################################################################
set desc "Check the leave proxy for IGMP snooping"

# Set dutP2 to router port to receive leave packet
ipmc::ipmcRouterPortSet IGMP $::dutP2 True
# Disable fast leave on dutP1
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 False

#set leave proxy on dutP2
ipmc::ipmcLeaveProxy IGMP True

clear_stat -alias allport
# send report packet on port 1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v2report -groupip $group4
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1

send_traffic -alias ixiap1 -actiontype start -time 2

after 1000
# send leave packet on port dutP1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac2 -srcip 192.168.3.63 -dstip 224.0.0.2 -igmptype leave -groupip $group4
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1

# capture packet on dutP2
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2

set dutmac [getDutMacAddr $::dut]

set getCaptured [check_capture -alias ixiap2 -srcmac $dutmac -dstmac $::ixiaMac2 -dbgprt 1]

if { $getCaptured == 1} {
	passed "9.3.1" $desc
} else {
	failed "9.3.1" $desc
}


###############################################################################################################
set desc "Check the proxy for IGMP snooping"

# Set dutP2 to router port to receive leave packet
ipmc::ipmcRouterPortSet IGMP $::dutP2 True
# Disable fast leave on dutP1
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 False

#set leave proxy
ipmc::ipmcLeaveProxy IGMP False

#set proxy enable
ipmc::ipmcProxy IGMP True

clear_stat -alias allport
# send report packet on port 1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v2report -groupip $group4
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1

# capture packet on dutP2
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 5
stop_capture -alias ixiap2

set dutmac [getDutMacAddr $::dut]
puts "dutmac is $dutmac"
set getCaptured [check_capture -alias ixiap2 -srcmac $dutmac -dbgprt 1]

if { $getCaptured == 1} {
	passed "9.3.2" $desc
} else {
	failed "9.3.2" $desc
}