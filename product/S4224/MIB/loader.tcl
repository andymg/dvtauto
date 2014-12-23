#!/bin/tcl
#file :loader.tcl
# purpose: load base modules
#author: andym 20130522

proc loader {args} {
	foreach dir $args {
		if {[catch {source $dir} err]} {
			puts "load $dir failed!\nerrorInfo: $err"
			exit
		}
	}
}

set ixia	 ../../../api/eqpt/ixia/ixia.tcl
set ipmc     ./1/ipmc.tcl
set vcl      ../../../api/mib/vcl.tcl
set util     ../../../api/mib/util.tcl

loader $ixia $util $ipmc $vcl

set ::dut 192.168.4.17
#set dut 192.168.3.53
set community private
set ::session "-v2c -c $community $::dut"
set ::portNo [getPortNo $::dut]

set ::ixiaIpAddr 192.168.1.22
set ::ixiaPort1 2,1
set ::ixiaPort2 2,2

source ./1/1.1.tcl
