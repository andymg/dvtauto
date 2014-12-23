#!/bin/tcl
#Author: Jerry
#Date : 2013-11-20


variable me [file normalize [info script]]
set path [file dirname [file nativename $me]]
catch {source $path/../../../../api/mib/pubModule.tcl} err


namespace import util::*


set ::dut [cfg::getvar IP]
set community private
set ::session "-v2c -c $community $::dut"
set ::portNo [getPortNo $::dut]
set ::ixiaIpAddr [cfg::getvar IP EQPT1]
set ::ixiaPort1 [lindex $::topo::EQPT1 0]
set ::ixiaPort2 [lindex $::topo::EQPT1 1]
set ::ixiaPort3 [lindex $::topo::EQPT1 2]
#puts $::ixiaPort1

set ::dutp1 [lindex $::topo::DUT1 0]
set ::dutp2 [lindex $::topo::DUT1 1]
set ::dutp3 [lindex $::topo::DUT1 2] 
set ::phymode $cfg::EQPT1(PORTMODE)

proc get_dut_mac {} {
	set cmd "exec snmpget -v2c -c public 192.168.100.1 1.3.6.1.2.1.4.22.1.2.60001.$::dut"
	set ret [catch {eval $cmd} e]
	if {!$ret} {set dut_mac [string range $e end-17 end] }
	return $dut_mac

}

#set ::ixiaMac1 "00 00 00 00 00 11"
#set ::ixiaMac2 "00 00 00 00 00 22"
#set ::ixiaFrameSize 100
#set ::ixiafpsrate 20

#set ::ixiarate 10