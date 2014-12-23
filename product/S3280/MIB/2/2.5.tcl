#!/bin/tcl
#Filename: 2.5.tcl
#History:
#        10/25/2013- Andy,Created
#        01/08/2014- Jefferson,Modified
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of this test case is to test ingress filtering function.

#introduction
#Enable ingress filtering on a port by checking the box. This parameter affects VLAN ingress processing. 
#If ingress filtering is enabled and the ingress port is not a member of the classified VLAN of the frame, 
#the frame is discarded. By default, ingress filtering is disabled (no checkmark). 

#precondition: all configurre should be default value except below mention.

#steps:
#1.
#2.
#3.
#4.




variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl


setToFactoryDefault $::dut

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname AutoIxia

config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode


config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate

##################################################################################################
set desc "Test 2.2.1: check ingress filtering disable"

config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid 10 -tpid 8100 -srcmac $::ixiaMac1  -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
#set port 2 to c-port
vlan::porttypeSet $::dutp1 cport
vlan::porttypeSet $::dutp2 unaware
vlan::vlanadd 10 [port2Portlist "[expr $::dutp1+3] [expr $::dutp2+4]"]
vlan::portIngressFilteringEnable $::dutp1 False


start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $ixiaMac1 -tpid 8100
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $ixiaMac1 -tpid 8100 -vlanid 10]
if { $getCaptured == $ixiap1tx } {
	passed "VLAN 2.2.1" $desc
} else {
	failed "VLAN 2.2.1" $desc
}