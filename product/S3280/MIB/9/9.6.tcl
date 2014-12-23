#!/bin/tclsh
#Filename: 9.6.tcl
#History:
#        01/07/2014- Andy,Created
#
#Copyright(c): Transition Networks, Inc.2013
##########################################################################################
#  Test points:
#  1. IGMP host port age-out
#  2. IGMP specific query check
##########################################################################################

variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set group1 "228.0.0.1"
set group5 "228.0.0.5"

set dstMac1 "01 00 5E 00 00 01"
set dstMac2 "01 00 5E 00 00 02"
set dstMac5 "01 00 5E 00 00 05"
set srcMac1 "00 C0 00 00 00 01"
set srcMac2 "00 C0 00 00 00 02"

setToFactoryDefault $::dut
after 1000
# Enable IGMP snooping and add new IGMP vlan entries
ipmc::ipmcSnoopingEnable IGMP True
ipmc::vlanSnoopingAdd IGMP 1 True
ipmc::ipmcRVset IGMP 1 2
ipmc::ipmcQIset IGMP 1 20
ipmc::ipmcQRIset IGMP 1 100


connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1 \
             -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode

ipmc::ipmcRouterPortSet IGMP $::dutP2 True

##############################################################################################################
set desc "IGMP testing general member ship old time"

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $srcMac1 -dstmac $dstMac1 \
             -srcip 192.168.3.63 -dstip 225.0.0.1 -igmptype v2report -groupip $group1
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap1 -actiontype start
after 10
set time 0
while { [llength [ipmc::ipmcGroupGet]] > 0} {
	incr time
	after 1000
}
puts "After $time seconds the group $group1 is removed by IGMP"

if { $time >= 38 && $time <= 43} {
	passed "9.6.1" $desc
} else {
	failed "9.6.1" $desc
}

###############################################################################################################
set desc "IGMP testing specific query after the leave packet is received"
#send report packet to DUT port
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $srcMac1 -dstmac $dstMac1 \
             -srcip 192.168.3.63 -dstip 225.0.0.1 -igmptype v2report -groupip $group5
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap1 -actiontype start

after 2000
#send leave packt
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $srcMac1 -dstmac $dstMac2 \
             -srcip 192.168.3.63 -dstip 224.0.0.2 -igmptype leave -groupip $group5
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1

start_capture -alias ixiap1
send_traffic -alias ixiap1 -actiontype start
after 20000
stop_capture -alias ixiap1

set captured [check_capture -alias ixiap1 -dstmac $dstMac5]
puts "IGMP: $captured speicif query are received on host port"
if { $captured == 3} {
	passed "9.6.2" $desc
} else {
	failed "9.6.2" $desc
}

###############################################################################################################
set desc "IGMP testing specific query after the leave packet is received"
#send report packet to DUT port
ipmc::ipmcRVset IGMP 1 2
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $srcMac1 -dstmac $dstMac1 \
             -srcip 192.168.3.63 -dstip 225.0.0.1 -igmptype v2report -groupip $group5
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap1 -actiontype start

after 2000
#send leave packt
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $srcMac1 -dstmac $dstMac2 \
             -srcip 192.168.3.63 -dstip 224.0.0.2 -igmptype leave -groupip $group5
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1

start_capture -alias ixiap1
send_traffic -alias ixiap1 -actiontype start
after 20000
stop_capture -alias ixiap1

set captured [check_capture -alias ixiap1 -dstmac $dstMac5]
puts "IGMP: $captured speicif query are received on host port"

after 20000
ipmc::ipmcRVset IGMP 1 5
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $srcMac1 -dstmac $dstMac1 \
             -srcip 192.168.3.63 -dstip 225.0.0.1 -igmptype v2report -groupip $group5
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap1 -actiontype start

after 2000
#send leave packt
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $srcMac1 -dstmac $dstMac2 \
             -srcip 192.168.3.63 -dstip 224.0.0.2 -igmptype leave -groupip $group5
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1

start_capture -alias ixiap1
send_traffic -alias ixiap1 -actiontype start
after 20000
stop_capture -alias ixiap1

set captured1 [check_capture -alias ixiap1 -dstmac $dstMac5]
puts "IGMP: $captured1 speicif query are received on host port"
if { $captured == 3 && $captured1 == 5} {
	passed "9.6.3" $desc
} else {
	failed "9.6.3" $desc
}