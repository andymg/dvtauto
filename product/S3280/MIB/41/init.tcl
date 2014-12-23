#!/bin/tcl

#Filename: init.tcl
#Target: load private module from "base" folder and initial public parameters
#History:
#        12/23/2013- Madeline,Created
#
#Copyright(c): Transition Networks, Inc.2013


#import pubModule from api/mib
variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../../../../api/mib/pubModule.tcl} err

#import pvlan.tcl from ../base/pvlan.tcl
variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../base/pvlan.tcl} err

namespace import util::*

#base configuration for DUT testing
set ::dut $cfg::DUT1(IP)
puts "dut is $::dut"
puts $cfg::DUT1(IP)
set community private
set ::session "-v2c -c $community $::dut"
puts $::session
set ::portNo [getPortNo $::dut]

set ::ixiaIpAddr $cfg::EQPT2(IP)

set ::ixiaPort1 [lindex $::topo::EQPT2 0]
set ::ixiaPort2 [lindex $::topo::EQPT2 1]
set ::ixiaPort3 [lindex $::topo::EQPT2 2]
puts "ixia port 1 is $::ixiaPort1"
puts "ixia port 2 is $::ixiaPort2"
puts "ixia port 3 is $::ixiaPort3"


set ::dutp1 [lindex $::topo::DUT1 0]
set ::dutp2 [lindex $::topo::DUT1 1]
set ::dutp3 [lindex $::topo::DUT1 2]
puts "dutp1 is $::dutp1"
puts "dutp2 is $::dutp2"
puts "dutp3 is $::dutp3"


set ::ixiaIpAddr $cfg::EQPT2(IP)
set ::ixiaphymode $cfg::EQPT2(PORTMODE)
puts $::ixiaIpAddr
puts $::ixiaphymode

set ::ixiaMac1 "00 00 00 00 00 11"
set ::ixiaMac2 "00 00 00 00 00 22"
set ::ixiaFrameSize 100
set ::ixiafpsrate 20

set ::ixiarate 10
