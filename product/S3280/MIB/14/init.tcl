#!/bin/tcl

#Filename: init.tcl
#Target: load private module from "base" folder and initial public parameters
#History:
#        1/14/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

#import pubModule from api/mib
variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../../../../api/mib/pubModule.tcl} err
variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
source  $path/../base/dhcpSnooping.tcl
catch {source $path/../base/IpSourceGuard.tcl} err
namespace import util::*

set dut1 $cfg::DUT1(IP)
set ::ixiaphymode $cfg::EQPT1(PORTMODE)



set community private
set ::session "-v2c -c $community "
set ::portNo [getPortNo $::dut1]

set ::ixiaIpAddr $cfg::EQPT1(IP)

set ::ixiaPort1 [lindex $topo::EQPT1 0]
set ::ixiaPort2 [lindex $topo::EQPT1 1]


set ::dutp1 [lindex $topo::DUT1 0]
set ::dutp2 [lindex $topo::DUT1 1]


set ::ixiaMac1 "00 00 00 00 00 11"
set ::ixiaMac2 "00 00 00 00 00 22"
set ::ixiaFrameSize 100
set ::ixiafpsrate 20

set ::ixiarate 10







