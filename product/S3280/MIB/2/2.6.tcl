#!/bin/tcl
#Filename: 2.6.tcl
#History:
#        11/01/2013- Andy,Created
#        01/08/2014- Jefferson,Modified
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of this test case is to test "Frame Type"

#introduction:
#Determines whether the port accepts all frames or only tagged/untagged frames. 
#This parameter affects VLAN ingress processing. If the port only accepts tagged frames, untagged frames received on the port are discarded. 
#By default, the field is set to All. 

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

###################################################################
set description "Test 2.3.1: check ingress Frame type tagged mode"
# taged vlan 10 --------->> dutp1 unaware FrameType tagged --->dutp2 unaware FrameType all ----->> tagged vlan  10

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portFrametypeSet $::dutp1 tagged


start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -tpid 8100]
if { $getCaptured == 0 &&  $ixiap2rx > 0} {
	passed "VLAN 2.3.1" $description
} else {
	failed "VLAN 2.3.1" $description
}
##############################################################################
set description "Test 2.3.2: check ingress Frame type untagged mode "
# taged vlan 10 --------->> dutp1 unaware FrameType untagged --->dutp2 unaware FrameType all ----->> 0 tagged

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portFrametypeSet $::dutp1 untagged


start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -tpid 8100 ]
if { $getCaptured == 0} {
	passed "VLAN 2.3.2" $description
} else {
	failed "VLAN 2.3.2" $description
}

############################################################################
set description "Test 2.3.3: check ingress Frame type all mode "
# taged vlan 10 --------->> dutp1 unaware FrameType tagged --->dutp2 unaware FrameType all ----->> tagged vlan  10

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 unaware
vlan::porttypeSet $::dutp2 unaware
vlan::portFrametypeSet $::dutp1 all

vlan::portIngressFilteringEnable $::dutp1 False


start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $ixiaMac1 -tpid 8100 -vlanid 10]
if { $getCaptured == $ixiap1tx && $getCaptured < $ixiap2rx } {
	passed  "VLAN 2.3.3" $description
} else {
	failed  "VLAN 2.3.3" $description
}