#!/bin/tcl

#Filename: 2.1.tcl
#History:
#        10/24/2013- Andy,Created
#        01/08/2014- Jefferson, Modified
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of this test case is to test if c-port can work well or not?

#precondition: all configurre should be default value except below mention.

#steps:
#1.when vlan=1 by default, send untag packets and check its result.
#2.when vlan=1 by default, send priority-vlan with different TPID,CFI and VID,to check its result.
#3.when vlan=1 by default, send singlevlan with different TPID,CFI and VID, to check its result.
#4.when vlan=1 by default, send doublevlan with different TPID,CFI and VID, to check its result.


variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl

setToFactoryDefault $::dut

set prtyp "cport"

vlan::porttypeSet $::dutp1 $prtyp

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 -alias allport -loginname vlanixia

config_portprop -alias ixiap1 -autonego enable -phymode $::phymode
config_portprop -alias ixiap2 -autonego enable -phymode $::phymode

proc sendReceive { vid tpid srcmac rate name desc {mark default} } {
    
    set cfi 0 ;# [expr int(rand()*2)]

    config_frame -alias ixiap1 -frametype ethernetii -vlanmode singlevlan -vlanid $vid -tpid $tpid -srcmac $srcmac -framesize 100
    config_stream -alias ixiap1 -ratemode fps -fpsrate $rate
    clear_stat -alias allport

    start_capture -alias ixiap2
    send_traffic -alias ixiap1 -actiontype start -time 2

    stop_capture -alias ixiap2 -framedata frameData -srcmac $srcmac -tpid $tpid
    get_stat -alias ixiap1 -txframe ixiap1tx
    get_stat -alias ixiap2 -rxframe ixiap2rx

    puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
    set getCaptured [check_capture -alias ixiap2 -srcmac $srcmac -tpid $tpid -vlanid $vid]

    switch mark {
       1    {
                if { $getCaptured ==0 } { 
                    if { $tpid == 88a8 } {
                       failed $name $desc
                    } else {
                       passed $name $desc
                    }
                } else {
                    if { $tpid == 8100 } {
                       failed $name $desc
                    } else {
                       passed $name $desc
                    }
                }
            }

        2   {
                if { $getCaptured == 0 } {
                    failed $name $desc
                } else {
                    passed $name $desc
                }
            }

    default {
                if { $getCaptured == 0 } {
                    passed $name $desc
                } else {
                    failed $name $desc
                }
            }

    }
    
}

#-------send untag packets
set name "None VLAN Field"
set desc "send untag packets to check receive packet type when Port Type is c-port"

config_frame -alias ixiap1 -frametype ethernetii -srcmac $srcmac -framesize 100
config_stream -alias ixiap1 -ratemode fps -fpsrate $rate
clear_stat -alias allport

start_capture -alias ixiap2
send_traffic -alias ixiap1 -actiontype start -time 2

stop_capture -alias ixiap2 -framedata frameData -srcmac $srcmac
get_stat -alias ixiap1 -txframe ixiap1tx
get_stat -alias ixiap2 -rxframe ixiap2rx

puts "ixiap1_tx_frame: $ixiap1tx, ixiap2_rx_frame: $ixiap2rx"
set getCaptured [check_capture -alias ixiap2 -srcmac $srcmac]
if { $getCaptured == 0} {
	passed $name $desc
} else {
	failed $name $desc
}


#------send singlevlan + priority-vlan packets-----------------------
foreach vid { 0 1 } {
    foreach id {8100 88a8 9100 9200} {
        set name "VLAN ID is $vid, TPID is $id"
        set desc "send Tag $vid to check receive VLAN Tag when Port Type is c-port"
        set mark 1 
        sendReceive $vid $id $::ixiaMac1 $::ixiarate $name $desc $mark
	}
}

#---send user-defined vlan id, it doesn't add any port list
set vid [expr int(rand()*4093+2)]

foreach id {8100 88a8 9100 9200} {
    set name "VLAN ID is $vid, TPID is $id, it doesn't add any port list"
    set desc "send Tag $vid to check receive VLAN Tag when Port Type is c-port"
    set mark 2
    sendReceive $vid $id $::ixiaMac1 $::ixiarate $name $desc $mark
}

#----user-defined vlan id, it added some port list
vlan::vlanadd $vid [port2Portlist "$::dutp1 $::dutp2"]
set vid [expr int(rand()*4093+2)]

foreach vid { 0 1 } {
    foreach id {8100 88a8 9100 9200} {
        set name "VLAN ID is $vid, TPID is $id"
        set desc "send Tag $vid to check receive VLAN Tag when Port Type is c-port"
        set mark 1 
        sendReceive $vid $id $::ixiaMac1 $::ixiarate $name $desc $mark
	}
}


#send doubletag packets, it will be developed in the future

clear_ownership -alias allport