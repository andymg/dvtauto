#Filename: 11.9.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases is to verify the dut will not add igmpv3 multicast address which is 
#not in the configuration and to check the traffic for this multicast address.




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




# ########################################################################################
# ##########igmpv3:illeagal multicast address test########################################
mvrenable false
mvrenable true
after 1000
config_frame -alias ixiap2 \
			 -framesize 200 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 02" \
			 -dstmac "01 00 5E 00 00 0B" \
			 -ethernetname ip \
			 -igmptype v3report \
			 -v3groupip1 225.0.0.11 \
			 -v3includeip1 [list 1.1.1.1] \
			 -v3groupip2 225.0.0.12 \
			 -v3excludeip2 [list 1.1.1.1] \
			 -srcip 2.2.2.2 \
			 -dstip 225.0.0.11
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 2
send_traffic -alias ixiap2 -actiontype start -time 2
set group_entry [check_group]
array unset sfm_arr
array set sfm_arr {}
check_SFM sfm_arr
# parray sfm_arr
if {[llength [array names sfm_arr]]==0 && [llength $group_entry]==0} {
	passed "illeagal multicast address test" "passed"
} else {
	failed "illeagal multicast address test" "failed"
}
