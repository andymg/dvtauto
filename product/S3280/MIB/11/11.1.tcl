#!/bin/tcl

#Filename: 11.1.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases  is to test the dynamic/compatible mode of mvr
 


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
#set dec "Test 10.1:check MVR VID functionality"
mvrenable true
set vid [expr round([expr 1+[expr 4093*[expr rand()]]])]
vlan_interface_setting add $vid
channel_setting $vid add 225.0.0.1 225.0.0.10 TNDVT
port_role $vid 80 60


#######################################################################################
#########################MVR-VLAN-Interface-Setting-Mode-Test##########################
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

eval $cmd_v2_report
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 2

clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start -time 3
stop_capture -alias ixiap1
get_stat -alias ixiap1 -rxframe ixiap1rx
get_stat -alias ixiap2 -txframe ixiap2tx
set get_capture [check_capture -alias ixiap1 -srcmac "00 00 00 00 00 02" -dstmac "01 00 5E 00 00 05" -vlanid $vid]
if {!$get_capture} {
	passed "compatible mode" "works well"
} else {
	failed "compatible mode" "failed"
}


parameter_mode $vid "dynamic"
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start -time 3
stop_capture -alias ixiap1
set get_capture [check_capture -alias ixiap1 -srcmac "00 00 00 00 00 02" -dstmac "01 00 5E 00 00 05" -vlanid $vid]
if {$get_capture} {
	passed "dynamic mode" "works well"
} else {
	failed "dynamic mode" "failed"
}




