
#!/bin/tcl

#Filename: 5.1.tcl
#History:
#        12/12/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes: the target of following test cases is test lldp optiona TLV :Mgmt Addr



source ./init.tcl
set port1 $::dutp3
set port2 $::dutp4
#5.15 select port Man Add TLV
lldp::selectportManTLV $dut1 $dut2 $port2 03C0
#5.16 Din't select port Man Add TLV
lldp::NotselectportManTLV $dut1 $dut2 $port2 00C0