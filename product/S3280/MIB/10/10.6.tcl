#!/usr/bin/env tclsh

#Filename: 10.6.tcl
#History:
#        01/15/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014


#Notes:
#The target of this test MLD v1 groups and multistream packets forwards

#precondition: 1. all configurre should be default value except below mention.
#              2. disable MLD flooding 

# Steps:
# 1. factory default DUT
# 2. set port 2 as router port, add port 1 to group1
# 3. Sending multistream packets on router port, capture packets on other two ports 

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


set testPackets 50
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
set desc "Testing DUT received  MLD report packet, one new group1 is added, the multistream is one of the groups"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# enable proxy config 
ipmc::ipmcProxy MLD True
# disable flooding 
ipmc::ipmcFloodingEnable MLD False

ipmc::vlanSnoopingAdd MLD 1 True

# set p3 as the router port
ipmc::ipmcRouterPortSet MLD $::dutP2 True

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

send_traffic -alias ixiap1 -actiontype start
after 500
set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

# send multistream packets to router port
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac11 -ipv6src $ipv6srcip2 -ipv6des $group1

config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 1000
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured1 [check_capture -alias ixiap1 -srcmac $srcMac16 -dstmac $MultiMac11]
set captured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac11]

puts "$captured1 packets received on p1"
puts "$captured3 packets received on p3"

if { [llength $groups] == 1 && $captured1 == $testPackets &&  $captured3 == 0} {
	passed "10.6.1" $desc
} else {
	failed "10.6.1" $desc
}

####################################################################################################
set desc "Testing DUT received  MLD report packet, and the multistream is not one of the groups"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# enable proxy config 
ipmc::ipmcProxy MLD True
# disable flooding 
ipmc::ipmcFloodingEnable MLD False

# set p3 as the router port
ipmc::ipmcRouterPortSet MLD $::dutP2 True

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

send_traffic -alias ixiap1 -actiontype start
after 500
set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

# send multistream packets to router port
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac12 -ipv6src $ipv6srcip2 -ipv6des $group2

config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 1000
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured1 [check_capture -alias ixiap1 -srcmac $srcMac16 -dstmac $MultiMac12]
set captured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac12]

puts "$captured1 packets received on p1"
puts "$captured3 packets received on p3"

if { [llength $groups] == 1 && $captured1 == 0 &&  $captured3 == 0} {
	passed "10.6.2" $desc
} else {
	failed "10.6.2" $desc
}

####################################################################################################
set desc "MLD multistream forwarding test,with VLAN 100, the multistream is one of the groups"
# add vlan 100 and set port 1 2 3 to cport
vlan::porttypeSet $::dutP1 cport
vlan::porttypeSet $::dutP2 cport
vlan::porttypeSet $::dutP3 cport
vlan::vlanadd 100 [port2Portlist "$::dutP1 $::dutP2 $::dutP3"]

ipmc::vlanSnoopingAdd MLD 100 True

# remove group1
# config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
#              -srcmac $srcMac16 -dstmac $MultiMac2 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
#              -mldv1 done -groupmldv1 $group1
# config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

# send_traffic -alias ixiap1 -actiontype start
# after 1000

# send report group1 in VLAN 100
config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -tpid 8100 \
             -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip16 \
             -mldv1 report -groupmldv1 $group1 -dbgprt 1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

send_traffic -alias ixiap1 -actiontype start
after 500
set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

# send multistream packets to router port
config_frame -alias ixiap2 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -tpid 8100 \
             -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac11 -ipv6src $ipv6srcip2 -ipv6des $group1 -dbgprt 1

config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
after 1000
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured1 [check_capture -alias ixiap1 -srcmac $srcMac16 -dstmac $MultiMac11]
set captured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac11]

puts "$captured1 packets received on p1"
puts "$captured3 packets received on p3"

if { $captured1 == $testPackets &&  $captured3 == 0} {
	passed "10.6.3" $desc
} else {
	failed "10.6.3" $desc
}