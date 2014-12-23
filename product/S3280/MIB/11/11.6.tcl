#Filename: 11.6.tcl
#History:
#        11/20/2013- Jerry,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases is to check the igmpv3 multicast address 
#in include and exclude mode, and transmit traffic to verify the two mode.


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



########################################################################################
####################ipv4 v3  mvr traffic test###########################################
mvrenable false
mvrenable true
after 1000
set cmd_v3_report {
	config_frame -alias ixiap2 \
			 -framesize 200 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 02" \
			 -dstmac "01 00 5E 00 00 05" \
			 -ethernetname ip \
			 -igmptype v3report \
			 -v3groupip1 225.0.0.5 \
			 -v3includeip1 [list 1.1.1.1] \
			 -v3groupip2 225.0.0.8 \
			 -v3excludeip2 [list 1.1.1.1] \
			 -srcip 2.2.2.2 \
			 -dstip 225.0.0.5
}
eval $cmd_v3_report
config_stream -alias ixiap2 \
			  -ratemode fps \
			  -fpsrate 2

send_traffic -alias ixiap2 -actiontype start -time 3
set group_entry [check_group]
set mvrchannel_check 0
set mvrsfm_check 0
set check_entry_1 0
if {[lindex $group_entry 0]==[lindex $group_entry 3] &&[lindex $group_entry 0]==$vid} {
	if {[lindex $group_entry 1]=="225.0.0.5" && [lindex $group_entry 4]=="225.0.0.8"} {
		if {[lindex $group_entry 2]==2 && [lindex $group_entry 5]==2} { 
				set mvrchannel_check 1
			} else {
				puts "the port in MVR Channel group is wrong!"
			}
		} else {
			puts "the multicast groupip in MVR Channel group is wrong!"
		}
	
} else {
	puts "the vlanid in MVR Channel group is wrong!"
}


array unset sfm_arr
array set sfm_arr {}
check_SFM sfm_arr
if {[llength [array names sfm_arr]]==0} {
	set mvrsfm_check 0
} else {
	if {[lindex $sfm_arr(1) 0]==[lindex $sfm_arr(2) 0] && [lindex $sfm_arr(1) 0]==$vid} {
		if {[lindex $sfm_arr(1) 1]=="225.0.0.5" && [lindex $sfm_arr(2) 1]=="225.0.0.8"} {
			if {[lindex $sfm_arr(1) 2]==2 && [lindex $sfm_arr(2) 2]==2} {
				if {[lindex $sfm_arr(1) 3]=="include" && [lindex $sfm_arr(2) 3]=="exclude"} {
					if {[lindex $sfm_arr(1) 4]== "1.1.1.1" && [lindex $sfm_arr(2) 4]=="1.1.1.1"} {
						puts [lindex $sfm_arr(1) 4]
						puts [lindex $sfm_arr(2) 4]
						if {[lindex $sfm_arr(1) 5]=="allow" && [lindex $sfm_arr(2) 5]=="deny"} {
							set mvrsfm_check 1
							} else {
								puts "the type in MVR SFM INFO is wrong!"
							}
						
						} else {
							puts "the source address in MVR SFM INFO is wrong!"
						}
					} else {
						puts "the mode in MVR SFM INFO is wrong!"
					} 
				} else {
					puts "the port in MVR SFM INFO is wrong!"
				}
			} else {
				puts "the groupip in MVR SFM INFO is wrong!"
			}
	} else {
		puts "the vlanid in MVR SFM INFO is wrong!"
	}
}



config_frame -alias ixiap1 \
			 -framesize 100 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "01 00 5E 00 00 05" \
			 -ethernetname ip \
			 -vlanmode singlevlan \
			 -vlanid $vid \
			 -tpid 8100 \
			 -srcip 1.1.1.1 \
			 -dstip 225.0.0.5
config_stream -alias ixiap1 \
			  -ratemode fps \
			  -fpsrate 100

clear_stat -alias allport
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "01 00 5E 00 00 05" -srcmac "00 00 00 00 00 01"]
set get_capture_p3 [check_capture -alias ixiap3 -dstmac "01 00 5E 00 00 05" -srcmac "00 00 00 00 00 01"]
if {$get_capture_p2==$ixiap1tx && $get_capture_p3==0} {
	set check_entry_1 1
} else {
	puts "igmpv3 include sourceip list test failed"
}

config_frame -alias ixiap1 \
			 -framesize 100 \
			 -frametype ethernetii \
			 -srcmac "00 00 00 00 00 01" \
			 -dstmac "01 00 5e 00 00 08" \
			 -ethernetname ip \
			 -vlanmode singlevlan \
			 -vlanid $vid \
			 -tpid 8100 \
			 -srcip 1.1.1.1 \
			 -dstip 225.0.0.8
config_stream -alias ixiap1 \
			  -ratemode fps \
			  -fpsrate 100

clear_stat -alias allport
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
set get_capture_p2 [check_capture -alias ixiap2 -dstmac "01 00 5E 00 00 08" -srcmac "00 00 00 00 00 01"]
set get_capture_p3 [check_capture -alias ixiap3 -dstmac "01 00 5E 00 00 08" -srcmac "00 00 00 00 00 01"]

if {$get_capture_p2==$get_capture_p3 && $get_capture_p2==0} {
	if {$check_entry_1==1 && $mvrchannel_check==1 && $mvrsfm_check==1} {
		passed "igmpv3 include and exclude mode test" "passed"
	} else {
		failed "igmpv3 include and exclude mode test" "failed"
	}
} else {
	failed "igmpv3 include and exclude mode test" "failed"
}

