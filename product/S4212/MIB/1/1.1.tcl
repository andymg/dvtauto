#!/bin/tcl
#fine ipmc_test1
#purpose :check basic function of ipmc
#Steps:
#1. Set device setToFactoryDefault
#2. Enable IGMP
#3. Create new vlan item
#4. Send IGMP report packet to Port1
#5. Check Group info to check the group list
#6. Send IGMP leve packet to Port1
#7. Check the Group info to verify whether the group is removed

#setToFactoryDefault $::dut

#import private module
#source 

set ::dutP1 1
set ::dutP2 2
set ::ixiaMac1 "01 00 5e 00 00 05"
set ::ixiaMac2 "00 00 00 00 00 02"
set ::ixiaMac3 "00 00 00 00 5e 05"
set ::ixiaFrameSize 100
set ::ixiaSendRate 100
set ::ixiaRunTime 1
set ::testerName fieldt

ipmc::ipmcSnoopingEnable IGMP False
after 3000
ipmc::ipmcSnoopingEnable IGMP True
ipmc::vlanSnoopingAdd IGMP 100 True

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname andyIxia
config_portprop -alias ixiap1 -autonego enable -phymode fiber
config_portprop -alias ixiap2 -autonego enable -phymode fiber

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype v2report -groupip 228.0.0.9
#config_portprop -alias ixiap3 -autonego enable -phymode copper
	
#config_frame -alias ixiap2 -srcmac $::ixiaMac2 -dstmac $::ixiaMac3 -framesize $::ixiaFrameSize
config_stream -alias ixiap1 -sendmode stopstrm  -pktperbst 1 -ratemode fps -fpsrate 1
#config_frame -alias ixiap1 -vlanmode none -srcmac "33 00 00 00 05 08" -dstmac $::ixiaMac1 -framesize $::ixiaFrameSize
send_traffic -alias ixiap1 -actiontype start
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype v2report -groupip 228.0.0.15
send_traffic -alias ixiap1 -actiontype start
set group1 [ipmc::ipmcGroupGet]
if {[llength $group1] == 2} {puts "Step1: v2report IGMP added check successed"}

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype v2report -groupip 228.0.0.16
send_traffic -alias ixiap1 -actiontype start

config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype v2report -groupip 228.0.0.18
send_traffic -alias ixiap1 -actiontype start
set groups [ipmc::ipmcGroupGet]
if {[llength $groups] == 4} {puts "Step2: v2report IGMP four group added successed"}

#enable fast leave on ::dutP1
ipmc::ipmcFastLeaveEnable IGMP $::dutP1 True
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype leave -groupip 228.0.0.9
send_traffic -alias ixiap1 -actiontype start
set groups [ipmc::ipmcGroupGet]
if {[llength $groups] == 3} {puts "Step3: v2report IGMP fast leave check passed"}

ipmc::ipmcFastLeaveEnable IGMP $::dutP1 False
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype leave -groupip 228.0.0.15
send_traffic -alias ixiap1 -actiontype start
set groups [ipmc::ipmcGroupGet]
if {[llength $groups] == 3} {puts "Step4: v2report IGMP leave passed when fast leave is disabled"}
after 5000

set groups [ipmc::ipmcGroupGet]
if {[llength $groups] == 2} {puts "Step5: after 5000,v2report IGMP leave passed"}

#set port 2 to router port
ipmc::ipmcRouterPortSet IGMP $::dutP2 True

start_capture -alias ixiap2
after 500
config_frame -alias ixiap1 -frametype ethernetii -vlanmode none -srcmac $::ixiaMac3 -dstmac $::ixiaMac1 -srcip 192.168.3.66 -dstip 225.0.0.5 -igmptype leave -groupip 228.0.0.18
send_traffic -alias ixiap1 -actiontype start
after 1000
stop_capture -alias ixiap2 -framedata frameData
puts "frameData is\n $frameData"
