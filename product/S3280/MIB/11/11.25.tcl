#!/bin/tcl

#Filename: 11.25.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases is MLDV2 illeagal Multicast Group Test .
 

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


set ipv6_add [ipv6_normalize ff02::1:ffa8:1 1 ]
set ipv6_exclude [ipv6_normalize 2011::9 1]


set dut_mac [get_dut_mac]
########################################################################################

mvrenable true
set vid [expr round([expr 1+[expr 4093*[expr rand()]]])]
vlan_interface_setting add $vid
channel_setting $vid add ff01::1 ff1e::8 TNDVT
port_role $vid 80 60

config_frame -alias ixiap2 -import mldv2-exclude.enc
config_stream -alias ixiap2 -ratemode fps -fpsrate 2
send_traffic -alias ixiap2 -actiontype start -time 3

array set sfm_arr {}
check_SFM sfm_arr
if {[array size sfm_arr]==0} {
	if {[llength [check_group]]==0} {
		set entry_check true
	} else {
		failed "MVR MLDV2 Channel info Check Test" "fail"
		exit 0
	}
	} else {
		failed "MVR MLDV2 SFM Check Test" "fail"
		exit 0
	}


config_frame -alias ixiap1 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "33 33 00 00 00 09" \
			 -ethernetname ipv6 \
			 -ipv6src "2011::9" \
			 -ipv6des "ff1e::9" \
			 -vlanmode singlevlan \
			 -vlanid $vid \
			 -tpid 8100
config_stream -alias ixiap1 \
			  -ratemode fps \
			  -fpsrate 300
clear_stat -alias allport
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "33 33 00 00 00 09" -srcmac "00 00 00 00 00 01"]
set get_capture_p3 [check_capture -alias ixiap3 -dstmac "33 33 00 00 00 09" -srcmac "00 00 00 00 00 01"]
if {$get_capture_p2==$get_capture_p3 && $get_capture_p2==$ixiap1tx && $entry_check} {
		passed "MLDV2 illeagal Multicast Group Test" "pass"
	} else {
		failed "MLDV2 illeagal Multicast Group Test" "fail"
		
	}