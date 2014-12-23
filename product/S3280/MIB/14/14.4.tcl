
#!/bin/tcl

#Filename: 14.4.tcl
#History:
#        1/14/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

##################Ip Source Guard introduction###########################
#IP traffic is filtered based on the source IP and MA C addresses. The switch forwards traffic only when 
#the source IP and MAC addresses match an entry in the IP source binding table
##################Ip Source Guard introduction###########################tnIPSourceGuardIfMaxDynamicClients(oid)
#Notes:Ip Source Guard static binding table test 


source ./init.tcl
set phymode $::ixiaphymode
#dut port1 connect ixia ixiap1
#dut port2 connect ixia ixiap2
set port1 $::dutp1
set port2 $::dutp2
setToFactoryDefault $dut1
after 1000
IPSG::setglobalMode $dut1 enable
IPSG::setportMode $dut1  $port1 enable
IPSG::setportMode $dut1  $port2 disable


set srcMac "00 14 22 8c 3b b9 "
set destMac "00 00 00 44 44 44"
set sendIp "192.168.100.2"
set targIp "192.168.100.1"
set ethtype ethernetii

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport  -loginname miles   -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode


#without any static binding table
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
set a $getCaptured
puts "get captured $a"

#create a static binding table
IPSG::createStaticTable $dut1  $port1 1  0014228c3bb9 192.168.100.2
IPSG::walkStatictable $dut1
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
set b $getCaptured
puts "get captured $b"
if { $a == 0 && $b != 0 } {
	puts "DUT forwards $a IP packets when Ip Source Guard static table is empty"
	puts "DUT forwards $b IP packets when IP packets meatched the static table"
    passed  "Ip Source Guard" "Ip Source Guard  static binding table test succeed"
} else { 
	puts "DUT forwards $a IP packets when Ip Source Guard static table is empty"
	puts "DUT forwards $b IP packets when IP packets meatched the static table"
    failed  "Ip Source Guard" "Ip Source Guard  static binding table test  failed"
}
clear_ownership -alias allport