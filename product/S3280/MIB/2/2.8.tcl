#!/bin/tcl
#Filename: 2.8.tcl
#History:
#        10/31/2013- Andy,Created
#        01/08/2014- Jefferson,Modified
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of this test case is to test port "TX Tag"

#introduction
#Determines egress tagging of a port. Untag_pvid - All VLANs except the configured PVID will be tagged. 
#Tag_all - All VLANs are tagged. Untag_all - All VLANs are untagged. 

#precondition: all configurre should be default value except below mention.

#steps:
#1.
#2.
#3.



variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl


setToFactoryDefault $::dut

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname AutoIxia

config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode


config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate

##################################################################################
set description "Test 2.4.1: check Port VID with untag_pvid != outer tag"
# taged vlan 10 --------->> dutp1 unaware FrameType all, PVID 2 --->dutp2 unaware,tx untag_pvid, PVID5 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 5
vlan::portTxTagSet $::dutp2 UNTAGPVID
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 2]
if { $getCaptured == $ixiap1tx} {
	passed "VLAN 2.4.1" $description
} else {
	failed "VLAN 2.4.1" $description
}

#############################################################################################
set description "Test 2.4.2: check Port VID with untag_pvid == outer tag"
# taged vlan 10 --------->> dutp1 unaware FrameType all, PVID 2 --->dutp2 unaware,tx untag_pvid, PVID5 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 2
vlan::portTxTagSet $::dutp2 UNTAGPVID
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 10]
if { $getCaptured == $ixiap1tx} {
	passed "VLAN 2.4.2" $description
} else {
	failed "VLAN 2.4.2" $description
}

set description "Test 2.4.3: check Egress Port VID with tagall"

puts "######################### $description ############################"
# taged vlan 10 --------->> dutp1 unaware FrameType all, PVID 2 --->dutp2 unaware,tx untag_pvid, PVID5 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 2
vlan::portTxTagSet $::dutp2 tagall
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 2 -innervlanid 10]
if { $getCaptured == $ixiap1tx} {
	passed "VLAN 2.4.3" $description
} else {
	failed "VLAN 2.4.3" $description
}

#############################################################################
set description "Test 2.4.4: check Egress Port VID with untagall"
# taged vlan 10 --------->> dutp1 unaware FrameType all, PVID 2 --->dutp2 unaware,tx untag_pvid, PVID5 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 2
vlan::portTxTagSet $::dutp2 untagall
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
#Egress packets with one tag as ingress 
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 10 ]
if { $getCaptured == $ixiap1tx} {
	passed "VLAN 2.4.4" $description
} else {
	failed "VLAN 2.4.4" $description
}

#####################################################################################
set description "Test 2.4.5: check Egress Port VID with untagall, the Egress PVID != Ingress PVID"
# taged vlan 10 --------->> dutp1 unaware FrameType all, PVID 2 --->dutp2 unaware,tx untag_pvid, PVID5 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 5
vlan::portTxTagSet $::dutp2 untagall
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
#Egress packets with one tag as ingress 
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 10 ]
if { $getCaptured == $ixiap1tx} {
	passed "VLAN 2.4.5" $description
} else {
	failed "VLAN 2.4.5" $description
}

#################################################################
set description "Test 2.4.6: check Egress Port VID with untagall, the Egress PVID != Ingress PVID"
# taged vlan 10 --------->> dutp1 unaware FrameType all, PVID 2 --->dutp2 unaware,tx untag_pvid, PVID5 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 2
vlan::portTxTagSet $::dutp2 untagall
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
#Egress packets with one tag as ingress 
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 2 ]
if { $getCaptured == 0 } {
	passed "VLAN 2.4.6" $description
} else {
	failed "VLAN 2.4.6" $description
}
##############################################################################################
set description "Test 2.4.7: check Egress Port VID with tagall, the Egress PVID != Ingress PVID"
# no tagged packet --------->> dutp1 cport FrameType all, PVID 5 --->dutp2 unaware,tx untag_pvid, PVID2 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 cport
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 5
vlan::portVlanSet $::dutp2 2
vlan::portTxTagSet $::dutp2 tagall
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]
vlan::vlanadd 5 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
#Egress packets with one tag as ingress 
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 5 ]
if { $getCaptured == $ixiap1tx } {
	passed "VLAN 2.4.7" $description
} else {
	failed "VLAN 2.4.7" $description
}

######################################################################################
set description "Test 2.4.8: check Egress Port VID with untag_pvid, the Egress PVID == Ingress PVID"
# no tagged packet --------->> dutp1 cport FrameType all, PVID 5 --->dutp2 unaware,tx untag_pvid, PVID2 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 cport
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 5
vlan::portVlanSet $::dutp2 5
vlan::portTxTagSet $::dutp2 untagpvid
vlan::vlanadd 5 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
#Egress packets with one tag as ingress 
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 5 ]
set getCaptured2 [check_capture -alias ixiap2 -srcmac $ixiaMac1 ]
if { $getCaptured == 0 && $getCaptured2 ==  $ixiap1tx } {
	passed "VLAN 2.4.8" $description
} else {
	failed "VLAN 2.4.8" $description
}

##########################################################################################
set description "Test 2.4.9: check Egress Port VID with untagall, the Egress PVID == Ingress PVID"
# no tagged packet --------->> dutp1 cport FrameType all, PVID 5 --->dutp2 unaware,tx untag_pvid, PVID2 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 cport
vlan::porttypeSet $::dutp2 unaware
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 5
vlan::portTxTagSet $::dutp2 untagall
vlan::vlanadd 5 [port2Portlist "$::dutp1 $::dutp2"]
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
#Egress packets with one tag as ingress 
set getCaptured [check_capture -alias ixiap2 -tpid 8100 -srcmac $ixiaMac1 -vlanid 2 ]
set getCaptured2 [check_capture -alias ixiap2 -srcmac $ixiaMac1 ]
if { $getCaptured == 0 && $getCaptured2 ==  $ixiap1tx } {
	passed "VLAN 2.4.9" $description
} else {
	passed "VLAN 2.4.9" $description
}

################################################################################################
set description "Test 2.4.10: check Egress Port VID with TAGALL, the Egress PVID != Ingress PVID"
# no tagged packet --------->> dutp1 cport FrameType all, PVID 5 --->dutp2 unaware,tx untag_pvid, PVID2 ----->> 

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 2 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 cport
vlan::porttypeSet $::dutp2 sport
vlan::portVlanSet $::dutp1 2
vlan::portVlanSet $::dutp2 5
vlan::portTxTagSet $::dutp2 tagall
vlan::vlanadd 5 [port2Portlist "$::dutp1 $::dutp2"]
vlan::vlanadd 2 [port2Portlist "$::dutp1 $::dutp2"]

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 88A8
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
#Egress packets with one tag as ingress 
set getCaptured [check_capture -alias ixiap2 -tpid 88A8 -srcmac $ixiaMac1 -vlanid 2 ]
set getCaptured2 [check_capture -alias ixiap2 -srcmac $ixiaMac1 ]
if { $getCaptured ==  $ixiap1tx } {
	passed "VLAN 2.4.10" $description
} else {
	failed "VLAN 2.4.10" $description
}