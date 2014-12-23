#!/bin/tcl

#Filename: 11.16.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes: the target of following test cases is check the statistics for igmpv1 report packets



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

set igmpv1_report {
config_frame -alias ixiap2 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 02" \
			 -dstmac "01 00 5E 00 00 05" \
			 -ethernetname ip \
			 -igmptype v1report \
			 -groupip 225.0.0.05 \
			 -srcip 2.2.2.2 \
			 -dstip 225.0.0.5
			}

#################################################################################
##############mvr statistics check igmpv1 join received##########################
mvrenable false
mvrenable true
clear_mvr_stat
eval $igmpv1_report
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 2
clear_stat -alias allport
send_traffic -alias ixiap2 -actiontype start -time 2
array unset statis_entry
array set statis_entry {}
check_statis igmpv1joinrx statis_entry
get_stat -alias ixiap2 -txframe ixiap2tx
if {$statis_entry($vid)==$ixiap2tx} {
	passed "mvr statistics check igmpv1 join received" "passed"
} else {
	failed "mvr statistics check igmpv1 join received" "failed"
}
