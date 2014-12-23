#!/bin/tcl

#Filename: 11.22.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases is MLDV2 Report and Multicast Forwarding Test  .
 

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
set ipv6_include [ipv6_normalize fe80::2c0:f2ff:fe42:2408 1]


set dut_mac [get_dut_mac]
########################################################################################

mvrenable true
set vid [expr round([expr 1+[expr 4093*[expr rand()]]])]
vlan_interface_setting add $vid
channel_setting $vid add 225.0.0.1 225.0.0.10 TNDVT
channel_setting $vid add ff01::1 ff02::1:ffa8:1 TNDVT2
port_role $vid 80 60



config_frame -alias ixiap2 -import mldv2-report.enc
config_stream -alias ixiap2 -ratemode fps -fpsrate 2
send_traffic -alias ixiap2 -actiontype start -time 3

set group_entry [check_group]
if {[llength $group_entry]==3 && [lindex $group_entry 0]==$vid} {
	if {[lindex $group_entry 1]==$ipv6_add && [lindex $group_entry 2]==2} {
		array set sfm_arr {}
		check_SFM sfm_arr

		if {[array name sfm_arr]==[list 1] && [lindex $sfm_arr(1) 0]==$vid} {
			if {[lindex $sfm_arr(1) 1]==$ipv6_add} {
				set monitor_check true
				} else {
					failed "MVR SFM INFO Test" "failed1"
				}

			} else {
				failed "MVR SFM INFO Test" "failed2"
			}

	} else {
		failed "MVR Channel Group for MLDV2 Test" "failed" 
	}
} else {
	failed "MVR Channel Group for MLDV2 Test" "failed" 
}



config_frame -alias ixiap1 \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "33 33 FF A8 00 01" \
			 -vlanmode singlevlan \
			 -vlanid $vid \
			 -tpid 8100
config_stream -alias ixiap1 \
			  -ratemode fps \
			  -fpsrate 300
clear_stat -alias allport
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 3
stop_capture -alias ixiap2 
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "33 33 FF A8 00 01" -srcmac "00 00 00 00 00 01"]
set get_capture_p3 [check_capture -alias ixiap3 -dstmac "33 33 FF A8 00 01" -srcmac "00 00 00 00 00 01"]

if {$get_capture_p2==$ixiap1tx && $get_capture_p3 == 0 && $monitor_check} {
 	passed "mldv2 traffic test" "works well"
 } else {
 	failed "mldv2 traffic test" "failed"
 }
