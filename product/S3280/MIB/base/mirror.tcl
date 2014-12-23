#!/bin/tcl

#Filename: mirror.tcl
#History:
#        1/15/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

namespace eval mirroringoid {
set tnMirroringGroupID(oid) 1.3.6.1.4.1.868.2.5.25.1.1.1.1.1
set tnMirroringGroupID(type) INTEGER 
set tnMirroringGroupID(access) read-only
set tnMirroringGroupDestIfIndex(oid) 1.3.6.1.4.1.868.2.5.25.1.1.1.1.2
set tnMirroringGroupDestIfIndex(type) Integer32 
set tnMirroringGroupDestIfIndex(access) read-write
set tnMirroringIfGroupID(oid) 1.3.6.1.4.1.868.2.5.25.1.1.2.1.1
set tnMirroringIfGroupID(type) INTEGER 
set tnMirroringIfGroupID(access) read-write
set tnMirroringIfMode(oid) 1.3.6.1.4.1.868.2.5.25.1.1.2.1.2
set tnMirroringIfMode(type) INTEGER 
set tnMirroringIfMode(access) read-write
}
namespace eval mirror {
namespace export *
}
proc mirror::setDestPort { dut mode } {
    set modevalue [string toupper $mode]
    if { [string equal $modevalue "DISABLE"] == 1 } {
       set port 0
    } else {
  	   set port $mode
    }
    set cmd "exec snmpset $::session $dut "
    set setMirrorDestPort "$mirroringoid::tnMirroringGroupDestIfIndex(oid).1 [getType $mirroringoid::tnMirroringGroupDestIfIndex(type)] $port"
    append cmd $setMirrorDestPort
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "set mirroring destination port  \"$mode\" for  dut $dut Failed!"
    } else {
        puts "set mirroring destination port  \"$mode\" for  dut $dut successed!"
    }
}


proc mirror::setSourcePort { dut port mode } {
    set modevalue [string toupper $mode]
    switch $modevalue {
       TX        { set value 10 }
       RX        { set value 20 }
       BOTH      { set value 30 }
       DISABLE   { set value  0 }
       deault    {puts "port mode error,which must be include tx,rx,both and disable"}
    }
    set cmd "exec snmpset $::session $dut "
    set setMirrorDestPort "$mirroringoid::tnMirroringIfMode(oid).$port [getType $mirroringoid::tnMirroringIfMode(type)] $value"
    append cmd $setMirrorDestPort
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "set mirroring source  port $port mode  \"$mode\" for  dut $dut Failed!"
    } else {
        puts "set mirroring source  port $port mode  \"$mode\" for  dut $dut successed!"
    }
}

