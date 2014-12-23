#!/bin/tcl

#Filename: 11.12.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes: the target of following test cases is check the statistics for igmp query packets received.


variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

set self [file normalize [info script]]
set path [file dirname [file dirname $self]] 
source $path/base/mvr.tcl
namespace import mvr::*
setToFactoryDefault $::dut

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 -alias allport -loginname mvr_auto

config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode
config_portprop -alias ixiap3 -autonego enable -phymode $phymode


set dut_mac [get_dut_mac]

# #################################################################################

mvrenable true
set vid [expr round([expr 1+[expr 4093*[expr rand()]]])]
vlan_interface_setting add $vid
channel_setting $vid add 225.0.0.1 225.0.0.10 TNDVT
channel_setting $vid add ff01::1 ff01::a TNDVT
port_role $vid 80 60
# ##################################################################################
# set igmpv1_report {
# config_frame -alias ixiap2 \
# 			 -frametype ethernetii \
# 			 -srcmac "00 00 00 00 00 02" \
# 			 -dstmac "01 00 5E 00 00 05" \
# 			 -ethernetname ip \
# 			 -igmptype v1report \
# 			 -groupip 225.0.0.05 \
# 			 -srcip 2.2.2.2 \
# 			 -dstip 225.0.0.5
# 			}
# set igmpv2_report {
# config_frame -alias ixiap2 \
# 			 -frametype ethernetii \
# 			 -srcmac "00 00 00 00 00 02" \
# 			 -dstmac "01 00 5e 00 00 05" \
# 			 -ethernetname ip \
# 			 -igmptype v2report \
# 			 -groupip 225.0.0.5 \
# 			 -srcip 2.2.2.2 \
# 			 -dstip 225.0.0.5
# }
# set cmd_v2_report {
# 	config_frame -alias ixiap2 \
# 			 -frametype ethernetii \
# 			 -srcmac "00 00 00 00 00 02" \
# 			 -dstmac "01 00 5e 00 00 05" \
# 			 -ethernetname ip \
# 			 -igmptype v2report \
# 			 -groupip 225.0.0.5 \
# 			 -srcip 2.2.2.2 \
# 			 -dstip 225.0.0.5
# 			}
# set cmd_v3_report {
# 	config_frame -alias ixiap2 \
# 			 -framesize 200 \
# 			 -frametype ethernetii \
# 			 -srcmac "00 00 00 00 00 02" \
# 			 -dstmac "01 00 5E 00 00 05" \
# 			 -ethernetname ip \
# 			 -igmptype v3report \
# 			 -v3groupip1 225.0.0.5 \
# 			 -v3includeip1 [list 1.1.1.1] \
# 			 -v3groupip2 225.0.0.8 \
# 			 -v3excludeip2 [list 1.1.1.1] \
# 			 -srcip 2.2.2.2 \
# 			 -dstip 225.0.0.5
# }
# set cmd_mldv1_report {
# 	config_frame -alias ixiap2 \
# 			 -framesize 200 \
# 			 -frametype ethernetii \
# 			 -srcmac "00 00 00 00 00 02" \
# 			 -dstmac "33 33 00 00 00 05" \
# 			 -ethernetname ipv6 \
# 			 -mldv1 report \
# 			 -groupmldv1 ff01::5 \
# 			 -ipv6src fe80::2 \
# 			 -ipv6des ff01::5
# }
# set cmd_v2_leave {
# config_frame -alias ixiap2 \
# 			 -frametype ethernetii \
# 			 -srcmac "00 00 00 00 00 02" \
# 			 -dstmac "01 00 5e 00 00 02" \
# 			 -ethernetname ip \
# 			 -igmptype leave \
# 			 -groupip 225.0.0.5 \
# 			 -srcip 2.2.2.2 \
# 			 -dstip 224.0.0.2
# 			}
# ##############mvr statistics check:igmp query received############################

clear_mvr_stat
array unset statis_entry
array set statis_entry {}
check_statis mldqueryrx statis_entry
config_frame -alias ixiap1 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "01 00 5e 00 00 01" \
			 -ethernetname ip \
			 -vlanmode singlevlan \
			 -vlanid $vid \
			 -igmptype query \
			 -groupip 0.0.0.0 \
			 -srcip 1.1.1.1 \
			 -dstip 224.0.0.1
config_stream -alias ixiap1 \
			  -ratemode fps \
			  -fpsrate 2

clear_stat -alias allport
send_traffic -alias ixiap1 -actiontype start -time 3
after 2000
get_stat -alias ixiap1 -txframe ixiap1tx
array unset statis_entry
array set statis_entry {}
check_statis igmpqueryrx statis_entry
if {$statis_entry($vid)==$ixiap1tx} {
	passed "igmp query received staitsitcs" "passed"
} else {
	failed "igmp query received staitsitcs" "failed"
}



