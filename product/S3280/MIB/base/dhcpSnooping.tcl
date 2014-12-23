#!/bin/tcl

#Filename: dhcpSnooping.tcl
#History:
#        11/20/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

namespace eval  dhcpSnoopingoid {
set tnDhcpSnoopingStatisticsClear(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.1
set tnDhcpSnoopingStatisticsClear(type) TruthValue 
set tnDhcpSnoopingStatisticsClear(access) read-write
set tnDhcpSnoopingStatisticsRxDiscover(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.2
set tnDhcpSnoopingStatisticsRxDiscover(type) INTEGER 
set tnDhcpSnoopingStatisticsRxDiscover(access) read-only
set tnDhcpSnoopingStatisticsTxDiscover(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.3
set tnDhcpSnoopingStatisticsTxDiscover(type) INTEGER 
set tnDhcpSnoopingStatisticsTxDiscover(access) read-only
set tnDhcpSnoopingStatisticsRxOffer(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.4
set tnDhcpSnoopingStatisticsRxOffer(type) INTEGER 
set tnDhcpSnoopingStatisticsRxOffer(access) read-only
set tnDhcpSnoopingStatisticsTxOffer(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.5
set tnDhcpSnoopingStatisticsTxOffer(type) INTEGER 
set tnDhcpSnoopingStatisticsTxOffer(access) read-only
set tnDhcpSnoopingStatisticsRxRequest(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.6
set tnDhcpSnoopingStatisticsRxRequest(type) INTEGER 
set tnDhcpSnoopingStatisticsRxRequest(access) read-only
set tnDhcpSnoopingStatisticsTxRequest(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.7
set tnDhcpSnoopingStatisticsTxRequest(type) INTEGER 
set tnDhcpSnoopingStatisticsTxRequest(access) read-only
set tnDhcpSnoopingStatisticsRxDecline(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.8
set tnDhcpSnoopingStatisticsRxDecline(type) INTEGER 
set tnDhcpSnoopingStatisticsRxDecline(access) read-only
set tnDhcpSnoopingStatisticsTxDecline(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.9
set tnDhcpSnoopingStatisticsTxDecline(type) INTEGER 
set tnDhcpSnoopingStatisticsTxDecline(access) read-only
set tnDhcpSnoopingStatisticsRxACK(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.10
set tnDhcpSnoopingStatisticsRxACK(type) INTEGER 
set tnDhcpSnoopingStatisticsRxACK(access) read-only
set tnDhcpSnoopingStatisticsTxACK(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.11
set tnDhcpSnoopingStatisticsTxACK(type) INTEGER 
set tnDhcpSnoopingStatisticsTxACK(access) read-only
set tnDhcpSnoopingStatisticsRxNAK(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.12
set tnDhcpSnoopingStatisticsRxNAK(type) INTEGER 
set tnDhcpSnoopingStatisticsRxNAK(access) read-only
set tnDhcpSnoopingStatisticsTxNAK(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.13
set tnDhcpSnoopingStatisticsTxNAK(type) INTEGER 
set tnDhcpSnoopingStatisticsTxNAK(access) read-only
set tnDhcpSnoopingStatisticsRxRelease(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.14
set tnDhcpSnoopingStatisticsRxRelease(type) INTEGER 
set tnDhcpSnoopingStatisticsRxRelease(access) read-only
set tnDhcpSnoopingStatisticsTxRelease(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.15
set tnDhcpSnoopingStatisticsTxRelease(type) INTEGER 
set tnDhcpSnoopingStatisticsTxRelease(access) read-only
set tnDhcpSnoopingStatisticsRxInform(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.16
set tnDhcpSnoopingStatisticsRxInform(type) INTEGER 
set tnDhcpSnoopingStatisticsRxInform(access) read-only
set tnDhcpSnoopingStatisticsTxInform(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.17
set tnDhcpSnoopingStatisticsTxInform(type) INTEGER 
set tnDhcpSnoopingStatisticsTxInform(access) read-only
set tnDhcpSnoopingStatisticsRxLeaseQuery(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.18
set tnDhcpSnoopingStatisticsRxLeaseQuery(type) INTEGER 
set tnDhcpSnoopingStatisticsRxLeaseQuery(access) read-only
set tnDhcpSnoopingStatisticsTxLeaseQuery(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.19
set tnDhcpSnoopingStatisticsTxLeaseQuery(type) INTEGER 
set tnDhcpSnoopingStatisticsTxLeaseQuery(access) read-only
set tnDhcpSnoopingStatisticsRxLeaseUnassigned(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.20
set tnDhcpSnoopingStatisticsRxLeaseUnassigned(type) INTEGER 
set tnDhcpSnoopingStatisticsRxLeaseUnassigned(access) read-only
set tnDhcpSnoopingStatisticsTxLeaseUnassigned(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.21
set tnDhcpSnoopingStatisticsTxLeaseUnassigned(type) INTEGER 
set tnDhcpSnoopingStatisticsTxLeaseUnassigned(access) read-only
set tnDhcpSnoopingStatisticsRxLeaseUnknown(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.22
set tnDhcpSnoopingStatisticsRxLeaseUnknown(type) INTEGER 
set tnDhcpSnoopingStatisticsRxLeaseUnknown(access) read-only
set tnDhcpSnoopingStatisticsTxLeaseUnknown(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.23
set tnDhcpSnoopingStatisticsTxLeaseUnknown(type) INTEGER 
set tnDhcpSnoopingStatisticsTxLeaseUnknown(access) read-only
set tnDhcpSnoopingStatisticsRxLeaseActive(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.24
set tnDhcpSnoopingStatisticsRxLeaseActive(type) INTEGER 
set tnDhcpSnoopingStatisticsRxLeaseActive(access) read-only
set tnDhcpSnoopingStatisticsTxLeaseActive(oid) 1.3.6.1.4.1.868.2.5.33.1.1.3.1.25
set tnDhcpSnoopingStatisticsTxLeaseActive(type) INTEGER 
set tnDhcpSnoopingStatisticsTxLeaseActive(access) read-only
set tnDhcpSnoopingMode(oid) 1.3.6.1.4.1.868.2.5.33.1.1.1.1.1
set tnDhcpSnoopingMode(type) INTEGER 
set tnDhcpSnoopingMode(access) read-write
set tnDhcpSnoopingifMode(oid) 1.3.6.1.4.1.868.2.5.33.1.1.2.1.1
set tnDhcpSnoopingifMode(type) INTEGER 
set tnDhcpSnoopingifMode(access) read-write
set tnDhcpRelayMode(oid) 1.3.6.1.4.1.868.2.5.33.1.2.1.1
set tnDhcpRelayMode(type) INTEGER 
set tnDhcpRelayMode(access) read-write
set tnDhcpRelayServerAddrType(oid) 1.3.6.1.4.1.868.2.5.33.1.2.1.1.2
set tnDhcpRelayServerAddrType(type) INTEGER 
set tnDhcpRelayServerAddrType(access) read-write
set tnDhcpRelayServerAddr(oid) 1.3.6.1.4.1.868.2.5.33.1.2.1.1.3
set tnDhcpRelayServerAddr(type) InetAddress 
set tnDhcpRelayServerAddr(access) read-write
set tnDhcpRelayInfoMode(oid) 1.3.6.1.4.1.868.2.5.33.1.2.1.1.4
set tnDhcpRelayInfoMode(type) INTEGER
set tnDhcpRelayInfoMode(access) read-write
set tnDhcpRelayInfoPolicy(oid) 1.3.6.1.4.1.868.2.5.33.1.2.1.1.5
set tnDhcpRelayInfoPolicy(type) INTEGER 
set tnDhcpRelayInfoPolicy(access) read-write
}  
namespace eval dhcpSnooping {
namespace export *
}

#set DHCP Snooping  global mode 
proc dhcpSnooping::setglobalMode { dut value } {
	set mode [string toupper $value]
	switch   -exact -- $mode {
		DISABLE    {set modevalue 2}
		ENABLE     {set modevalue 1}
        default    {puts "DHCP Snooping global mode doesn't match"}
	}
    set cmd "exec snmpset $::session $dut"
    set setdhcpSnoopingMode "$dhcpSnoopingoid::tnDhcpSnoopingMode(oid).1 [getType $dhcpSnoopingoid::tnDhcpSnoopingMode(type)] $modevalue"
    append cmd " $setdhcpSnoopingMode"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
    	puts $error
        puts "set DHCP Snooping  global mode  \"$mode\" for  dut $dut Failed!"
    } else {

        puts "set DHCP Snooping global mode  \"$mode\" for  dut $dut successed!"
    }
}

#set DHCP Snooping port mode 

proc dhcpSnooping::setportmode {dut port value} {
    set mode [string toupper $value]
    switch   $mode {
        TRUST     {set modevalue 1}
        UNTRUST   {set modevalue 2}
        default   {puts "DHCP Snooping port mode doesn't match"}
    }
    set cmd "exec snmpset $::session $dut"
    set setdhcpSnoopingifMode "$dhcpSnoopingoid::tnDhcpSnoopingifMode(oid).$port [getType $dhcpSnoopingoid::tnDhcpSnoopingifMode(type)] $modevalue"
    append cmd " $setdhcpSnoopingifMode"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "set DHCP Snooping  port $port mode  \"$mode\" for  dut $dut Failed!"
    } else {

        puts "set DHCP Snooping port $port mode  \"$mode\" for  dut $dut successed!"
    }
}

