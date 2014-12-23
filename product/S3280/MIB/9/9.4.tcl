#!/bin/tclsh
#Filename: 9.4.tcl
#History:
#        12/10/2013- Andy,Created
#
#Copyright(c): Transition Networks, Inc.2013
##########################################################################################
#  Test points:
#  1. IGMP v3 report
#  2. Check the IGMP proxy
##########################################################################################
variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set group1 "228.0.0.5"
set group2 "228.0.0.2"
set group3 "228.0.0.13"
set group4 "235.0.2.14"

setToFactoryDefault $::dut
after 1000
# Enable IGMP snooping and add new IGMP vlan entries
ipmc::ipmcSnoopingEnable IGMP True
ipmc::vlanSnoopingAdd IGMP 100 True
ipmc::vlanSnoopingAdd IGMP 1 True


connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 \
             -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode
config_portprop -alias ixiap3 -autonego enable -phymode $phymode

# ###############################################################################################################
set desc "Check the v3repot packet on DUT"

# Set dutP2 to router port to receive leave packet
ipmc::ipmcRouterPortSet IGMP $::dutP2 True
# Disable fast leave on dutP1
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 False

clear_stat -alias allport
# send v3 report report packet on port 1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 \
             -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v3report \
             -v3groupip1 $group1 -v3includeip1 [list 192.168.1.1 192.168.1.2]
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2
after 500

send_traffic -alias ixiap1 -actiontype start -time 2

set groups [ipmc::ipmcGroupGet]
puts "current groups: $groups"
if { [llength $groups] == 1 && [string first $group1 $groups] > 0} {
	passed "9.4.1" $desc
} else {
	failed "9.4.1" $desc
}

###############################################################################################################
set desc "Check the v3repot packet on DUT"

# Set dutP2 to router port to receive leave packet
ipmc::ipmcRouterPortSet IGMP $::dutP2 True
# Disable fast leave on dutP1
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 False

clear_stat -alias allport
# send v3 report report packet on port 1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 \
             -srcip 192.168.3.64 -dstip 225.0.0.5 -igmptype v3report \
             -v3groupip1 $group2 -v3includeip1 [list 192.168.1.1 192.168.1.2] \
             -v3groupip2 $group3 -v3includeip2 [list 192.168.2.1 192.168.2.2]
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

send_traffic -alias ixiap1 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current groups: $groups"
if { [llength $groups] == 3 && [string first $group2 $groups] > 0 && [string first $group3 $groups] > 1} {
	passed "9.4.2" $desc
} else {
	failed "9.4.2" $desc
}
