#!/bin/tcl

#Filename: 41.1.tcl
#History:
#        12/23/2013- Madeline,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of test cases is to config private vlan

#steps:
#1.
variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
source $path/init.tcl
setToFactoryDefault $::dut
set vid 1.1
set a 0x11
pvlan::enableportpvlan $vid $dut $a
#set 

# set PortMemb [pvlan::pvlanmp $dut]
# set portMac [string toupper [getPortMacaddr $dut $port1]]
# puts "DUT port $port1 mac address is:  $portMac"
# #select port 
# pvlan::pvlanmp $port $enable $dut1 c0
# puts $port 
