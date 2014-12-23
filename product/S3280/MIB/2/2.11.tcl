#!/bin/tcl
#Filename: 2.11.tcl
#History:
#        01/08/2014- Jefferson,Created
#Copyright(c): Transition Networks, Inc.2013

#Notes:
#The target of this test case is to test if Management VLAN can work well or not?

#precondition: 
#1.all configurre should be default value except below mention.
#2.Make sure you can control COM port of DUT because we need to change Management VLAN 1 to other VLAN value.

#steps:
#1.when MGMT vlan=1 by default,set port-type to unaware, send priority-vlan/singlevlan/doublevlan with different TPID,CFI and VID,to check its result.
#2.when MGMT vlan=1 by default,set port-type to c-port, send priority-vlan/singlevlan/doublevlan with different TPID,CFI and VID,to check its result
#3.when MGMT vlan=1 by default,set port-type to s-port, send priority-vlan/singlevlan/doublevlan with different TPID,CFI and VID,to check its result
#4.when MGMT vlan=1 by default,set port-type to c-s-port, send priority-vlan/singlevlan/doublevlan with different TPID,CFI and VID,to check its result
#5.when MGMT vlan=other value by default,retest step1-4.
#6.restore default configure, to check if it can work well or not? (retest step1-4)