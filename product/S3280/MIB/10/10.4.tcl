#!/usr/bin/env tclsh

#Filename: 10.4.tcl
#History:
#        01/14/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014


#Notes:
#The target of this test MLD v1 leave,fast leave and proxy leave

#precondition: all configurre should be default value except below mention.

# Steps:
# 1. factory default DUT
# 2. as default config of groups check DUT received mld leave report
# 3. Test leave report after report is received
# 4. Test fast leave report after report is received
# 5. Test leave proxy function

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
set desc "Default DUT, check MLDv1 report is received on DUT"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 leave -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

if {[llength $groups] == 0} {
	passed "10.4.1" $desc
} else {
	failed "10.4.1" $desc
}

####################################################################################################
set desc "After grou1 is added in DUT, check MLDv1 report is received on DUT"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# ADD vlan 1 in group
ipmc::vlanSnoopingAdd MLD 1 True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start
after 1000
set groups1 [ipmc::ipmcGroupGet]
puts "current groups $groups1"

# send leave packet 
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac2 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 done -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1

start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 5000
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set getCaptured2 [check_capture -alias ixiap2 -dstmac $MultiMac11]
set getCaptured3 [check_capture -alias ixiap3 -dstmac $MultiMac11]
puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"
if {[llength groups1] == 1 &&$getCaptured2 == 1 && $getCaptured3 == 0} {
	passed "10.4.2" $desc
} else {
	failed "10.4.2" $desc
}

####################################################################################################
set desc "After grou1 is added in DUT, check fast leave function"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# enable fastleave on p2
ipmc::ipmcFastLeaveEnable MLD 2 True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start
after 1000
set groups1 [ipmc::ipmcGroupGet]
puts "current groups $groups1"

# send leave packet 
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac2 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 done -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1

start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 5000
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set getCaptured2 [check_capture -alias ixiap2 -dstmac $MultiMac11]
set getCaptured3 [check_capture -alias ixiap3 -dstmac $MultiMac11]
puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"
if {[llength groups1] == 1 && $getCaptured2 == 0 && $getCaptured3 == 0} {
	passed "10.4.3" $desc
} else {
	failed "10.4.3" $desc
}

####################################################################################################
set desc "Testing MLD proxy function for MLD report facket"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# enable proxy config 
ipmc::ipmcProxy MLD False
ipmc::ipmcLeaveProxy MLD True
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
if { $getCaptured3 == 0} {
	passed "10.4.4" $desc
} else {
	failed "10.4.4" $desc
}
####################################################################################################
set desc "Testing MLD leave proxy function for MLD done facket"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# enable proxy config 
ipmc::ipmcProxy MLD False
ipmc::ipmcLeaveProxy MLD True
# set p3 as the router port
ipmc::ipmcRouterPortSet MLD $::dutP3 True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac2 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 done -groupmldv1 $group1 -dbgprt 1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 500
stop_capture -alias ixiap3

set getCaptured3 [check_capture -alias ixiap3 -srcmac $dutmac -dstmac $MultiMac2]
puts "$getCaptured3 packets received on p3"

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"
if { $getCaptured3 >= 1} {
	passed "10.4.5" $desc
} else {
	failed "10.4.5" $desc
}