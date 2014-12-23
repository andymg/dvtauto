#!/bin/sh
#\
exec tclsh "$0" "$@"

#Filename: 200.3.tcl
#History:
#        10/30/2013- Jefferson,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:

#by default:
#************DUT1 parameters***********
#vlan remove 1 1-4 
#vlan porttype 1 s-port
#vlan porttype 2-4 c-port
#evc add 1 11 11 1 
#evc ece add 1 uni 3 evc 1
#***************************************

#************DUT2 parameters***********
#vlan remove 1 1-4
#vlan porttype 1 s-port
#vlan porttype 2-4 c-port
#evc add 1 11 11 1
#evc ece add 1 uni 3 evc 1
#***************************************
#******************************************************************************************************************************************

source ./init.tcl

set evc_vid 11
set aftertime 100000

proc configCommands {evc_vid spawnIDa spawnIDb} {
    
	set max_port_list all
	set default_vid 1
	set dut_lnk_pt 1
	set eqpt_lnk_pt "2-4"
	set out_port_type "s-port"
	set in_port_type "c-port"
	set evc_id 1
	#set evc_vid 11
	set evc_ivid 11
	set nni_list 1
	set ece_id 1
	set uni_list 3
	set map_evc "nni"
	
	foreach id "$spawnIDa $spawnIDb" {
	#VLAN remove <vid>|<name> [<port_list>]
	    exp_send -i $id "vlan remove $default_vid $max_port_list\r"
        expect -i $id ">"
	#VLAN PortType [<port_list>] [unaware|c-port|s-port|s-custom-port]
	    exp_send -i $id "vlan porttype $dut_lnk_pt $out_port_type\r"
        expect -i $id ">"
	    exp_send -i $id "vlan porttype $eqpt_lnk_pt $in_port_type\r"
        expect -i $id ">"
	#EVC Add <evc_id> [<vid>] [<ivid>] [<nni_list>] [<learning>] [<policer_id>]
	    exp_send -i $id "evc add $evc_id $evc_vid $evc_ivid $nni_list\r"
        expect -i $id ">"
	#EVC ECE Add [<ece_id>] [<ece_id_next>] [uni] [<uni_list>] [tag] [<tag_type>] [<vid>] [<pcp>] [<dei>] [intag] [<in_type>] [<in_vid>] [<in_pcp>] [<in_dei>]\
	[all | (ipv4 [<dscp>]) | (ipv6 [<dscp>])] [direction] [<direction>] [evc] [<evc_id>] [<policer_id>]\
	[pop] [<pop>] [policy] [<policy>] \
	[outer] [<ot_mode>] [<ot_vid>] [<ot_preserve>] [<ot_pcp>] [<ot_dei>] \
	[inner] [<it_type>] [<it_vid>] [<it_preserve>] [<it_pcp>] [<it_dei>]
	
	    exp_send -i $id "evc ece add $ece_id uni $uni_list evc $evc_id\r"
        expect -i $id ">"
	}
	exp_send -i $id "logout\r"
    catch {exp_close -i $id}
}

mef::chkDutConnect $cfg::DUT1(IP) $cfg::DUT2(IP)

setToFactoryDefault $cfg::DUT1(IP)
setToFactoryDefault $cfg::DUT2(IP)

mef::chkDutConnect $cfg::DUT1(IP) $cfg::DUT2(IP)

mef::loginSystem $cfg::DUT1(IP) $cfg::DUT2(IP)

mef::chkSystemVersion

configCommands $evc_vid $::spawnIDa $::spawnIDb

set phymode "fiber"
set tpid 8100
set frame_size 68
set ixia_rate 1

set unicast_a "00:00:00:00:11:11"
set unicast_b "00:00:00:00:22:22"

#this case only use one EQPT1, so just consider two ports in ixia to connect another two in DUT1 and DUT2
connect_ixia -ipaddr $cfg::EQPT1(IP) -portlist [lindex $topo::EQPT1 0],ixiap1,[lindex $topo::EQPT1 1],ixiap2 -alias allport -loginname AutoIxia

config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

puts "######################### EPL Configuration 1 of 8 | Test Cases for Basic Service Attributes 1 of 3 ############################"
puts "######################### NON-LOOPING FRAME DELIVERY #########################"
puts "######################TEST OBJECT  Determine if a MEN forwards frames to the UNI from which they originated######################"
puts "######################TEST STATUS  Mandatory###########################"
puts "#########TEST DIRECTION  Bi-directional (test frames transmitted from every UNI to every other UNI in the EVC#########"
puts "TEST CASE 1.1.3"

#first to learn mac-address each other due to p2p
config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -srcmac $unicast_a -dstmac $unicast_b -framesize $frame_size
config_stream -alias ixiap1 -ratemode fps -fpsrate $ixia_rate

config_frame -alias ixiap2 -frametype ethernetii -vlanmode singlevlan -vlanid $evc_vid -tpid $tpid -srcmac $unicast_b -dstmac $unicast_a -framesize $frame_size
config_stream -alias ixiap2 -ratemode fps -fpsrate $ixia_rate

send_traffic -alias ixiap1 -actiontype start -time 3
send_traffic -alias ixiap2 -actiontype start -time 3

clear_stat -alias allport

#start to test
after $aftertime

start_capture -alias ixiap1
start_capture -alias ixiap2

send_traffic -alias ixiap1 -actiontype start -time 3
send_traffic -alias ixiap2 -actiontype start -time 3

stop_capture -alias ixiap1
stop_capture -alias ixiap2

#ixiap1tx,ixiap2rx is output parameters.
#ixiap1tx/rx means count.

get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"

set getCaptured [check_capture -alias ixiap2 -srcmac $unicast_a -dstmac $unicast_b -tpid $tpid -vlanid $evc_vid]

if { $getCaptured == 0 } {
	puts "PASS"
} else {
	puts "FAIL"
}


get_stat -alias ixiap1 -rxframe ixiap1rx
get_stat -alias ixiap2 -txframe ixiap2tx

puts "ixiap1_tx_frame: $ixiap1rx, ixiap2_rx_frame: $ixiap2tx"

set getCaptured [check_capture -alias ixiap1 -srcmac $unicast_b -dstmac $unicast_a -tpid $tpid -vlanid $evc_vid]

if { $getCaptured == 0 } {
	puts "PASS"
} else {
	puts "FAIL"
}

puts "################# TEST CASE 1.1.3 Finished ####################"