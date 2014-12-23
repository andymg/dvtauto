#!/bin/sh
#\
exec tclsh "$0" "$@"

#Filename: init.tcl
#Target: load private module from "base" folder and initial public parameters.
#History:
#        11/20/2013- Olivia,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:

#import pubModule from api/mib

variable me [file normalize [info script]]
puts "me $me"
set path [file dirname [file nativename $me]]
puts "path is $path"
catch {source $path/../../../../api/cli/pubModule.tcl} err

#import mef private module
variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../base/mef.tcl} err

namespace import util::*

#base configuration for DUT testing
set ::dut1 $cfg::DUT1(IP)
set ::dut2 $cfg::DUT2(IP)

set ::dutp1 [lindex $::topo::DUT1 1]
set ::dutp2 [lindex $::topo::DUT2 1]
# puts $::dutp1
# puts $::dutp2

# #import ixia module
# variable me [file normalize [info script]]
# set path [file dirname [file nativename $me]]
# catch {source $path/../../../../api/eqpt/ixia/ixia.tcl} err

set ixiaIpAddr $::cfg::EQPT1(IP)
#puts $ixiaIpAddr
set ixiaPort1 [lindex $::topo::EQPT1 0]
#puts $ixiaPort1
set ixiaPort2 [lindex $::topo::EQPT1 1]
#puts $ixiaPort2
set phymode $cfg::EQPT1(PORTMODE)
