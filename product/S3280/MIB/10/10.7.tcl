#!/usr/bin/env tclsh

#Filename: 10.7.tcl
#History:
#        01/15/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014


#Notes:
#The target of this test MLD query

#precondition: 1. all configurre should be default value except below mention.
#              2. add MLD VLAN snooping 

# Steps:
# 1. factory default DUT
# 2. add new MLD vlan snooping and send report packet on p1
# 3. capture query packet on p1

variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set MultiMac16 "33 33 00 00 00 16"
set MultiMac2 "33 33 00 00 00 02"
set MultiMac1 "33 33 00 00 00 01"
set srcMac16 "00 C0 F2 00 00 16"
set MultiMac11 "33 33 00 00 00 11"
set MultiMac12 "33 33 00 00 00 12"
set dutmac [getDutMacAddr $::dut]
puts "Current dut mac is :$dutmac"

set ipv6srcip2 "FE80::2"
set ipv6dstip2 "FF02::2"
set ipv6dstip16 "FF02::16"

set group1 "FF1E::11"
set group2 "FF1E::12"
set errorgroup "FE1E::12"


set testPackets 5
puts "Test on DUT: $::dut"
#set DUT factory default
setToFactoryDefault $::dut

# connect ixia and take owner ship of ixia ports
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 \
             -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode
config_portprop -alias ixiap3 -autonego enable -phymode $phymode
####################################################################################################
set desc "Testing DUT MLD query packets when MLD query is default enabled"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True

ipmc::vlanSnoopingAdd MLD 1 True
# Set VLAN 1 snooping Query interval to 2 seconds
ipmc::ipmcQRIset MLD 1 10
ipmc::ipmcQIset MLD 1 5
# set p3 as the router port
ipmc::ipmcRouterPortSet MLD $::dutP2 True

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
after 17000
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured1 [check_capture -alias ixiap1 -srcmac $dutmac -dstmac $MultiMac1]
set captured3 [check_capture -alias ixiap3 -srcmac $dutmac -dstmac $MultiMac1]

puts "$captured1 general query packets received on p1"
puts "$captured3 general query packets received on p3"

if { $captured3 >=4 && $captured3 <= 5 && $captured1 >= 4 && $captured1 <= 5} {
	passed "10.7.1" $desc
} else {
	failed "10.7.1" $desc
}

####################################################################################################
set desc "Testing DUT MLD query packets when MLD query is disabled"
# disable Query on MLD vlan 1
ipmc::ipmcQueryEnable MLD 1 False

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
after 17000
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured1 [check_capture -alias ixiap1 -srcmac $dutmac -dstmac $MultiMac1]
set captured3 [check_capture -alias ixiap3 -srcmac $dutmac -dstmac $MultiMac1]

puts "$captured1 general query packets received on p1"
puts "$captured3 general query packets received on p3"

if { $captured3 == 0 && $captured1 == 0} {
	passed "10.7.2" $desc
} else {
	failed "10.7.2" $desc
}
