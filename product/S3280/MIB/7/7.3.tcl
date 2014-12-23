
#!/bin/tcl

#Filename: 5.1.tcl
#History:
#        12/12/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes: the target of following test cases is test lldp optional TLV ,which include Port Descr	,
#Sys Name,	Sys Descr,Sys Capa 
source ./init.tcl
set port1 $::dutp3
set port2 $::dutp4
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts "++++(please make sure dut1 port $port1 connected dut2 port $port2)+++++"
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#port2 that  connect two duts 
#5.9 lldp optional TLV ----Sys Capa
lldp::checkportOptionalTLV $dut1 $dut2 $port2 10
#5.10 lldp optional TLV ----Sys Descr
lldp::checkportOptionalTLV $dut1 $dut2 $port2 20
#5.11 lldp optional TLV ----Sys Name
lldp::checkportOptionalTLV $dut1 $dut2 $port2 40
#5.12 lldp optional TLV ----Port Descr
lldp::checkportOptionalTLV $dut1 $dut2 $port2 80
#5.13 Didn't select all lldp optional TLV except Man Add 
lldp::checkportOptionalTLV $dut1 $dut2 $port2 00
#5.14 select all lldp optional TLV except Man Add 
lldp::checkportOptionalTLV $dut1 $dut2 $port2 F0