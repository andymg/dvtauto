#!/bin/tcl

#Filename: 11.21.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases  is to test the Immediate Leave of MVR .
 

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



set cmd_v2_report {
	config_frame -alias ixiap2 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 02" \
			 -dstmac "01 00 5e 00 00 05" \
			 -ethernetname ip \
			 -igmptype v2report \
			 -groupip 225.0.0.5 \
			 -srcip 2.2.2.2 \
			 -dstip 225.0.0.5
			}

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


# ######################################################################################
# ########################mvr immediate leave test######################################
parameter_llqi $vid 50
immediate_leave 2 true
eval $cmd_v2_report
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 1
clear_stat -alias allport
start_capture -alias ixiap2
eval $cmd_v2_leave
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 1
after 3000
stop_capture -alias ixiap2
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "01 00 5e 00 00 05" -srcmac "00 00 00 00 00 01"]
set group_entry [check_group]
if {$get_capture_p2==0 && [llength $group_entry]==0} {
	passed "mvr immediate leave test" "passed"
} else {
	failed "mvr immediate leave test" "failed"
}

immediate_leave 2 false

