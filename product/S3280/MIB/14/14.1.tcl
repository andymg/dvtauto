#Filename: 14.1.tcl
#History:
#        1/14/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

##################Ip Source Guard introduction###########################
#IP traffic is filtered based on the source IP and MA C addresses. The switch forwards traffic only when 
#the source IP and MAC addresses match an entry in the IP source binding table
##################Ip Source Guard introduction###########################tnIPSourceGuardIfMaxDynamicClients(oid)
#Notes:IPSG port mode  test 


source ./init.tcl
set phymode $::ixiaphymode
#dut port1 connect ixia ixiap1
#dut port2 connect ixia ixiap2
set port1 $::dutp1
set port2 $::dutp2
setToFactoryDefault $dut1
after 1000
setToFactoryDefault $dut1
puts "start connect_ixia"
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode

set srcMac "00 00 00 33 33 33"
set destMac "00 00 00 44 44 44"
set sendIp "192.168.1.1"
set targIp "192.168.1.2"
set ethtype ethernetii



#1.port mode enable test 
IPSG::setglobalMode $dut1 enable
IPSG::setportMode $dut1  $port1 enable
IPSG::setportMode $dut1  $port2 disable

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac -frametype $ethtype -srcip $sendIp -dstip $targIp   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destMac  ]
puts "get captured $getCaptured"
if { $getCaptured == 0 } {
    passed  "Ip Source Guard" "Ip Source Guard  port mode  enable test succeed"
} else { 
    failed  "Ip Source Guard" "Ip Source Guard  port mode enable  test failed"
}

#2.port mode disable test 
IPSG::setglobalMode $dut1 enable
IPSG::setportMode $dut1  $port1 disable
IPSG::setportMode $dut1  $port2 disable

config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destMac -frametype $ethtype -srcip $sendIp -dstip $targIp   -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2
stop_capture -alias ixiap2 
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcMac -dstmac $destMac  ]
puts "get captured $getCaptured"
if { $getCaptured != 0 } {
    passed  "Ip Source Guard" "Ip Source Guard   port mode  disable test succeed"
} else { 
    failed  "Ip Source Guard" "Ip Source Guard  port mode disable  test failed"
}
clear_ownership -alias allport