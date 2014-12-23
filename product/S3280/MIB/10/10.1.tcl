#!/usr/bin/env tclsh

#Filename: 10.1.tcl
#History:
#        01/13/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014


#Notes:
#The target of this test case is to test if MLD enable can work well or not?

#precondition: all configurre should be default value except below mention.

# Steps:
# 1. factory default DUT
# 2. enable MLD mode and test the basic function, check the MLD worked well or not

variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set MultiMac16 "33 33 00 00 00 16"
set srcMac16 "00 C0 F2 00 00 16"

set ipv6srcip2 "FE80::2"
set ipv6dstip2 "FF02::16"

set group1 "FF1E::11"

puts "Test on DUT: $::dut"
#set DUT factory default
setToFactoryDefault $::dut

# connect ixia and take owner ship of ixia ports
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 \
             -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
#config_portprop -alias ixiap2 -autonego enable -phymode $phymode
#config_portprop -alias ixiap3 -autonego enable -phymode $phymode


####################################################################################################
set desc "MLD mode testing, check whether the basic enable can worked well with MLD disabled as default"

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1

send_traffic -alias ixiap1 -actiontype start

after 1000
set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

if {[llength $groups] == 0 } {
	passed "10.1.1" $desc
} else {
	failed "10.1.1" $desc
}

####################################################################################################
set desc "MLD mode testing, check whether the basic enable can worked well with MLD disabled as default"
ipmc::ipmcSnoopingEnable MLD True
ipmc::vlanSnoopingAdd MLD 1 True



config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1

send_traffic -alias ixiap1 -actiontype start

after 1000
set groups [ipmc::ipmcGroupGet]
puts "current MLD groups: $groups"

if {[llength $groups] == 1 } {
	passed "10.1.2" $desc
} else {
	failed "10.1.2" $desc
}