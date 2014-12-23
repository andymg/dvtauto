#!/bin/tcl

#Filename: 7.5.tcl
#History:
#        12/27/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Note:the target of following test cases are 
source ./init.tcl

#port means dut port that connected to ixia 
set port  $::dutp1
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts " (please make sure DUT port $::dutp1 connected IXIA port $::ixiaPort1) +++++"
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"


setToFactoryDefault $dut1
lldp::setlldpportmode $dut1 $port DISABLE
lldp::setlldpportmode $dut1 $port TXANDRX
set phymode $::ixiaphymode





#.1 enable lldp CDP aware test 
#test CDP packets from CISOC-3750

lldp::setCDPaware $dut1 $port enable
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode

###import CDP packet to ixia
config_frame -alias ixiap1 -import  CDP.enc
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 2
set RemchaID [lldp::walkRemChassisID $dut1]
set CDPchaID [string toupper $RemchaID]
puts "CISCO 3750 CDP packet's Device ID(Chassis ID) is : CS3750"
if {[string equal "CS3750" $CDPchaID]} {
    passed  "CDP aware "   "Enable DUT $dut1 port $port LLDP CDP(CISCO-3750-CDP packet) aware test success"
} else {
    failed  "CDP aware "   "Enable DUT $dut1 port $port LLDP CDP(CISCO-3750-CDP packet) aware test failed"	
}


#.2 enable lldp CDP aware test 
lldp::setlldpportmode $dut1 $port DISABLE
lldp::setlldpportmode $dut1 $port TXANDRX
lldp::setCDPaware $dut1 $port enable
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode

###import CDP packet to ixia
config_frame -alias ixiap1 -import  BCMCDP.enc
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 2
set RemchaID [lldp::walkRemChassisID $dut1]
set CDPchaID [string toupper $RemchaID]
#BCMCDP packet's DEVICE ID (chassis ID) is 0060b9c14027
puts "CISCO BCM91100 CDP packet's Device ID (chassis ID)is : 0060b9c14027"
if {[string equal "0060b9c14027" $CDPchaID]} {
    passed  "CDP aware "   "Enable DUT $dut1 port $port LLDP CDP(CISCO-BCM91100-CDP packet) aware test success"
} else {
    failed  "CDP aware "   "Enable DUT $dut1 port $port LLDP CDP(CISCO-BCM91100-CDP packet) aware test failed"	
}

#.3 disable lldp CDP aware test 

lldp::setCDPaware $dut1 $port disable
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode

###import CDP packet to ixia
config_frame -alias ixiap1 -import  CDP.enc
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
send_traffic -alias ixiap1 -actiontype start -time 2
set RemchaID [lldp::walkRemChassisID $dut1]
set CDPchaID [string toupper $RemchaID]
if {[string equal "CS3750" $CDPchaID] != 1} {
    passed  "CDP aware "   "Disable DUT $dut1 port $port LLDP CDP aware test success"
} else {
    failed  "CDP aware "   "Disable DUT $dut1 port $port LLDP CDP aware test failed"	
}

clear_ownership -alias allport