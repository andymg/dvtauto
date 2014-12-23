#!/bin/tcl
#Author: Andym
#Date : 2013-11-20
#Desc : all init parameters for VLAN testing

#import pubModule from api/mib
variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../../../../api/mib/pubModule.tcl} err

#import vlan.tcl from ../base/vlan.tcl
variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../base/vlan.tcl} err

namespace import util::*

#base configuration for DUT testing
set ::dut $cfg::DUT1(IP)
set community private
set ::session "-v2c -c $community $::dut"
set ::portNo [getPortNo $::dut]

set ::ixiaIpAddr $cfg::EQPT2(IP)

set ::ixiaPort1 [lindex $::topo::EQPT2 0]
set ::ixiaPort2 [lindex $::topo::EQPT2 1]

set ::dutp1 [lindex $::topo::DUT1 0]
set ::dutp2 [lindex $::topo::DUT1 1]

set ::phymode $cfg::EQPT1(PORTMODE)

set ::ixiaMac1 "00 00 00 00 00 11"
set ::ixiaMac2 "00 00 00 00 00 22"
set ::ixiaFrameSize 100
set ::ixiafpsrate 20

set ::ixiarate 10
