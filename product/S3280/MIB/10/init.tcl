#!/usr/bin/env tclsh
#Filename: init.tcl
#History:
#        01/13/2014- Andym,Created
#
#Copyright(c): Transition Networks, Inc.2014

################## MLD introduction ###########################
# MLD is an acronym for Multicast Listener Discovery for IPv6. 
# MLD is used by IPv6 routers to discover multicast listeners 
# on a directly attached link, much as IGMP is used in IPv4. 
# The protocol is embedded in ICMPv6 instead of using a separate protocol. 
################## MLD 10.1 test introduction ###########################
# Desc: this is the init file for MLD testing, 
# pubmodule and basic modules are loadded
# Testing parameters are inited here for furture 10.* testing

variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../../../../api/mib/pubModule.tcl} err

#import vlan.tcl from ../base/vlan.tcl
variable me [file normalize [info script]]
set mpath [file dirname [file nativename $me]]
catch {source $mpath/../base/ipmc.tcl} err
catch {source $mpath/../base/vlan.tcl} err

namespace import util::*

set ::dut $cfg::DUT1(IP)
set community private
set ::session "-v2c -c $community $::dut"

set ::ixiaIpAddr $cfg::EQPT2(IP)

set ::ixiaPort1 [lindex $::topo::EQPT2 0]
set ::ixiaPort2 [lindex $::topo::EQPT2 1]
set ::ixiaPort3 [lindex $::topo::EQPT2 2]
set ::phymode $cfg::EQPT2(PORTMODE)

set ::dutP1 [lindex $::topo::DUT1 0]
set ::dutP2 [lindex $::topo::DUT1 1]
set ::dutP3 [lindex $::topo::DUT1 2]


set ::ixiaFrameSize 100
set ::ixiaSendRate 100
set ::ixiaRunTime 1
set ::testerName fieldt

# printTestInfo
