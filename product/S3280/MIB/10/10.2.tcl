#!/usr/bin/env tclsh

#Filename: 10.2.tcl
#History:
#        01/14/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014


#Notes:
#The target of this test case is to test IPMCv6 flooding function

#precondition: all configurre should be default value except below mention.

# Steps:
# 1. factory default DUT
# 2. as default config of IPMCv6 flooding check the multicast flooding
# 3. Disable IPMCv6 flooding check the multicast flooding
# 4. add new group and check the ipv6 multicast stream forwarding way

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
set desc "MLD ICMPv6 flooding testing, check the default ICMPv6 flooding function is enable when mld is disabled"

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac11 -ipv6src $ipv6srcip2 -ipv6des $group1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

# capture packets on port 2 and port 3
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set getCaptured2 [check_capture -alias ixiap2 -srcmac $srcMac16 -dstmac $MultiMac11]
set getCaptured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac11]

puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

if {$testPackets == $getCaptured2 && $testPackets == $getCaptured3} {
	passed "10.2.1" $desc
} else {
	failed "10.2.1" $desc
}

####################################################################################################
set desc "MLD ICMPv6 flooding testing, check the default ICMPv6 flooding function is enable when mld is enable"

# enable MLD mode
ipmc::ipmcSnoopingEnable MLD True

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac11 -ipv6src $ipv6srcip2 -ipv6des $group1 -dbgprt 1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

# capture packets on port 2 and port 3
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set getCaptured2 [check_capture -alias ixiap2 -srcmac $srcMac16 -dstmac $MultiMac11]
set getCaptured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac11]

puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

if {$testPackets == $getCaptured2 && $testPackets == $getCaptured3} {
	passed "10.2.2" $desc
} else {
	failed "10.2.2" $desc
}

####################################################################################################
set desc "MLD ICMPv6 flooding testing, check the default ICMPv6 flooding function is disabled when mld is enable"

# enable MLD mode
ipmc::ipmcSnoopingEnable MLD True
ipmc::ipmcFloodingEnable MLD False
ipmc::vlanSnoopingAdd MLD 1 True

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac11 -ipv6src $ipv6srcip2 -ipv6des $group1 -dbgprt 1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

# capture packets on port 2 and port 3
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set getCaptured2 [check_capture -alias ixiap2 -srcmac $srcMac16 -dstmac $MultiMac11]
set getCaptured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac11]

puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

if {0 == $getCaptured2 && 0 == $getCaptured3} {
	passed "10.2.3" $desc
} else {
	failed "10.2.3" $desc
}

###################################################################################################
set desc "MLD ICMPv6 flooding testing, check the default ICMPv6 flooding function is disabled when mld is enable"

# enable MLD mode
ipmc::ipmcSnoopingEnable MLD True
ipmc::ipmcFloodingEnable MLD True

# mldv1 report on port 2
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start
after 1000
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac11 -ipv6src $ipv6srcip2 -ipv6des $group1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

# capture packets on port 2 and port 3
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

set getCaptured2 [check_capture -alias ixiap2 -srcmac $srcMac16 -dstmac $MultiMac11]
set getCaptured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac11]

puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

if {$testPackets == $getCaptured2 && 0 == $getCaptured3} {
	passed "10.2.4" $desc
} else {
	failed "10.2.4" $desc
}

####################################################################################################
# Steps:
# 1. enable MLD mode 
# 2. enable Flooding mode
# 3. send mldv1 report packet on p2 with group1
# 4. send ipv6 multicast packets with dest group1 to p1
# 5. check reveived packets on p2 and p3
set desc "MLD ICMPv6 flooding testing, check the default ICMPv6 flooding function is enable when mld is enable"


# enable MLD mode
ipmc::ipmcSnoopingEnable MLD True
ipmc::ipmcFloodingEnable MLD True

# mldv1 report on port 2
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start
after 1000
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac12 -ipv6src $ipv6srcip2 -ipv6des $group2 -dbgprt 1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

# capture packets on port 2 and port 3
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

set getCaptured2 [check_capture -alias ixiap2 -srcmac $srcMac16 -dstmac $MultiMac12]
set getCaptured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac12]

puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

if {$testPackets == $getCaptured2 && $testPackets == $getCaptured3} {
	passed "10.2.5" $desc
} else {
	failed "10.2.5" $desc
}

####################################################################################################
set desc "MLD ICMPv6 flooding testing, check the default ICMPv6 flooding function is disabled when mld is enable"

# enable MLD mode
ipmc::ipmcSnoopingEnable MLD True
ipmc::ipmcFloodingEnable MLD False

# mldv1 report on port 2
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none -framesize 120 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac16 -ipv6src $ipv6srcip2 -ipv6des $ipv6dstip2 \
             -mldv1 report -groupmldv1 $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start
after 1000
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 200 -ethernetname ipv6\
             -srcmac $srcMac16 -dstmac $MultiMac12 -ipv6src $ipv6srcip2 -ipv6des $group2 -dbgprt 1

config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm $testPackets

# capture packets on port 2 and port 3
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
stop_capture -alias ixiap3

set groups [ipmc::ipmcGroupGet]
puts "current IPMC groups: $groups"

set getCaptured2 [check_capture -alias ixiap2 -srcmac $srcMac16 -dstmac $MultiMac12]
set getCaptured3 [check_capture -alias ixiap3 -srcmac $srcMac16 -dstmac $MultiMac12]

puts "$getCaptured2 packets received on p2"
puts "$getCaptured3 packets received on p3"

if {0 == $getCaptured2 && 0 == $getCaptured3} {
	passed "10.2.6" $desc
} else {
	failed "10.2.6" $desc
}