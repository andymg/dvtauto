#!/bin/tcl

#Filename: 11.20.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases  is to test the Last Membership Query Interval  of mvr.
 

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
# ########################################################################################

mvrenable true
set vid [expr round([expr 1+[expr 4093*[expr rand()]]])]
vlan_interface_setting add $vid
channel_setting $vid add 225.0.0.1 225.0.0.10 TNDVT
port_role $vid 80 60



# # #####################################################################################
# # ############################MVR-VLAN-Interface-Setting-LLQI-Test#####################
send_traffic -alias ixiap2 -actiontype start -time 2
parameter_llqi $vid 80
set cmd_v2_leave {
config_frame -alias ixiap2 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 02" \
			 -dstmac "01 00 5e 00 00 02" \
			 -ethernetname ip \
			 -igmptype leave \
			 -groupip 225.0.0.5 \
			 -srcip 2.2.2.2 \
			 -dstip 224.0.0.2
			}
eval $cmd_v2_leave
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 1


clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap2 -actiontype start -time 1
after 30000
stop_capture -alias ixiap2
set get_capture_llqi [check_capture -alias ixiap2 -srcmac $dut_mac -dstmac "01 00 5E 00 00 05"]
set timestamp_list [return_segment -alias ixiap2 -return_type timestamp]
for {set i 1} {$i < [expr $get_capture_llqi-1]} {incr i} {
	set diff_timestamp [expr [lindex $timestamp_list [expr $i+1]]-[lindex $timestamp_list $i]]

	if {[expr abs([expr $diff_timestamp - 8000000000])] < 1000000000} {
		if {$i==$get_capture_llqi-2} {
			passed "LLQI test " "passed"
		}
		
	} else {
		failed "LLQI test" "failed"
		break
	}
}
