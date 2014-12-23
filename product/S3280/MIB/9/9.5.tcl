#!/bin/tclsh
#Filename: 9.5.tcl
#History:
#        12/10/2013- Andy,Created
#
#Copyright(c): Transition Networks, Inc.2013
##########################################################################################
#  Test points:
#  1. IGMP v3 include / excluded test
#  2. Test multicast stream with srcip in include/excluded
##########################################################################################
variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set group1 "228.0.0.5"
set group2 "228.0.0.2"
set group3 "228.0.0.13"
set group4 "235.0.2.14"

set dstMac4 "01 00 5E 00 00 04"
set srcMac3 "00 C0 00 00 00 03"
set srcMac4 "00 C0 00 00 00 04"

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

ipmc::ipmcRouterPortSet IGMP $::dutP2 True
# Disable fast leave on dutP1
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 True

###############################################################################################################
set desc "multicast packets from router port to DUT"

clear_stat -alias allport
# send v3 report report packet on port 1
config_frame -alias ixiap2 -frametype ethernetii -vlanmode none\
            -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 \
             -srcip 192.168.1.1 -dstip $group2
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2
after 500

# capture packet on dutP2
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1

set captured [check_capture -alias ixiap1 -srcmac $ixiaMac3]
puts "got $captured packets"

if { $captured == 10 } {
	passed "9.5.1" $desc
} else {
	failed "9.5.1" $desc
}

###############################################################################################################
set desc "multicast packets from router port to DUT, the srcip is included"

clear_stat -alias allport
# send v3 report report packet on port 1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none \
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 \
             -srcip 192.168.3.63 -dstip 225.0.0.5 -igmptype v3report \
             -v3groupip1 $group1 -v3includeip1 [list 192.168.1.1]
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2
after 500

#send v3report packet to DUTP1
send_traffic -alias ixiap1 -actiontype start


config_frame -alias ixiap2 -frametype ethernetii -vlanmode none\
            -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 \
             -srcip 192.168.1.1 -dstip $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2
after 500

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured [check_capture -alias ixiap1 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $::ixiaMac3 -dstmac $::ixiaMac1]
puts "got $captured2 packets on port $::dutP3"

if { $captured == 10 && $captured2 == 0} {
	passed "9.5.2" $desc
} else {
	failed "9.5.2" $desc
}

###############################################################################################################
set desc "multicast packets from router port to DUT, the srcip is not in included"

clear_stat -alias allport
# send v3 report report packet on port 1

config_frame -alias ixiap2 -frametype ethernetii -vlanmode none\
            -srcmac $srcMac3 -dstmac $::ixiaMac1 \
             -srcip 192.168.1.3 -dstip $group1
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2
after 500

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured [check_capture -alias ixiap1 -srcmac $ -dstmac $::ixiaMac1]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $srcMac3 -dstmac $::ixiaMac1]
puts "got $captured2 packets on port $::dutP3"

if { $captured == 0 && $captured2 == 0} {
      passed "9.5.3" $desc
} else {
      failed "9.5.3" $desc
}
###############################################################################################################
set desc "multicast packets from router port to DUT, the srcip is excluded"

clear_stat -alias allport
# send v3 report report packet on port 1
# send v3 report report packet on port 1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $::ixiaMac4 -dstmac $::ixiaMac1 \
             -srcip 192.168.3.64 -dstip 225.0.0.5 -igmptype v3report \
             -v3groupip1 $group2 -v3excludeip1 [list 192.168.1.2]
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

send_traffic -alias ixiap1 -actiontype start


config_frame -alias ixiap2 -frametype ethernetii -vlanmode none\
            -srcmac $srcMac4 -dstmac $::ixiaMac2 \
             -srcip 192.168.1.2 -dstip $group2
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2
after 500

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured [check_capture -alias ixiap1 -srcmac $srcMac4 -dstmac $::ixiaMac2]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $srcMac4 -dstmac $::ixiaMac2]
puts "got $captured2 packets on port $::dutP3"

if { $captured == 0 && $captured2 == 0} {
      passed "9.5.4" $desc
} else {
      failed "9.5.4" $desc
}

###############################################################################################################
set desc "multicast packets from router port to DUT, the srcip is excluded ,the group is not exist"

clear_stat -alias allport
# send v3 report report packet on port 1
# send v3 report report packet on port 1


config_frame -alias ixiap2 -frametype ethernetii -vlanmode none\
            -srcmac $::ixiaMac3 -dstmac $::ixiaMac4 \
             -srcip 192.168.1.2 -dstip 238.0.0.4
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2
after 500

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured [check_capture -alias ixiap1 -srcmac $::ixiaMac3 -dstmac $::ixiaMac4]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $::ixiaMac3 -dstmac $::ixiaMac4]
puts "got $captured2 packets on port $::dutP3"

if { $captured == 10 && $captured2 == 10} {
      passed "9.5.5" $desc
} else {
      failed "9.5.5" $desc
}

###############################################################################################################
set desc "multicast packets from router port to DUT, the srcip is not configured,the group is not exist"

clear_stat -alias allport
# send v3 report report packet on port 1
# send v3 report report packet on port 1
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -framesize 120\
             -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 \
             -srcip 192.168.3.64 -dstip 225.0.0.6 -igmptype v3report \
             -v3groupip1 $group1 -v3excludeip1 [list 192.168.1.1 192.168.1.2]
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -bstperstrm 2

send_traffic -alias ixiap1 -actiontype start


config_frame -alias ixiap2 -frametype ethernetii -vlanmode none\
            -srcmac $::ixiaMac3 -dstmac $dstMac4 \
             -srcip 192.168.1.3 -dstip 238.0.0.4
config_stream -alias ixiap2 -sendmode stopstrm  -pktperbst 5 -bstperstrm 2
after 500

# capture packet on dutP2
start_capture -alias ixiap1
start_capture -alias ixiap3
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
stop_capture -alias ixiap3

set captured [check_capture -alias ixiap1 -srcmac $::ixiaMac3 -dstmac $dstMac4]
puts "got $captured packets on port $::dutP1"

set captured2 [check_capture -alias ixiap3 -srcmac $::ixiaMac3 -dstmac $dstMac4]
puts "got $captured2 packets on port $::dutP3"

if { $captured == 10 && $captured2 == 10} {
      passed "9.5.6" $desc
} else {
      failed "9.5.6" $desc
}