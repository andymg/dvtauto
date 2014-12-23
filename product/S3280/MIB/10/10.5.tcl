#!/usr/bin/env tclsh

#Filename: 10.5.tcl
#History:
#        01/14/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014


#Notes:
#The target of this test MLD v1 proxy function

#precondition: all configurre should be default value except below mention.

# Steps:
# 1. factory default DUT
# 2. as default config of groups check DUT received mld leave report
# 3. Enable proxy and test the report and done packet

variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set MultiMac16 "33 33 00 00 00 16"
set MultiMac2 "33 33 00 00 00 02"
set srcMac16 "00 C0 F2 00 00 16"
set MultiMac11 "33 33 00 00 00 11"
set MultiMac12 "33 33 00 00 00 12"
set dutmac [getDutMacAddr $::dut]

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
set desc "Testing MLD proxy function for MLD report facket"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# enable proxy config 
ipmc::ipmcProxy MLD True

ipmc::vlanSnoopingAdd MLD 1 True

# set p3 as the router port
ipmc::ipmcRouterPortSet MLD $::dutP3 True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 500
stop_capture -alias ixiap3

set getCaptured3 [check_capture -alias ixiap3 -srcmac $dutmac -dstmac $MultiMac11]
puts "$getCaptured3 packets received on p3"

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"
if { $getCaptured3 == 1} {
	passed "10.5.1" $desc
} else {
	failed "10.5.1" $desc
}

####################################################################################################
set desc "Testing MLD proxy function for MLD done facket"

# send mldv1 report packet
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2
send_traffic -alias ixiap2 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

# send mldv1 done packet and capture on router port
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac2 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 done -groupmldv1 $group1 -dbgprt 1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 2000
stop_capture -alias ixiap3

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

set getCaptured3 [check_capture -alias ixiap3 -srcmac $dutmac -dstmac $MultiMac2]
puts "$getCaptured3 packets received on p3"

if { $getCaptured3 == 1} {
	passed "10.5.2" $desc
} else {
	failed "10.5.2" $desc
}