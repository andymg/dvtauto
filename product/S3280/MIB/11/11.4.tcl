#Filename: 11.4.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases is to check that the dut will  add the 
#correct ipv4 v2 multicast group address in the entry and transmit the multicast tranffic correct.

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
###########################config#########################################################
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

mvrenable true
set vid [expr round([expr 1+[expr 4093*[expr rand()]]])]
vlan_interface_setting add $vid
channel_setting $vid add 225.0.0.1 225.0.0.10 TNDVT
port_role $vid 80 60


# ######################################################################################
# #############################ipv4 v2 MVR Traffic Test#################################
mvrenable false
mvrenable true
set igmpv2_report {
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
eval $igmpv2_report
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 2

send_traffic -alias ixiap2 -actiontype start -time 3
config_frame -alias ixiap1 \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "01 00 5E 00 00 05" \
			 -vlanmode singlevlan \
			 -vlanid $vid \
			 -tpid 8100
config_stream -alias ixiap1 \
			  -ratemode fps \
			  -fpsrate 300

clear_stat -alias allport
start_capture -alias ixiap3
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 3
stop_capture -alias ixiap2
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "01 00 5E 00 00 05" -srcmac "00 00 00 00 00 01"]
set get_capture_p3 [check_capture -alias ixiap3 -dstmac "01 00 5e 00 00 05" -srcmac "00 00 00 00 00 01"]
if {$get_capture_p2==$ixiap1tx && $get_capture_p3 == 0 } {
	passed "base mvr traffic test" "works well"
} else {
	failed "base mvr traffic test" "failed"
}

