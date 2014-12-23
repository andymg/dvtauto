#!/bin/tcl

#Filename: dhcpRelay.tcl
#Target: lldp private module
#History:
#        1/15/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

namespace eval  dhcpRelayoid {
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
namespace eval dhcpRelay {
namespace export *
}





# set DHCP relay mode 

#set DHCP Snooping  global mode 
#proc dhcpSnooping::setRelayMode { dut value ip } {
#   set mode [string toupper $value]
#   switch   -exact -- $mode {
#                 set cmd "exec snmpset $::session $dut"
#                    set setdhcpRelayMode "$dhcpSnoopingoid::tnDhcpRelayMode(oid).1 [getType $dhcpSnoopingoid::tnDhcpRelayMode(type)] $modevalue"
#                    append cmd " $setdhcpRelayMode"
#                    set setdhcpRelayIP  "$dhcpSnoopingoid::tnDhcpRelayServerAddr(oid).1 [getType $dhcpSnoopingoid::tnDhcpRelayServerAddr(type)] $Ipvalue"
#                    set ret [catch {eval $cmd} error]
#                  }
#
#        DISABLE     {set modevalue 2
#
#                     set cmd "exec snmpset $::session $dut"
#                     set setdhcpRelayMode "$dhcpSnoopingoid::tnDhcpRelayMode(oid).1 [getType $dhcpSnoopingoid::tnDhcpRelayMode(type)] $modevalue"
#                     append cmd " $setdhcpRelayMode"
#                     set setdhcpRelayIP  "$dhcpSnoopingoid::tnDhcpRelayServerAddr(oid).1 [getType $dhcpSnoopingoid::tnDhcpRelayServerAddr(type)] $Ipvalue"
#                     set ret [catch {eval $cmd} error]
#                    }
#        default    {puts "DHCP Snooping global mode doesn't match"}
#    }
#    
#    if {$ret == 1} { 
#        puts $error
#        puts "set DHCP Snooping  relay  mode  \"$mode\" for  dut $dut Failed!"
#    } else {
#
#        puts "set DHCP Snooping relay  mode  \"$mode\" for  dut $dut successed!"
#    }
#}