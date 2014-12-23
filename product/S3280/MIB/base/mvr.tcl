#!/bin/tcl
namespace eval mvroid {
set tnMVRMode(oid) 1.3.6.1.4.1.868.2.5.50.2.1.1.1.1
set tnMVRMode(type) TruthValue 
set tnMVRMode(access) read-write
set tnMVRStatisticsClear(oid) 1.3.6.1.4.1.868.2.5.50.2.1.1.1.2
set tnMVRStatisticsClear(type) TruthValue 
set tnMVRStatisticsClear(access) read-write
set tnMVRName(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.2
set tnMVRName(type) DisplayString 
set tnMVRName(access) read-write
set tnMVRInterfaceMode(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.3
set tnMVRInterfaceMode(type) INTEGER 
set tnMVRInterfaceMode(access) read-write
set tnMVRInterfaceTagging(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.4
set tnMVRInterfaceTagging(type) INTEGER 
set tnMVRInterfaceTagging(access) read-write
set tnMVRInterfacePriority(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.5
set tnMVRInterfacePriority(type) INTEGER 
set tnMVRInterfacePriority(access) read-write
set tnMVRInterfaceLLQI(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.6
set tnMVRInterfaceLLQI(type) INTEGER 
set tnMVRInterfaceLLQI(access) read-write
set tnMVRInactivePortList(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.7
set tnMVRInactivePortList(type) PortList 
set tnMVRInactivePortList(access) read-write
set tnMVRSourcePortList(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.8
set tnMVRSourcePortList(type) PortList 
set tnMVRSourcePortList(access) read-write
set tnMVRReceiverPortList(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.9
set tnMVRReceiverPortList(type) PortList 
set tnMVRReceiverPortList(access) read-write
set tnMVRInterfaceRowStatus(oid) 1.3.6.1.4.1.868.2.5.50.2.1.2.1.10
set tnMVRInterfaceRowStatus(type) RowStatus 
set tnMVRInterfaceRowStatus(access) read-create
set tnMVRImmediateLeaveEnabled(oid) 1.3.6.1.4.1.868.2.5.50.2.1.3.1.1
set tnMVRImmediateLeaveEnabled(type) TruthValue 
set tnMVRImmediateLeaveEnabled(access) read-write
set tnMVRChannelEndAddr(oid) 1.3.6.1.4.1.868.2.5.50.2.1.4.1.4
set tnMVRChannelEndAddr(type) InetAddress 
set tnMVRChannelEndAddr(access) read-write
set tnMVRChannelName(oid) 1.3.6.1.4.1.868.2.5.50.2.1.4.1.5
set tnMVRChannelName(type) DisplayString 
set tnMVRChannelName(access) read-write
set tnMVRChannelRowStatus(oid) 1.3.6.1.4.1.868.2.5.50.2.1.4.1.6
set tnMVRChannelRowStatus(type) RowStatus 
set tnMVRChannelRowStatus(access) read-create
set tnIGMPQueriesRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.2
set tnIGMPQueriesRx(type) Unsigned32 
set tnIGMPQueriesRx(access) read-only
set tnMLDQueriesRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.3
set tnMLDQueriesRx(type) Unsigned32 
set tnMLDQueriesRx(access) read-only
set tnIGMPQueriesTx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.4
set tnIGMPQueriesTx(type) Unsigned32 
set tnIGMPQueriesTx(access) read-only
set tnMLDQueriesTx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.5
set tnMLDQueriesTx(type) Unsigned32 
set tnMLDQueriesTx(access) read-only
set tnIGMPv1JoinsRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.6
set tnIGMPv1JoinsRx(type) Unsigned32 
set tnIGMPv1JoinsRx(access) read-only
set tnIGMPv2ReportsRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.7
set tnIGMPv2ReportsRx(type) Unsigned32 
set tnIGMPv2ReportsRx(access) read-only
set tnMLDv1ReportsRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.8
set tnMLDv1ReportsRx(type) Unsigned32 
set tnMLDv1ReportsRx(access) read-only
set tnIGMPv3ReportsRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.9
set tnIGMPv3ReportsRx(type) Unsigned32 
set tnIGMPv3ReportsRx(access) read-only
set tnMLDv2ReportsRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.10
set tnMLDv2ReportsRx(type) Unsigned32 
set tnMLDv2ReportsRx(access) read-only
set tnIGMPv2LeavesRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.11
set tnIGMPv2LeavesRx(type) Unsigned32 
set tnIGMPv2LeavesRx(access) read-only
set tnMLDv1LeavesRx(oid) 1.3.6.1.4.1.868.2.5.50.2.1.5.1.12
set tnMLDv1LeavesRx(type) Unsigned32 
set tnMLDv1LeavesRx(access) read-only
set tnMVRGroupPortMembers(oid) 1.3.6.1.4.1.868.2.5.50.2.1.6.1.4
set tnMVRGroupPortMembers(type) PortList 
set tnMVRGroupPortMembers(access) read-only
set tnMVRSFMType(oid) 1.3.6.1.4.1.868.2.5.50.2.1.7.1.8
set tnMVRSFMType(type) INTEGER 
set tnMVRSFMType(access) read-only
set tnMVRSFMHardwareFilter(oid) 1.3.6.1.4.1.868.2.5.50.2.1.7.1.9
set tnMVRSFMHardwareFilter(type) TruthValue 
set tnMVRSFMHardwareFilter(access) read-only
set tnMVRSFM(oid) 1.3.6.1.4.1.868.2.5.50.2.1.7.1

}

namespace import util::*
namespace eval mvr {
	namespace export *
}
#mvr::mvrenable true 
#mvr::mvrenable false
proc mvr::mvrenable {enable} {
	set enable [string tolower $enable]
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRMode(oid)  ".1 "
	set mvrenable_type [getType $mvroid::tnMVRMode(type)]
	append cmd $mvrenable_type
	if {$enable=="true"} {
		append cmd " 1"
	} elseif {$enable=="false"} {
		append cmd " 2"	
	} else {
		error "the parameter should be true or false\n"
	}
	
	set res [catch {eval $cmd} error]
	if {$res} {
		error "fail to enable the mvr mode"
	 } else {
	 	puts "config the mvr mode succeesful"
	 }

}
#add or del the mvr vlan_interface entry
#the vid accept both leagal and illeagal value
proc mvr::vlan_interface_setting {{oper add} {vid 1}} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRInterfaceRowStatus(oid) "."
	set rowstatus_type [getType $mvroid::tnMVRInterfaceRowStatus(type)]

	if {$oper=="add"} {
		set rowstatus_value " 4"
	} elseif {$oper=="del"} {
		append rowstatus_value " 6"
	} else {
		error "the operation for mvr_vlan_interface entry must be add or del\n"
	}
	append cmd $vid " " $rowstatus_type $rowstatus_value
	set match [regexp {[^0-9]} $vid]
	if {!$match&&$vid>=1 && $vid<=4094} {
		set res [catch {eval $cmd} error]
		if {$res} {
		puts "fail to operate the mvr vlan interface entry with the leagal vlanid"
		exit
		} else {
			puts "operate the mvr vlan interface entry succeesful"
		}
	} else {
		set res [catch {eval $cmd} error]
		if {$res} {
			puts "can't operate the mvr vlan interface entry with illeagal vlanid"
		} else {
			error "operate the mvr vlan interface entry succeesful with the illeagal vlanid"
		}
	}
	
}
#set the MVR Name for the specific MVR VLIAN ID
proc mvr::parameter_mvrname {mvr_vid mvr_name} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRName(oid) "." $mvr_vid " "
	set mvr_name_type [getType $mvroid::tnMVRName(type)]
	append cmd $mvr_name_type " "
	append cmd $mvr_name

	set match_format [regexp {[^a-zA-Z0-9]} $mvr_name]
	puts $match_format
	set length_name [string length $mvr_name]
	if {$match_format || $length_name>32} {
		set res [catch {eval cmd} error]
		if {$res} {
			puts "can't modify the illeagal mvr name"
		} else {
			error "modify the illeagal mvr name succeesful"
			
		}
	} else {
		set res [catch {eval $cmd} error]
		if {$res} {
			error "can't modify the leagal mvr name"
		} else {
			puts "modify the leagal mvr name succesful"
		}
	}

}

#the interface_mode must be dynamic or compatible
proc mvr::parameter_mode {mvr_vid interface_mode} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRInterfaceMode(oid) "." $mvr_vid " "
	set interface_mode_type [getType $mvroid::tnMVRInterfaceMode(type)]
	append cmd $interface_mode_type " "
	set interface_mode [string tolower $interface_mode]
	switch -- $interface_mode {
		"dynamic" {set interface_mode 1}
		"compatible" {set interface_mode 2}
		default {error "the name of interface_mode is incorrect"}
	}
	append cmd $interface_mode

	set res [catch {eval $cmd} error]
	if {$res} {
		error "can't modify the leagal mvr mode"
	} else {
		puts "modify the mvr interface mode successfully"
	}
}

#the tagging must be untagged or tagged
proc mvr::parameter_tagging {mvr_vid tagging} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRInterfaceTagging(oid) "." $mvr_vid " "
	set interface_tagging_type [getType $mvroid::tnMVRInterfaceTagging(type)]
	append cmd $interface_tagging_type " "
	switch -- $tagging {
		"untagged" {set tagging 1}
		"tagged" {set tagging 2}
		default {error "the name of the tagging option is incorrect"}

	}
	append cmd $tagging
	set res [catch {eval $cmd} error]
	if {$res} {
		error "can't modify the tagging mode"
	} else {
		puts "modify the mvr tagging mode successfully"
	}
}

proc mvr::parameter_priority {mvr_vid priority} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRInterfacePriority(oid) "." $mvr_vid " "
	set priority_type [getType $mvroid::tnMVRInterfacePriority(type)]
	append cmd $priority_type " "
	set match_format [regexp {[^0-7]} $priority]
	puts $match_format
	if {!$match_format && $match_format>=0 && $match_format<=7} {
		append cmd $priority
		set res [catch {eval $cmd} error]
		if {$res} {
			error "can't modify the prority"
		} else {
			puts "modify the priority successfully"
		}
	} else {
		error "the format of priority is incorrect"
	}
}

proc mvr::parameter_llqi {mvr_vid llqi} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRInterfaceLLQI(oid) "." $mvr_vid " "
	set llqi_type [getType $mvroid::tnMVRInterfaceLLQI(type)]
	append cmd $llqi_type " "
	set match_format [regexp {[^0-9]} $llqi]
	if {!$match_format && $llqi>=0 && $llqi<=31744} {
		append cmd $llqi
		set res [catch {eval $cmd} error]
		if {$res} {
			error "can't modify the llqi"
		} else {
			puts "modify the llqi successfully"
		}

	} else {
		error "the format of priority is incorrect"
	}
 }

#the oper must be add or del
#mvr::channel_setting 300 add ff00::1 ff00::a TNDVT
 proc mvr::channel_setting {mvr_vid oper source_multicast end_multicast channel_name} {
 	append cmd "exec snmpset " $::session " " $mvroid::tnMVRChannelRowStatus(oid) "." $mvr_vid ".1.4."
 	set len [string length $source_multicast]
 	for {set i 0} {$i<$len} {incr i} {
 		if {[string index $source_multicast $i]==":"} {
 			set source_multicast [mvr::ipv6_normalize $source_multicast 1]
 			set end_multicast [mvr::ipv6_normalize $end_multicast 2]
 			set cmd ""
 			append cmd "exec snmpset " $::session " " $mvroid::tnMVRChannelRowStatus(oid) "." $mvr_vid ".2.16."
 			break
 		} elseif {$i==[expr $len-1]} {
 			set endlist [split $end_multicast .]
 			foreach item $endlist {
 				append end [format "%02x" $item]
 			}
 			set end_multicast $end

 		}
 	}
 	append cmd $source_multicast " " "i" " "
 	switch -- $oper {
 		"add" {set oper 4}
 		"del" {set oper 6}
 		default {error "make sure the oper is add or del"}
 	} 
 	append cmd $oper
 	set res [catch {eval $cmd} error]
 	if {$res} {
 		error "make sure the mrv_vid and source_multcast is correct"
 	} else {
 		puts "operate the interface channel successfully"
 	}
 	if {$oper==6} {return}
 	set cmd_temp [split $cmd " "]
 	set end_oid $mvroid::tnMVRChannelEndAddr(oid)
 	set end_type [getType $mvroid::tnMVRChannelEndAddr(type)]
 	set channel_name_oid $mvroid::tnMVRChannelName(oid)
 	set channel_name_type [getType $mvroid::tnMVRChannelName(type)]
 	set cmd_oid [lindex $cmd_temp 6]
 	set status_oid_length [string length $mvroid::tnMVRChannelRowStatus(oid)]
 	set end_oid [string replace $cmd_oid 0 [expr $status_oid_length-1] $end_oid]
 
 	set cmd_end [lreplace $cmd_temp 6 8 $end_oid $end_type $end_multicast]
 	set cmd_end [join $cmd_end " "]
 	set res [catch {eval $cmd_end} error]
 	if {$res} {
 		error "make sure the end multicast address is correct"
 	}
 	set channel_name_oid [string replace $cmd_oid 0 [expr $status_oid_length-1] $channel_name_oid]
 	set cmd_channel_name [lreplace $cmd_temp 6 8 $channel_name_oid $channel_name_type $channel_name]
 	set res [catch {eval $cmd_channel_name} error]
 	if {$res} {
 		error "make sure the channel name is correct"
 	}
 }

#config the port role 
#mvr::port_role 200 80 40
proc mvr::port_role {mvr_id src_port rec_port} {
	append cmd1 "exec snmpset " $::session " " $mvroid::tnMVRSourcePortList(oid) "." $mvr_id " "
	append cmd2 "exec snmpset " $::session " " $mvroid::tnMVRReceiverPortList(oid) "." $mvr_id " "
	set type_src_port [getType $mvroid::tnMVRSourcePortList(type)]
	set type_rec_port [getType $mvroid::tnMVRReceiverPortList(type)]
	append cmd1 $type_src_port " " $src_port
	append cmd2 $type_rec_port " " $rec_port
	set res1 [catch {eval $cmd1} error]
	set res2 [catch {eval $cmd2} error]
	if {$res1 && $res2} {
		error "can't config the port role"
	} else {
		puts "set the port role successfully"
	}

}
#enalbe_mode should be false or true
proc mvr::immediate_leave {port enable_mode} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRImmediateLeaveEnabled(oid) "." $port " "
	set immediate_leave_type [getType $mvroid::tnMVRImmediateLeaveEnabled(type)]
	switch -- $enable_mode {
		"true" {set enable_mode 1}
		"false" {set enable_mode 2}
		default {error "make sure input the correct enable_mode"}
	}
	append cmd $immediate_leave_type " " $enable_mode
	set res [catch {eval $cmd} error]
	if {$res} {
		error "can't enable/disable the immediate_leave mode"
	} else {
		puts "enable/disable immediate_leave mode successfully"
	}

}

#convert ipv6 multicast address to decimal 
#ipv6_normalize ff00::1 will return :
#mode = 1:
#255.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1
#mode = 2:
#ff000000000000000000000000000001
proc mvr::ipv6_normalize {ipv6 mode} {
	set oct [split $ipv6 :]
	set len [llength $oct]
	for {set i 0} {$i<$len} {incr i} {
		if {[lindex $oct $i]==""} {
			for {set j 0} {$j<[expr 8 - $len]} {incr j} {
				set oct [linsert $oct [expr $i+$j] 0]
#				puts $oct
			}
			if {$i!=0} {
				set oct [lreplace $oct [expr $i+$j] [expr $i+$j] 0]
				} else {
					set oct [lreplace $oct [expr $i+$j] [expr $i+$j+1] 0 0]
					#set oct [lreplace $oct [expr $i+$j+1] [expr $i+$j+1] 0]
				}
			break
		}
	}
#	puts $oct
	for {set i 0} {$i<8} {incr i} {
		if {[string length [lindex $oct $i]]<4} {
			set oct [lreplace $oct $i $i [format %04x "0x[lindex $oct $i]"]]
		}
#		set dec_temp [format "%d" "0x[lindex $oct $i]"]
		set string_temp [lindex $oct $i]
		set string_temp_first [string range $string_temp 0 1]
		set string_temp_second [string range $string_temp 2 3]
		set dec_first [format "%d" "0x$string_temp_first"]
		set dec_second [format "%d" "0x$string_temp_second"]
		lappend new_oct $dec_first $dec_second
	}
	set ipv6_new [join $new_oct .]
	foreach elem $oct {
		append new_oct_2 $elem
	}
#	puts $new_oct_2
	if {$mode==1} {
		return $ipv6_new
		} elseif {$mode==2} {
			return $new_oct_2
		} else {
			puts "make sure input the correct mode "
		}
}




###############################################
#check the mvr group info 
proc mvr::check_group {} {
	append cmd "exec snmpwalk " $::session " " "$mvroid::tnMVRGroupPortMembers(oid)"
	set res [catch {eval $cmd} e]
	if {$res} {
		error "can't get the mvr group info"
	} 
	set group_entry ""
	set oid "iso.3.6.1.4.1.868.2.5.50.2.1.6.1.4."
	set oid_length [string length $oid]
	if {[string first \" $e]==-1} {return $group_entry}
	while {[string first "iso" $e]!=-1} {
		set group_port ""
		set e [string replace $e 0 [expr $oid_length-1]]
		set loc [string first . $e]
		set group_vlan_id [string range $e 0 [expr $loc-1]]
#it seems that string trimleft can't delete a string with above two ".", so the command below 
#will del two times while meet above two "."
		set e [string trimleft $e "$group_vlan_id"]
		set e [string trimleft $e "."]
		if {[string index $e 0]==1} {
			set e [string trimleft $e 1.]
			set e [string trimleft $e 4.]
		} elseif {[string index $e 0]==2} {
			set e [string trimleft $e 2.]
			set e [string trimleft $e 16.]
		}
		set loc [string first = $e]
		set group_address [string range $e 0 [expr $loc-2]]
		set e [string trimleft $e $group_address]
		set loc [string first \" $e]
		set e [string replace $e 0 $loc]
		set port_num [string index $e 0]
		binary scan $port_num B8 var1
		for {set i 1} {$i<=8} {incr i} {
			if {[string index $var1 [expr $i-1]]==1} {
				lappend group_port $i
			}
		}
		lappend group_entry $group_vlan_id $group_address $group_port
		set e [string replace $e 0 [expr 1+[string first \" $e]]]
	}
	return $group_entry
}
############################################################
#check the SFM Table
#this function will return a array,each array entry is a list 
#each list contain the SFM table's: vlanid,group,port,mode,source address,type,hardware filter mode
#sfm_arr is like sfm_arr(index) [list vlanid group port mode sourceiplist type hardwareenable] 
proc check_SFM {sfm_arr} {
	upvar $sfm_arr SFM_entry
	append cmd "exec snmpwalk " $::session " " "$mvroid::tnMVRSFMType(oid)"
	set res [catch {eval $cmd} e]
	if {$res} {
		error "can't get the mvr SFMType info"
	} 
	array set  SFM_entry {}
	set sfmoid iso[string trimleft $mvroid::tnMVRSFMType(oid) 1]
	set entry_list 0
	while {[string first INTEGER $e]!=-1} {
		incr entry_list

		set e [string replace $e 0 [string length $sfmoid]]
		set vlanid [string range $e 0 [expr [string first "." $e]-1]]
		lappend SFM_entry($entry_list) $vlanid 
		set e [string replace $e 0 [string first "." $e]]
		set group_addr ""
		if {[string index $e 0]==1} {
			set multi_type 1
			set e [string trimleft $e {1.4.}]
			for {set ip_loop 1} {$ip_loop<=4} {incr ip_loop} {
				lappend group_addr [string range $e 0 [expr [string first "." $e]-1]]
				set e [string replace $e 0 [string first "." $e]]
			}
		} else {
				set multi_type 2
				set e [string trimleft $e {2.}]
				set e [string trimleft $e {16.}]
				for {set ipv6_loop 1} {$ipv6_loop<=16} {incr ipv6_loop} {
					lappend group_addr [string range $e 0 [expr [string first "." $e]-1]]
					set e [string replace $e 0 [string first "." $e]]
				}
			}

		set group_addr [join $group_addr "."]
		lappend SFM_entry($entry_list) $group_addr
		set group_port [string range $e 0 [string first "." $e]-1]
		lappend SFM_entry($entry_list) $group_port
		set e [string replace $e 0 [string first "." $e]]
		set group_mode [string range $e 0 [string first "." $e]-1]
		switch $group_mode {
			1 {set group_mode include}
			2 {set group_mode exclude}
		}
		lappend SFM_entry($entry_list) $group_mode
		set e [string replace $e 0 [string first "." $e]]
		if {[string index $e 0]==1} {
			set e [string trimleft $e {1.}]
			set e [string trimleft $e {4.}]
			#puts $e 
			for {set ip_loop 1} {$ip_loop<=3} {incr ip_loop} {
				lappend source_addr [string range $e 0 [expr [string first "." $e]-1]]
				set e [string replace $e 0 [string first "." $e]]
			}
			lappend source_addr [string range $e 0 [expr [string first " " $e]-1]]
			set e [string replace $e 0 [string first " " $e]]
		} else {
			set e [string trimleft $e {2.}]
				set e [string trimleft $e {16.}]
				#puts $e 
				for {set ipv6_loop 1} {$ipv6_loop<=15} {incr ipv6_loop} {
					lappend source_addr [string range $e 0 [expr [string first "." $e]-1]]
					set e [string replace $e 0 [string first "." $e]]
				}
			lappend source_addr [string range $e 0 [expr [string first " " $e]-1]]
			set e [string replace $e 0 [string first " " $e]]
		  }
		set source_addr [join $source_addr "."]
		lappend SFM_entry($entry_list) $source_addr
		set source_addr ""
		set e [string trimleft $e {= INTEGER: }]
		set group_type [string index $e 0]
		set e [string replace $e 0 1]
		switch -- $group_type {
			1 {set group_type allow}
			2 {set group_type deny}
		}
		lappend SFM_entry($entry_list) $group_type

	}
	append cmd2 "exec snmpwalk " $::session " " "$mvroid::tnMVRSFMHardwareFilter(oid)"
	set res [catch {eval $cmd2} e]
	if {$res} {
		error "can't get the mvr SFMHardwarefilter info"
	} 
	for {set i 1} {$i<=$entry_list} {incr i} {
		set e [string replace $e 0 [string first ":" $e]]
		set hardware_enable [string index $e 1]
		string replace $e 0 2
		switch $hardware_enable {
			1 {set hardware_enable yes}
			2 {set hardware_enable no}
		}
		lappend SFM_entry($i) $hardware_enable
	}
	
}


######################################
#check the statistics for mvr 
#return the statistics as an array,the index is vlanid,the value is the statistics number.
#the statis_type is which type of packets you want to get.
#the stat is like : stat($vlanid) $statistics
proc check_statis {statis_type stat} {
	upvar $stat statis 
	switch $statis_type {
		igmpqueryrx {set miboid $mvroid::tnIGMPQueriesRx(oid)}
		mldqueryrx {set miboid $mvroid::tnMLDQueriesRx(oid)}
		igmpquerytx {set miboid $mvroid::tnIGMPQueriesTx(oid)}
		mldquerytx {set miboid $mvroid::tnMLDQueriesTx(oid)}
		igmpv1joinrx {set miboid $mvroid::tnIGMPv1JoinsRx(oid)}
		igmpv2reportrx {set miboid $mvroid::tnIGMPv2ReportsRx(oid)}
		mldv1reportrx {set miboid $mvroid::tnMLDv1ReportsRx(oid)}
		igmpv3reportrx {set miboid $mvroid::tnIGMPv3ReportsRx(oid)}
		mldv2reportrx {set miboid $mvroid::tnMLDv2ReportsRx(oid)}
		igmpv2leaverx {set miboid $mvroid::tnIGMPv2LeavesRx(oid)}
		mldv1leaverx {set miboid $mvroid::tnMLDv1LeavesRx(oid)}
		default {puts "incorrect parameter!!!"}
	}
	append cmd "exec snmpwalk " $::session " " $miboid
	array set  statis {}
	set res [catch {eval $cmd} e]
	if {$res} {
		puts "can't get the Statistics of $statis_type"
	}
	while {[string first "Gauge32" $e]!=-1} {
		set string_vlan [string range $e 0 [string first "=" $e]]
		set vlanid [string range $string_vlan [expr 1+[string last "." $string_vlan ]]  [expr [string first " " $string_vlan]-1]]
		set e [string replace $e 0 [expr 9+[string length $string_vlan]]]
		if {[string first "Gauge32" $e]!=-1} {
			set num [string range $e 0 [expr [string first "\n" $e]-1]]
			set e [string trimleft $e "$num"]
			set e [string trimleft $e "\n"]
			} else {
				set num [string range $e 0 end]

			}
		set statis($vlanid) $num
	} 
}


#####################clear the statistics of mvr ##################
proc clear_mvr_stat {} {
	append cmd "exec snmpset " $::session " " $mvroid::tnMVRStatisticsClear(oid) ".1" " "
	set stat_type [getType $mvroid::tnMVRStatisticsClear(type)]
	append cmd $stat_type " " "1"
	set res [catch {eval $cmd} e]
	if {$res==1} {
		puts "can't clear the statistics of mvr"
	}
}