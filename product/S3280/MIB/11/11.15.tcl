#!/bin/tcl

#Filename: 11.15.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes: the target of following test cases is check the statistics for :
#1: mld query transmitted #############################
#2: mldv1 report received #############################
#3: mldv1 leave received ##############################


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

set cmd_mldv1_report {
	config_frame -alias ixiap2 \
			 -framesize 200 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 02" \
			 -dstmac "33 33 00 00 00 05" \
			 -ethernetname ipv6 \
			 -mldv1 report \
			 -groupmldv1 ff01::5 \
			 -ipv6src fe80::2 \
			 -ipv6des ff01::5
}



#################################################################################
#########mvr statistics check mld query transmitted #############################
#########mvr statistics check mldv1 report received #############################
#########mvr statistics check mldv1 leave received ##############################
mvrenable false
mvrenable true 
clear_mvr_stat
clear_stat -alias allport
eval $cmd_mldv1_report
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 2

send_traffic -alias ixiap2 -actiontype start -time 2
array unset statis_entry
array set statis_entry {}
check_statis mldv1reportrx statis_entry
get_stat -alias ixiap2 -txframe ixiap2tx

if {$statis_entry($vid)==$ixiap2tx} {
	passed "mvr statistics check mldv1 report received" "passed"
} else {
	failed "mvr statistics check mldv1 report received" "failed"
}


config_frame -alias ixiap2 \
			 -frametype ethernetii \
			 -framesize 200 \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "33 33 00 00 00 05" \
			 -ethernetname ipv6 \
			 -mldv1 done \
			 -groupmldv1 ff01::5 \
			 -ipv6src fe80::1 \
			 -ipv6des ff01::5
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 1 -bstperstrm 1
send_traffic -alias ixiap2 -actiontype start
after 1000
array unset statis_entry
array set statis_entry {}
check_statis mldv1leaverx statis_entry
if {$statis_entry($vid)==1} {
	passed "mvr staitsitcs check mldv1 leave received" "passed"
} else {
	failed "mvr staitsitcs check mldv1 leave received" "failed"
}
after 16000
array unset statis_entry
array set statis_entry {}
check_statis mldquerytx statis_entry
if {$statis_entry($vid)==3} {
	passed "mvr statistics check mld query transmitted" "passed"
} else {
	failed "mvr statistics check mld query transmitted" "failed"
} 