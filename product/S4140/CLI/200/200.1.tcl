# #!/bin/sh
# #\
# exec tclsh "$0" "$@"

# #Filename: S4140 EPL Configuration1.tcl
# #History:
# #        10/30/2013- Jefferson,Created
# #		   12/16/2013- Olivia,Finished
# #
# #Copyright(c): Transition Networks, Inc.2013

# #Notes:

# #by default:
# #************DUT1 parameters***********

# # vlan remove 1 all  
# # vlan porttype 1 s-port
# # vlan porttype 2-4 c-port
# # evc add 1 11 1001 1 enable
# # evc ece add 1 uni 3 evc 1
# # mep config 1 mip up 3 domevc 5 2013 11 1 enable
# # evc port l2cp all 0,11-13,15-31 tunnel
# # evc port l2cp all 1-10,14 discard

# #***************************************

# #************DUT2 parameters***********

# # vlan remove 1 all
# # vlan porttype 1 s-port
# # vlan porttype 2-4 c-port
# # evc add 1 11 1001 1 enable
# # evc ece add 1 uni 3 evc 1
# # mep config 1 mip up 3 domevc 5 2014 11 1 enable
# # evc port l2cp all 0,11-13,15-31 tunnel
# # evc port l2cp all 1-10,14 discard

# #***************************************
# #******************************************************************************************************************************************

variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
puts "path:$path"
source $path/init.tcl

# IXIA config parameters
set evc_vid 11
set priority_vid 0
set tpid 8100
set tpid1 88a8
set min_size 64
set max_size 8000
set unframe_size 1518
set frame_size 1522
set broadcast "FF FF FF FF FF FF"
set multicast "01 00 5E 11 22 33"
set unicast1 "00 00 00 01 02 03"
set unicast2 "00 00 00 04 05 06"
set unknownDA "00 00 00 99 99 99"
set L2CP_mac_00 "01 80 C2 00 00 00"
set L2CP_mac_07 "01 80 C2 00 00 07"
set L2CP_mac_0E "01 80 C2 00 00 0E"
set L2CP_mac_0F "01 80 C2 00 00 0F"


proc configCommands {evc_vid spawnIDa spawnIDb} {

    # DUT config parameters
	set max_port_list all
	set default_vid 1
	set dut_lnk_pt 1
	set eqpt_lnk_pt "2-4"
	set out_port_type "s-port"
	set in_port_type "c-port"
	set evc_id 1
	set evc_ivid 1001
	set nni_list 1
	set ece_id 1
	set uni_list 3
	set map_evc "nni"
	set evc_instance 1
	set mip_instance 1
	set mip_direction "up"
	set mip_domain "domevc"
	set mip_level 5
	

	
	foreach id "$spawnIDa $spawnIDb" {

	#Port Mode [<port_list>] [auto|10hdx|10fdx|100hdx|100fdx|1000fdx|2500fdx|10gfdx|sfp_auto_ams]	
		exp_send -i $id "port mode $uni_list auto\r"
        expect -i $id ">"

    #STP Port Mode [<stp_port_list>] [enable|disable]
    	exp_send -i $id "stp port mode disable\r"
        expect -i $id ">"

	#VLAN remove <vid>|<name> [<port_list>]
	    exp_send -i $id "vlan remove $default_vid $max_port_list\r"
        expect -i $id ">"

	#VLAN PortType [<port_list>] [unaware|c-port|s-port|s-custom-port]
	    exp_send -i $id "vlan porttype $dut_lnk_pt $out_port_type\r"
        expect -i $id ">"
	    exp_send -i $id "vlan porttype $eqpt_lnk_pt $in_port_type\r"
        expect -i $id ">"

	#EVC Add <evc_id> [<vid>] [<ivid>] [<nni_list>] [<learning>] [<policer_id>]
	    exp_send -i $id "evc add $evc_id $evc_vid $evc_ivid $nni_list enable\r"
        expect -i $id ">"
	#EVC ECE Add [<ece_id>] [<ece_id_next>] [uni] [<uni_list>] [tag] [<tag_type>] [<vid>] [<pcp>] [<dei>] [intag] [<in_type>] [<in_vid>] [<in_pcp>] [<in_dei>]\
	[all | (ipv4 [<dscp>]) | (ipv6 [<dscp>])] [direction] [<direction>] [evc] [<evc_id>] [<policer_id>]\
	[pop] [<pop>] [policy] [<policy>] \
	[outer] [<ot_mode>] [<ot_vid>] [<ot_preserve>] [<ot_pcp>] [<ot_dei>] \
	[inner] [<it_type>] [<it_vid>] [<it_preserve>] [<it_pcp>] [<it_dei>]
	
	    exp_send -i $id "evc ece add $ece_id uni $uni_list evc $evc_id\r"
        expect -i $id ">"

        exp_send -i $id "mep config $mip_instance mip $mip_direction $uni_list $mip_domain $mip_level 2014 $evc_vid $evc_id enable\r"
    #MEP config [<inst>] [mep|mip] [down|up] [<port>] [domport|domevc] [<level>] [itu|ieee] [<meg>] [<mep>] [<vid>] [<flow>] [enable|disable]
        expect -i $id ">"
        
        exp_send -i $id "evc port l2cp $max_port_list 0,11-13,15-31 tunnel\r"
        expect -i $id ">"
    #EVC Port L2CP [<port_list>] [<l2cp_list>] [<mode>]
    
        exp_send -i $id "evc port l2cp $max_port_list 1-10,14 discard\r"
        expect -i $id ">"
    #EVC Port L2CP [<port_list>] [<l2cp_list>] [<mode>]  

	}
	exp_send -i $id "logout\r"
    catch {exp_close -i $id}
}

proc Option2config {evc_vid spawnIDa spawnIDb} {
	set max_port_list all
    # DUT config parameters
	foreach id "$spawnIDa $spawnIDb" {
	exp_send -i $id "evc port l2cp $max_port_list 0,7,14,16-31 tunnel\r"
    expect -i $id ">"
    #EVC Port L2CP [<port_list>] [<l2cp_list>] [<mode>]  
	}
	exp_send -i $id "logout\r"
    catch {exp_close -i $id}
}


mef::chkDutConnect $::dut1 $::dut2

setToFactoryDefault $::dut1
setToFactoryDefault $::dut2

mef::loginSystem $::dut1 $::dut2

mef::chkSystemVersion $::dut1 $::dut2

configCommands $evc_vid $::spawnIDa $::spawnIDb


###################set ixia_rate 1

###################this case only use one EQPT1, so just consider two ports in ixia to connect another two in DUT1 and DUT2
connect_ixia -ipaddr $::ixiaIpAddr -portlist $ixiaPort1,ixiap1,$ixiaPort2,ixiap2 -alias allport -loginname AutoIxia

config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode


puts "\n\n\nTEST CASE 1.1.1\n"

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $broadcast -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"

set getCaptured [check_capture -alias ixiap2 -dstmac $broadcast -vlanid $evc_vid -tpid $tpid -length $frame_size]
puts $getCaptured
if { $getCaptured == 10 } {
	puts "TEST CASE 1.1.1(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 1.1.1(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}

config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $broadcast -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"

set getCaptured [check_capture -alias ixiap1 -dstmac $broadcast -vlanid $evc_vid -tpid $tpid -length $frame_size]
#puts $getCaptured
if { $getCaptured == 10 } {
	puts "TEST CASE 1.1.1(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 1.1.1(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}
puts "TEST CASE 1.1.1 Finished"



puts "\n\n\nTEST CASE 1.1.2\n"
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $multicast -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $multicast -vlanid $evc_vid -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 1.1.2(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 1.1.2(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}

config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $multicast -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"

set getCaptured [check_capture -alias ixiap1 -dstmac $multicast -vlanid $evc_vid -tpid $tpid -length $frame_size]
if { $getCaptured==10 } {
	puts "TEST CASE 1.1.2(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 1.1.2(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}
puts "TEST CASE 1.1.2 Finished"





puts "\n\n\nTEST CASE 1.1.3\n"
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $evc_vid -tpid $tpid]
if { $getCaptured == 10 } {
	puts "TEST CASE 1.1.3(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 1.1.3(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}


config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx

set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $evc_vid -tpid $tpid]
if { $getCaptured == 10 } {
	puts "TEST CASE 1.1.3(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 1.1.3(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}
puts "TEST CASE 1.1.3 Finished"





puts "\n\n\nTEST CASE 1.1.4\n"

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unknownDA -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"

set getCaptured [check_capture -alias ixiap2 -dstmac $unknownDA -vlanid $evc_vid -tpid $tpid -length $frame_size]

if { $getCaptured == 10 } {
	puts "TEST CASE 1.1.4(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 1.1.4(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}

config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unknownDA -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
set getCaptured [check_capture -alias ixiap1 -dstmac $unknownDA -vlanid $evc_vid -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 1.1.4(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 1.1.4(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}
puts "TEST CASE 1.1.4 Finished"




puts "\n\n\nTEST CASE 4.1.1\n"
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 -fcs badcrc
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $evc_vid -tpid $tpid]
if { $getCaptured == 0 } {
	puts "TEST CASE 4.1.1(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 4.1.1(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 -fcs badcrc
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx"
set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $evc_vid -tpid $tpid]
if { $getCaptured == 0 } {
	puts "TEST CASE 4.1.1(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 4.1.1(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}
puts "TEST CASE 4.1.1 Finished\n\n\n"



connect_ixia -ipaddr $::ixiaIpAddr -portlist $ixiaPort1,ixiap1,$ixiaPort2,ixiap2 -alias allport -loginname AutoIxia
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode



puts "\n\n\nTEST CASE 10.1.1\n"
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode none -dstmac $unicast1 -srcmac $unicast2 -framesize $unframe_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
# puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -length $unframe_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 10.1.1(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 10.1.1(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize "
}


config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode none -dstmac $unicast2 -srcmac $unicast1 -framesize $unframe_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
# puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx"
set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -length $unframe_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 10.1.1(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 10.1.1(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize "
}
puts "TEST CASE 10.1.1 Finished"





puts "\n\n\nTEST CASE 11.1.1\n"
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $evc_vid -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 11.1.1(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 11.1.1(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}


config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx

set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $evc_vid -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 11.1.1(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 11.1.1(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}
puts "TEST CASE 11.1.1 Finished"




puts "\n\n\nTEST CASE 11.1.2\n"

config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $priority_vid -tpid $tpid]
if { $getCaptured == 10 } {
	puts "TEST CASE 11.1.2(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 11.1.2(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $priority_vid -tpid $tpid]
if { $getCaptured == 10 } {
	puts "TEST CASE 11.1.2(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 11.1.2(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize "
}
puts "TEST CASE 11.1.2 Finished"




puts "\n\n\nTEST CASE 12.1.1\n"
for {set i 0} { $i<8 } {incr i 1} {
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -priority $i -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -priority $i -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $evc_vid -tpid $tpid -priority $i]
if { $getCaptured == 10 } {
	puts "TEST CASE 12.1.1(a)-UNIA to UNIB Priority=$i:  PASS\n"
} else {
	puts "TEST CASE 12.1.1(a)-UNIA to UNIB Priority=$i:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize, $actualPri"
}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -priority $i -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -priority $i -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx

set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $evc_vid -priority $i -tpid $tpid]
if { $getCaptured == 10 } {
	puts "TEST CASE 12.1.1(b)-UNIB to UNIA Priority=$i:  PASS\n"
} else {
	puts "TEST CASE 12.1.1(b)-UNIB to UNIA Priority=$i:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize, $actualPri"
}

}
puts "TEST CASE 12.1.1 Finished"



puts "\n\n\nTEST CASE 12.1.2\n"

for {set i 0} { $i<8 } {incr i 1} {
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $priority_vid -priority $i -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -priority $i -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $priority_vid -tpid $tpid -priority $i]
if { $getCaptured == 10 } {
	puts "TEST CASE 12.1.2(a)-UNIA to UNIB Priority=$i:  PASS\n"
} else {
	puts "TEST CASE 12.1.2(a)-UNIA to UNIB Priority=$i:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $actualPri"
}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $priority_vid -priority $i -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $priority_vid -priority $i -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx

set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $priority_vid -priority $i -tpid $tpid]
if { $getCaptured == 10 } {
	puts "TEST CASE 12.1.2(b)-UNIB to UNIA Priority=$i:  PASS\n"
} else {
	puts "TEST CASE 12.1.2(b)-UNIB to UNIA Priority=$i:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $actualPri"
}

}
puts "TEST CASE 12.1.2 Finished"





puts "\n\n\nTEST CASE 14.1.1"
puts "This Case Need to Change Different SFP Manually, so Current Auto Test NOT Support"






puts "\n\n\nTEST CASE 15.1.1\n"
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode none -dstmac $unicast1 -srcmac $unicast2 -framesize $max_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxoversize ixiap2rx
# puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -length $max_size]

if { $getCaptured == 10 } {
	puts "TEST CASE 15.1.1(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 15.1.1(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $numEthernetType, $actualVlanid, $sortframesize, $actualPri"
}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode none -dstmac $unicast2 -srcmac $unicast1 -framesize $max_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxoversize ixiap1rx
# puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx"

set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -length $max_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 15.1.1(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 15.1.1(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize"
}

puts "TEST CASE 15.1.1 Finished"







puts "\n\n\nTEST CASE 15.1.2\n"
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode none -dstmac $unicast1 -srcmac $unicast2 -framesize $min_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -length $min_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 15.1.2(a)-UNIA to UNIB:  PASS\n"
} else {
	puts "TEST CASE 15.1.2(a)-UNIA to UNIB:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize"
}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode none -dstmac $unicast2 -srcmac $unicast1 -framesize $min_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx"

set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -length $min_size]

if { $getCaptured == 10 } {
	puts "TEST CASE 15.1.2(b)-UNIB to UNIA:  PASS\n"
} else {
	puts "TEST CASE 15.1.2(b)-UNIB to UNIA:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize"
}

puts "TEST CASE 15.1.2 Finished"




puts "\n\n\nTEST CASE 21.1.1\n"
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode none -dstmac $unicast1 -srcmac $unicast2 -framesize $unframe_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -length $unframe_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 21.1.1(a)-UNIA to UNIB Untagged:  PASS\n"
} else {
	puts "TEST CASE 21.1.1(a)-UNIA to UNIB Untagged:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize"
}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode none -dstmac $unicast2 -srcmac $unicast1 -framesize $unframe_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx"
set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -length $unframe_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 21.1.1(b)-UNIB to UNIA Untagged:  PASS\n"
} else {
	puts "TEST CASE 21.1.1(b)-UNIB to UNIA Untagged:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize"
}


config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $priority_vid -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 21.1.1(a)-UNIA to UNIB Priority Tagged:  PASS\n"
} else {
	puts "TEST CASE 21.1.1(a)-UNIA to UNIB Priority Tagged:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize, $actualVlanid, $numEthernetType"
}




config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $priority_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx"
set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $priority_vid -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 21.1.1(b)-UNIB to UNIA Priority Tagged:  PASS\n"
} else {
	puts "TEST CASE 21.1.1(b)-UNIB to UNIA Priority Tagged:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize, $actualVlanid, $numEthernetType"
}


config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $evc_vid -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 21.1.1(a)-UNIA to UNIB CE-VLAN ID=11:  PASS\n"
} else {
	puts "TEST CASE 21.1.1(a)-UNIA to UNIB CE-VLAN ID=11:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize, $actualVlanid, $numEthernetType"
}


config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx"
set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $evc_vid -tpid $tpid]
if { $getCaptured == 10 } {
	puts "TEST CASE 21.1.1(b)-UNIB to UNIA CE-VLAN ID=11:  PASS\n"
} else {
	puts "TEST CASE 21.1.1(b)-UNIB to UNIA CE-VLAN ID=11:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize, $actualVlanid, $numEthernetType"
}

puts "TEST CASE 21.1.1 Finished"






puts "\n\n\nTEST CASE 24.1.1\n"
####The VLAN ID should be from 1 to 4095
#for {set i 4092} { $i<4096 } {incr i} {
for {set i 1} { $i<3 } {incr i} {
#puts $i
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $i -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap2 -actiontype start -time 1
#clear_stat -alias allport
start_capture -alias ixiap2
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $i -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

set getCaptured [check_capture -alias ixiap2 -dstmac $unicast1 -vlanid $i -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 24.1.1(a)-UNIA to UNIB VLAN ID=$i:  PASS\n"
} else {
	puts "TEST CASE 24.1.1(a)-UNIA to UNIB VLAN ID=$i:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize, $actualVlanid, $numEthernetType"
}


config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $i -tpid $tpid -dstmac $unicast1 -srcmac $unicast2 -framesize $frame_size
config_stream -alias ixiap1 -sendmode contpkt -ratemode fps -rate 1
send_traffic -alias ixiap1 -actiontype start -time 1
#clear_stat -alias allport
start_capture -alias ixiap1
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $i -tpid $tpid -dstmac $unicast2 -srcmac $unicast1 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10 
send_traffic -alias ixiap2 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx

set getCaptured [check_capture -alias ixiap1 -dstmac $unicast2 -vlanid $i -tpid $tpid -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE 24.1.1(b)-UNIB to UNIA VLAN ID=$i:  PASS\n"
} else {
	puts "TEST CASE 24.1.1(b)-UNIB to UNIA VLAN ID=$i:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac, $sortframesize, $actualVlanid, $numEthernetType"
}

}
puts "TEST CASE 24.1.1 Finished"




puts "\n\n\nTEST CASE 5.1.1\n"

for {set i 1} { $i<11 } {incr i} {
set l2cp_mac "01 80 C2 00 00 0"
if { $i <= 9 } {
	append l2cp_mac $i
    #puts $l2cp_mac\n
    } else {
    	set hex_i [format %x $i]
    	set capital_i [string toupper $hex_i]
    	append l2cp_mac $capital_i
    	#puts $l2cp_mac\n
    }
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $l2cp_mac]
if { $getCaptured == 0 } {
	puts "TEST CASE 5.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  PASS\n"
} else {
	puts "TEST CASE 5.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  FAIL"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}


config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $l2cp_mac]
if { $getCaptured == 0 } {
	puts "TEST CASE 5.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  PASS\n"
} else {
	puts "TEST CASE 5.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  FAIL"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}

}
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_0E -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $L2CP_mac_0E]
if { $getCaptured == 0 } {
	puts "TEST CASE 5.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_0E:  PASS\n"
} else {
	puts "TEST CASE 5.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_0E:  FAIL"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}
config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_0E -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $L2CP_mac_0E]
if { $getCaptured == 0 } {
	puts "TEST CASE 5.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_0E:  PASS\n"
} else {
	puts "TEST CASE 5.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_0E:  FAIL"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}

puts "TEST CASE 5.1.1 Finished"


puts "\n\n\nTEST CASE Option1 13.1.1\n"

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_00 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $L2CP_mac_00 -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_00:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_00:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}


config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_00 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $L2CP_mac_00 -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_00:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_00:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}


for {set i 11} { $i<14 } {incr i} {
set l2cp_mac "01 80 C2 00 00 0"
set hex_i [format %x $i]
set capital_i [string toupper $hex_i]
append l2cp_mac $capital_i
#puts $l2cp_mac\n
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $l2cp_mac]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}



config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $l2cp_mac]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}

}

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_0F -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $L2CP_mac_0F -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_0F:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_0F:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}

config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_0F -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $L2CP_mac_0F -length $frame_size]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_0F:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_0F:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}


for {set i 0} { $i<16 } {incr i} {
set l2cp_mac "01 80 C2 00 00 2"
if { $i <= 9 } {
	append l2cp_mac $i
    #puts $l2cp_mac\n
    } else {
    	set hex_i [format %x $i]
    	set capital_i [string toupper $hex_i]
    	append l2cp_mac $capital_i
    	#puts $l2cp_mac\n
}
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $l2cp_mac]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}


config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $l2cp_mac]
if { $getCaptured == 10 } {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  PASS\n"
} else {
	puts "TEST CASE Option1 13.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  FAIL\n"
	####for debug, this action need to globle the below parameters
	#puts "Actual Captured Frames Info: $sortdamac"
}

}

puts "TEST CASE Option1 13.1.1 Finished\n"

mef::loginSystem $::dut1 $::dut2
Option2config $evc_vid $::spawnIDa $::spawnIDb

puts "\n\n\nTEST CASE Option2 13.1.1\n"

config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_00 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $L2CP_mac_00 -length $frame_size]
#puts $getCaptured
# puts $sortdamac
#puts $L2CP_mac_00
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_00:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_00:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
 	}


config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_00 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $L2CP_mac_00 -length $frame_size]
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_00:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_00:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
	}



config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_07 -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $L2CP_mac_07 -length $frame_size]
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_07:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_07:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
	}

config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_07 -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $L2CP_mac_07 -length $frame_size]
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_07:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_07:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
	}




config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_0E -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $L2CP_mac_0E -length $frame_size]
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_0E:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$L2CP_mac_0E:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
	}


config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $L2CP_mac_0E -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $L2CP_mac_0E -length $frame_size]
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_0E:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$L2CP_mac_0E:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
	}





for {set i 0} { $i<16 } {incr i} {
set l2cp_mac "01 80 C2 00 00 2"
if { $i <= 9 } {
	append l2cp_mac $i
    #puts $l2cp_mac\n
    } else {
    	set hex_i [format %x $i]
    	set capital_i [string toupper $hex_i]
    	append l2cp_mac $capital_i
    	#puts $l2cp_mac\n
}
config_frame -alias ixiap1 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap1 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start
###################stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
stop_capture -alias ixiap2
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
#puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx\n"
set getCaptured [check_capture -alias ixiap2 -dstmac $l2cp_mac]
#puts $getCaptured
#puts $sortdamac
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(a)-UNIA to UNIB MAC-$l2cp_mac:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
	}



config_frame -alias ixiap2 -frametype none -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -dstmac $l2cp_mac -framesize $frame_size
config_stream -alias ixiap2 -sendmode stopstrm -pktperbst 10
clear_stat -alias allport
start_capture -alias ixiap1
send_traffic -alias ixiap2 -actiontype start
stop_capture -alias ixiap1
get_stat -alias ixiap2 -txframe ixiap2tx
get_stat -alias ixiap1 -rxframe ixiap1rx
#puts "ixiap2_tx_frame: $ixiap2tx, ixiap1_rx_frame: $ixiap1rx\n"
set getCaptured [check_capture -alias ixiap1 -dstmac $l2cp_mac]
#puts $getCaptured
#puts $sortdamac
if { $getCaptured == 10 } {
 		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  PASS\n"
	} else {
		puts "TEST CASE Option2 13.1.1(b)-UNIB to UNIA MAC-$l2cp_mac:  FAIL"
		####for debug, this action need to globle the below parameters
 		#puts "Actual Captured Frames Info: $sortdamac"
	}
}

puts "TEST CASE Option2 13.1.1 Finished\n"

puts "\nTEST CASE 25.1.1: SOAM Cases Not Support"
puts "\nTEST CASE 26.1.1: SOAM Cases Not Support"
puts "\nTEST CASE 27.1.1: SOAM Cases Not Support"
puts "\nTEST CASE 27.1.2: SOAM Cases Not Support"
puts "\nTEST CASE 28.1.1: SOAM Cases Not Support"
puts "\nTEST CASE 28.1.2: SOAM Cases Not Support"
puts "\nTEST CASE 29.1.1: SOAM Cases Not Support"
puts "\nTEST CASE 30.1.1: SOAM Cases Not Support"


puts "\n\n\nEPL Confinguration 1 Finished"