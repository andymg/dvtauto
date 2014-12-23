#!/bin/tcl
#Author: Andym
#Date: 2013-11-20
#Desc: this is the init file for ipmc testing

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
set ::portNo [getPortNo $::dut]

set ::ixiaIpAddr $cfg::EQPT2(IP)

set ::ixiaPort1 [lindex $::topo::EQPT2 0]
set ::ixiaPort2 [lindex $::topo::EQPT2 1]
set ::ixiaPort3 [lindex $::topo::EQPT2 2]
set ::phymode $cfg::EQPT2(PORTMODE)

set ::dutP1 [lindex $::topo::DUT1 0]
set ::dutP2 [lindex $::topo::DUT1 1]
set ::dutP3 [lindex $::topo::DUT1 2]

set ::ixiaMac1 "01 00 5E 00 00 05"
set ::ixiaMac2 "01 00 5E 00 00 02"
set ::ixiaMac3 "00 00 00 00 5E 05"
set ::ixiaMac4 "00 00 00 00 5E 04"

set ::ixiaFrameSize 100
set ::ixiaSendRate 100
set ::ixiaRunTime 1
set ::testerName fieldt

# printTestInfo
