#!/bin/tcl

#Filename: 7.1.tcl
#History:
#        12/12/2013- Miles,Created
#        12/27/2013- Miles,Updated
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of following test cases  is  test lldp global parameters like tx interval ,tx hold ,tx delay ,tx reinit 

source ./init.tcl
set phymode $::ixiaphymode
#port1 that connect to IXIA port 
set port1  $::dutp1
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts " (please make sure DUT port $::dutp1 connected IXIA port $::ixiaPort1) +++++"
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
setToFactoryDefault $dut1
puts "start connect_ixia"
connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1 -alias allport -loginname AutoIxia -dbgprt 1
config_portprop -alias ixiap1 -autonego enable -phymode $phymode
#5.1.The target of this test case  is to test lldp Tx interval
#test default txInterval ( LLDP txInterval from 5 to 32768,default value is 30 )


set  mac  [string toupper [getDutMacAddr $dut1]]
set interval [lldp::gettxInterval $dut1]
set portMac [string toupper [getPortMacaddr $dut1 $port1]]
puts "DUT port $port1 mac address is:  $portMac"
clear_stat -alias allport
start_capture -alias ixiap1
lldp::setlldpportmode $dut1 $port1 TXONLY
puts "###IXIA is capturing packets ,please wait###"
after [expr $interval * 1000*6]
stop_capture -alias ixiap1 
get_stat -alias ixiap1 -rxframe ixiap1rx
set getCaptured [check_capture -alias ixiap1 -srcmac $portMac -ethertype 88CC -dbgprt 1]
puts " matched packets :$getCaptured"
if { $getCaptured == "5" || $getCaptured == "6" } {
     puts " ###Txinterval is : $interval "
       puts "### Actually in [expr $interval*5] seconds ,DUT captured 5 lldp packets ###"
       passed  txInterval "Lldp txinterval test  successed!"       
} else {
      puts  "###LLDP Txinterval is : $interval"
        puts "### Actually in [expr $interval*5] seconds ,DUT captured $getCaptured lldp packets ###"
        failed txInterval  "Lldp txinterval test  failed"    
      }

#5.2 test  a new txinterval value 10  and test it 
lldp::setlldpportmode $dut1 $port1 DISABLE
clear_stat -alias allport
start_capture -alias ixiap1
lldp::settxInterval  $dut1 10
set interval [lldp::gettxInterval $dut1]
lldp::setlldpportmode $dut1 $port1 TXONLY
puts "###IXIA is capturing packets ,please wait###"
after [expr $interval * 1000*6]
stop_capture -alias ixiap1 
get_stat -alias ixiap1 -rxframe ixiap1rx
set getCaptured [check_capture -alias ixiap1 -srcmac $portMac -ethertype 88CC ]
set filtervalue [format %d $getCaptured]
puts "filetered value is $filtervalue"
puts " matched packets :$getCaptured"
if { $filtervalue == 5 || $filtervalue == 6  } {
     puts " ###Txinterval is : $interval "
       puts "### Actually in [expr $interval*5] seconds ,DUT captured $getCaptured lldp packets ###"
       passed  txInterval "Lldp txinterval test is successed！"
       
} else {
      puts  "###LLDP Txinterval is : $interval"
        puts "### Actually in [expr $interval*5] seconds ,DUT captured $getCaptured lldp packets ###"
        failed txInterval  "Lldp txinterval test  is faile" 
        
      }

#5.3  lldp tx hold test 
#test measure: check ixia could capture lldp packets with you configured txhold  or not 
clear_stat -alias allport
lldp::settxInterval $dut1 $port1
lldp::settxHold $dut1 10
lldp::setlldpportmode $dut1 $port1 TXANDRX
start_capture -alias ixiap1
after 30000
stop_capture -alias ixiap1 
get_stat -alias ixiap1 -rxframe ixiap1rx
set getCaptured [check_lldppacket -alias ixiap1  -ethertype 88CC -hold 0032 -dbgprt 1]
puts " matched packets :$getCaptured"
if { $getCaptured !=0 } {
       passed  txhold "Lldp txhold test  successed"
} else {
        failed txhold  "Lldp txhold test  failed" 
    }

#5.4 lldp tx delay test
#If some configuration is changed (e.g. the IP address) a new LLDP frame is transmitted, 
#but the time between the LLDP frames will always be at least the value of Tx Delay seconds.
#Tx Delay cannot be larger than 1/4 of the Tx Interval value. Valid values are restricted to 1 - 8192 seconds. 
clear_stat -alias allport
lldp::settxInterval $dut1 1000
lldp::settxdelay  $dut1 10
lldp::setlldpportmode $dut1 $port1 TXANDRX
start_capture -alias ixiap1
#change sysname for 4 times ,dut will not wait lldp txinterval ,which will send lldp packets every tx delat interval 
for {set i  1} {$i <= 4 } {incr i} {

  lldp::setsystmName  $dut1  [join "miles $i" "" ]
}
after [expr 4*10]
#after 4*tx delay interval ,check captured lldp packets ,it should capture 4 lldp packets in 40s.
stop_capture -alias ixiap1 
get_stat -alias ixiap1 -rxframe ixiap1rx
set getCaptured [check_lldppacket -alias ixiap1  -ethertype 88CC  -dbgprt 1]
puts " matched packets :$getCaptured"
if { $getCaptured == 4 } {
         puts "IXIA captured $getCaptured lldp packets "
       passed  txdelay "Lldp txdelay test  successed"       
} else {
         puts "system name has changed 4 times ,but dut only send $getCaptured lldp packets"
        failed txdelay  "Lldp txdelay test  failed"     
    }

#5.5 tx reinit test 
#When a port is disabled, LLDP is disabled or the switch is rebooted, 
#an LLDP shutdown frame is transmitted to the neighboring units, 
#signalling that the LLDP information isn't valid anymore. 
#Tx Reinit controls the amount of seconds between the shutdown frame and a new LLDP initialization. 
#Valid values are restricted to 1 - 10 seconds. 

clear_stat -alias allport
lldp::settxInterval $dut1 10
lldp::settxHold  $dut1 2
lldp::settxReinit $dut1 10
lldp::setlldpportmode $dut1 $port1 TXANDRX
after 10000
lldp::setlldpportmode $dut1 $port1 Disable
after 1000
lldp::setlldpportmode $dut1 $port1 TXANDRX
start_capture -alias ixiap1
after 25000
stop_capture -alias ixiap1 
get_stat -alias ixiap1 -rxframe ixiap1rx
set getCaptured [check_lldppacket -alias ixiap1  -ethertype 88CC -hold 0014 -dbgprt 1]
puts " matched packets :$getCaptured"
#in 20s dut only send one lldp packet although txinterval is 10s,because another 10s is reinint interval,
#init lldp module will cost 10s when port mode changed from disable to enable
if { $getCaptured == 1 } {
      puts "IXIA captured $getCaptured lldp packets "
       passed  txreinit "Lldp txReinittest  successed"
      
} else {
      puts "IXIA captured $getCaptured lldp packets "
        failed txreinit  "Lldp txReinit test  failed" 
    }
clear_ownership -alias allport