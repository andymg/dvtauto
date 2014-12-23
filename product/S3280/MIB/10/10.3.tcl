#!/usr/bin/env tclsh

#Filename: 10.3.tcl
#History:
#        01/14/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014


#Notes:
#The target of this test MLD v1 report packets

#precondition: all configurre should be default value except below mention.

# Steps:
# 1. factory default DUT
# 2. as default config of groups check DUT received mld v1 report
# 3. Add mld groups check DUT received normal v1 report and error report

variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set MultiMac16 "33 33 00 00 00 16"
set srcMac16 "00 C0 F2 00 00 16"
set MultiMac11 "33 33 00 00 00 11"
set MultiMac12 "33 33 00 00 00 12"

set ipv6srcip2 "FE80::2"
set ipv6dstip2 "FF02::16"

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
set desc "Enable MLD and received normal MLDv1 report packet when no vlan group is added"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

if {[llength $groups] == 0} {
	passed "10.3.1" $desc
} else {
	failed "10.3.1" $desc
}
####################################################################################################
set desc "Enable MLD and received normal MLDv1 report packet with VLAN 1 group is added"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# add mld vlan 1 group
ipmc::vlanSnoopingAdd MLD 1 True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"


if {[llength $groups] == 1} {
	passed "10.3.2" $desc
} else {
	failed "10.3.2" $desc
}

####################################################################################################
set desc "Enable MLD and received normal MLDv1 tagged report packet with VLAN 1 group is added"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# add mld vlan 1 group

config_frame -alias ixiap2 -frametype ethernetii -vlanmode singlevlan -vid 100 -tipd 8100\
             -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group2 -dbgprt 1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"


if {[llength $groups] == 1} {
	passed "10.3.3" $desc
} else {
	failed "10.3.3" $desc
}

####################################################################################################
set desc "Enable MLD and received error MLDv1 report packet with VLAN 1 group is added"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# add mld vlan 1 group

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none\
             -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $errorgroup -dbgprt 1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"


if {[llength $groups] == 1} {
	passed "10.3.4" $desc
} else {
	failed "10.3.4" $desc
}

####################################################################################################
set desc "Enable MLD and received normal MLDv1 tagged report packet with VLAN 100 group is added"
# enable MLD 
ipmc::ipmcSnoopingEnable MLD True
# add mld vlan 1 group
ipmc::vlanSnoopingAdd MLD 100 True


vlan::porttypeSet $::dutP1 cport
vlan::porttypeSet $::dutP2 cport
vlan::vlanadd 100 [port2Portlist "$::dutP1 $::dutP2"]

config_frame -alias ixiap2 -frametype ethernetii -vlanmode singlevlan -vlanid 100 -tpid 8100\
             -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group2 -dbgprt 1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"


if {[llength $groups] == 2} {
	passed "10.3.5" $desc
} else {
	failed "10.3.5" $desc
}