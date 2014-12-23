#!/bin/tcl

#Filename: 11.23.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases is MLDV2 Include Source Ipv6 address Test .
 

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
channel_setting $vid add ff01::1 ff02::1:ffa8:1 TNDVT
port_role $vid 80 60

config_frame -alias ixiap2 -import mldv2-report.enc
config_stream -alias ixiap2 -ratemode fps -fpsrate 2
send_traffic -alias ixiap2 -actiontype start -time 3

set ipv6_src [ipv6_normalize fe80::2c0:f2ff:fe42:2408 1]
array set sfm_arr {}
check_SFM sfm_arr
if {[lindex $sfm_arr(1) 3]=="include" && [lindex $sfm_arr(1) 4]==$ipv6_include} {
	set monitor_check true
} else {
	failed "MVR SFM INFO for MLDV2 Include Mode Test" "failed"
}



config_frame -alias ixiap1 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "33 33 FF A8 00 01" \
			 -ethernetname ipv6 \
			 -ipv6src fe80::2c0:f2ff:fe42:2408 \
			 -ipv6des ff02::1:ffa8:1 \
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
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "33 33 FF A8 00 01" -srcmac "00 00 00 00 00 01"]
set get_capture_p3 [check_capture -alias ixiap3 -dstmac "33 33 FF A8 00 01" -srcmac "00 00 00 00 00 01"]

if {$get_capture_p2==$ixiap1tx && $get_capture_p3 == 0 } {
 	set mldv2_include_correct true
 } else {
 	set mldv2_include_correct false
 }




config_frame -alias ixiap1 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "33 33 FF A8 00 01" \
			 -ethernetname ipv6 \
			 -ipv6src fe80::2c0:f2ff:fe42:2407 \
			 -ipv6des ff02::1:ffa8:1 \
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
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "33 33 FF A8 00 01" -srcmac "00 00 00 00 00 01"]
set get_capture_p3 [check_capture -alias ixiap3 -dstmac "33 33 FF A8 00 01" -srcmac "00 00 00 00 00 01"]
puts $get_capture_p2
puts $get_capture_p3
puts $ixiap1tx
if {$get_capture_p2==0 && $get_capture_p3 == 0 && $monitor_check && $mldv2_include_correct} {
 	passed "MLDV2 Include Mode Test" "pass"
 } else {
 	failed "MLDV2 Include Mode Test" "fail"
 }

