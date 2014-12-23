
#!/bin/tcl

#Filename: 12.1.tcl
#History:
#        1/9/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

##################DHCP Snooping###########################

#The switch filter DHCP packets when one of these situations occurs:
# 1. all ports could receive DHCP reply packets (offer,ack,nak) from trust port
# 2. only trust port could receive DHCP request packets (discover,request ,inform ,decline,release) from trust port
# 3. only trust port could receive DHCP request packets (discover,request,inform,decline,release ) from untrust port


#option 53 
#            Value   Message Type
#           -----   ------------   
#             1     DHCPDISCOVER
#             2     DHCPOFFER
#             3     DHCPREQUEST
#             4     DHCPDECLINE
#             5     DHCPACK
#             6     DHCPNAK
#             7     DHCPRELEASE
#             8     DHCPINFORM
##################DHCP Snooping###########################


#Note :The target of this test case is to test dhcp request packets (DHCP inform ) from trust port to trust or untrust port;

source ./init.tcl
set phymode $::ixiaphymode
#dut port1 connect ixia ixiap1
#dut port2 connect ixia ixiap2
set port1 $::dutp1
set port2 $::dutp2
set port3 $::dutp3

set srcmac "00 00 00 11 11 11"
set destmac "00 00 00 22 22 22"
set destBro "FF FF FF FF FF FF"


setToFactoryDefault $dut1
dhcpSnooping::setglobalMode $dut1 enable
dhcpSnooping::setportmode $dut1 $port1 trust
dhcpSnooping::setportmode $dut1 $port2 untrust
dhcpSnooping::setportmode $dut1 $port3 trust

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2,$::ixiaPort3,ixiap3 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode
config_portprop -alias ixiap3 -autonego enable -phymode $phymode

# 1. sending  DHCP inform packets from untrust port test 
#option 50,option 53 ,option 54 must be include in dhcp inform packet
config_frame -alias ixiap1 -srcmac $srcmac  -dstmac $destBro -frametype ethernetii  -framesize 800  -srcip "192.168.1.1" -dstip "255.255.255.255" -protocol dhcp  -opCode dhcpBootRequest \
 -clientIpAddr "192.168.1.1"    -option  "53,08" -dbgprt 1
config_stream -alias ixiap1 -ratemode fps -fpsrate $::ixiafpsrate
clear_stat -alias allport
start_capture -alias ixiap2
start_capture -alias ixiap3
send_traffic -alias ixiap1 -actiontype start -time 3
stop_capture -alias ixiap2 
stop_capture -alias ixiap3
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx
get_stat -alias ixiap3 -rxframe ixiap3rx
puts "IXIA $ixiap1 connect to dut trust port $port1 and send DHCP inform packets from this port "
set staixiap2 [check_capture -alias ixiap2 -srcmac $srcmac  ]
puts "IXIA $ixiap2 connect to dut untrust port $port2, received $staixiap2 dhcp inform packets  "
set staixiap3 [check_capture -alias ixiap3 -srcmac $srcmac  ]
puts "IXIA $ixiap3 connect to dut trust port $port3, received $staixiap3 dhcp inform packets  "
if { $staixiap2 == 0 && $staixiap3 != 0  } {
    passed "DHCP Snooping" "Send DHCP INFORM packets from trust port to trust or untrust port test  succeed"
} else { 
    failed  "DHCP Snooping" "Send DHCP INFORM packets from trust port to trust or untrust port test  failed"
}


clear_ownership -alias allport



