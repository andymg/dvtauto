#!/bin/tcl

#Filename: 15.1.tcl
#History:
#        15/1/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

##################DHCP relay###########################

#1.In order to DHCP information work well ,dhcp relay must be enabled and relay server ip address must be the DHCP server ip address
#2.option 82 will be insereted into dhcp packets when relay information was enabled
#3.DHCP request packets that including option 82 will be filtered by Relay information policy when relay information option is enabled
#4.DHCP request packets that   including option 82 will be dropped  when relay information option is disabled
#5.DHCP request packets that doesn't  including option 82 will be forwarded  when relay information option is disabled
##################DHCP relay###########################


source ./init.tcl

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "DHCP RELAY MIB has some problems ,I will update test case when MIB was verified"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"