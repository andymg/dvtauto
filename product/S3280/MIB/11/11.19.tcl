#!/bin/tcl

#Filename: 11.19.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases  is to test the priority of mvr.
 

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


# #####################################################################################
# ############################MVR-VLAN-Interface-Setting-Priority-Test#################
parameter_tagging $vid tagged
set priority [expr round ([expr [expr rand()] * 7])] 
parameter_priority $vid $priority
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start -time 3
stop_capture -alias ixiap1
set get_capture_priority [check_capture -alias ixiap1 -srcmac "00 00 00 00 00 02" -dstmac "01 00 5E 00 00 05" -tpid "8100" -priority $priority]
if {$get_capture_priority} {
	passed "priority test" "works well"
} else {
	failed "priority test" "failed"
	}
