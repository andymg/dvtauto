#!/bin/tcl

#Filename: 1.1.tcl
#History:
#        12/10/2013- Andy,Created
#
#Copyright(c): Transition Networks, Inc.2013
##########################################################################################
#  Test points:
#  1. check v1/v2 report packet received on DUT
#  2. fast leave function
#  3. Multicast packets testing received on member port
##########################################################################################

variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set MultiMac16 "01 00 5E 00 00 12"
set srcMac16 "00 C0 F2 00 00 02"
setToFactoryDefault $::dut

ipmc::ipmcSnoopingEnable IGMP True
ipmc::vlanSnoopingAdd IGMP 1 True

####################################################################################################
set desc "IGMP test report packet , the new group will be added in Group list"
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode
config_portprop -alias ixiap3 -autonego enable -phymode $phymode

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 \
             -igmptype v2report -groupip 228.0.0.9
#config_portprop -alias ixiap3 -autonego enable -phymode copper
	
#config_frame -alias ixiap2 -srcmac $::ixiaMac2 -dstmac $::ixiaMac3 -framesize $::ixiaFrameSize
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
#config_frame -alias ixiap1 -vlanmode none -srcmac "33 00 00 00 05 08" -dstmac $::ixiaMac1 -framesize $::ixiaFrameSize
send_traffic -alias ixiap1 -actiontype start
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 \
             -igmptype v2report -groupip 228.0.0.15
send_traffic -alias ixiap1 -actiontype start
after 1000
set group1 [ipmc::ipmcGroupGet]
puts "current groups are: $group1"

if {[llength $group1] == 2} {
	passed "IGMP 9.1.1" $desc
} else {
	failed "IGMP 9.1.1" $desc
}

########################################################################################################
set desc "9.2: v2report IGMP four group added successed"
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 \
             -igmptype v2report -groupip 228.0.0.16
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 \
             -igmptype v2report -groupip 228.0.0.18
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start
set groups [ipmc::ipmcGroupGet]

puts "current groups are: $groups"

if {[llength $groups] == 4} {
	passed "IGMP 9.1.2" $desc
} else {
	set len [llength $groups]
	failed "IGMP 9.1.2" $desc
}

##########################################################################################################
set desc "9.3: Enable IGMP fast leave and reveive leave request"
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 True
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
            -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 \
            -igmptype leave -groupip 228.0.0.9
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start
set groups [ipmc::ipmcGroupGet]
puts "current groups are: $groups"

if {[llength $groups] == 3} {
	passed "IGMP 9.1.3" $desc
} else {
	failed "IGMP 9.1.3" $desc
}

########################################################################################################
set desc "9.1.4 Diable IGMP fast leave and receive leave request"
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 False
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 \
             -igmptype leave -groupip 228.0.0.15
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
send_traffic -alias ixiap1 -actiontype start
set groups1 [ipmc::ipmcGroupGet]
after 5000

set groups2 [ipmc::ipmcGroupGet]
puts "current groups are: $groups2"
if {[llength $groups2] == 2 && [llength $groups1] == 3} {
	passed "IGMP 9.1.4" $desc
} else {
	failed "IGMP 9.1.4" $desc
}


########################################################################################################
set desc "Testing multicast packet (grouped packets)received on port1 and port 3"
#set dutP2 to router port
ipmc::ipmcRouterPortSet IGMP $::dutP2 True

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $srcMac16 -dstmac $MultiMac16 -srcip 192.168.3.12 -dstip 228.0.0.16

config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set groups2 [ipmc::ipmcGroupGet]
puts "current groups are: $groups2"

set captured [check_capture -alias ixiap1 -srcmac $srcMac16 -dstmac $MultiMac16]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac16]
puts "got $captured2 packets on port $::dutP3"


if { $captured== 10 && $captured2 == 0 } {
	passed "IGMP 9.1.5" $desc
} else {
	failed "IGMP 9.1.5" $desc
}

########################################################################################################
set desc "Testing multicast packet (no grouped) received on port1 and port 3"
#set dutP2 to router port
ipmc::ipmcRouterPortSet IGMP $::dutP2 True
set MultiMac8 "01 00 5E 00 00 08"
set srcMac8 "00 C0 F2 00 00 08"

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $srcMac8 -dstmac $MultiMac8 -srcip 192.168.3.12 -dstip 228.0.0.8

config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set groups2 [ipmc::ipmcGroupGet]
puts "current groups are: $groups2"

set captured [check_capture -alias ixiap1 -srcmac $srcMac8 -dstmac $MultiMac8]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $srcMac8 -dstmac $MultiMac8]
puts "got $captured2 packets on port $::dutP3"


if { $captured== 10 && $captured2 == 10 } {
	passed "IGMP 9.1.6" $desc
} else {
	failed "IGMP 9.1.6" $desc
}
########################################################################################################
set desc "Testing multicast packet received on port1 and port 3"
#set dutP2 to router port
ipmc::ipmcRouterPortSet IGMP $::dutP2 True
set MultiMac8 "01 00 5E 00 00 08"
set srcMac8 "00 C0 F2 00 00 08"

config_frame -alias ixiap3 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $srcMac8 -dstmac $MultiMac8 -srcip 192.168.3.12 -dstip 228.0.0.8 \
             -igmptype v2report -groupip 228.0.0.8
config_stream -alias ixiap3 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
# add group 228.0.0.8 to groups
send_traffic -alias ixiap3 -actiontype start

# sending testing multicaset packets
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $srcMac8 -dstmac $MultiMac8 -srcip 192.168.3.12 -dstip 228.0.0.8

config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set groups2 [ipmc::ipmcGroupGet]
puts "current groups are: $groups2"

set captured [check_capture -alias ixiap1 -srcmac $srcMac8 -dstmac $MultiMac8]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $srcMac8 -dstmac $MultiMac8]
puts "got $captured2 packets on port $::dutP3"


if { $captured== 0 && $captured2 == 10 } {
	passed "IGMP 9.1.7" $desc
} else {
	failed "IGMP 9.1.7" $desc
}