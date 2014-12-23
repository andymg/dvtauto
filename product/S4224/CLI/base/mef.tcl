#!/bin/sh
#\
exec tclsh "$0" "$@"

source ../../../../api/cli/pubModule.tcl

catch {package require Expect} err

namespace eval mef {
    variable user admin
	variable passwd ""
}

proc mef::loginSystem {dut1 dut2} {
    
	variable user
	variable passwd
	
	if { [catch {spawn telnet $dut1} fda] } {
        error "Connected Failure,Please check your network connectivity"
    } else {
        set ::spawnIDa $spawn_id
        expect -i $spawnIDa -nocase "username:"
        exp_send -i $spawnIDa "$user\r"
        expect -i $spawnIDa -nocase "password: "
        exp_send -i $spawnIDa "$passwd\r"
        expect -i $spawnIDa ">"
    }
	
    if { [catch {spawn telnet $dut2} fdb] } {
        error "Connected Failure,Please check your network connectivity"
    } else {
        set ::spawnIDb $spawn_id
        expect -i $spawnIDb -nocase "username:"
        exp_send -i $spawnIDb "$user\r"
        expect -i $spawnIDb -nocase "password: "
        exp_send -i $spawnIDb "$passwd\r"
        expect -i $spawnIDb ">"
    }
	
}

proc mef::chkSystemVersion { } {
    
	set chkversion "sys ver"
	
    puts "--------Start to check DUT1 $dut1 software version-------------"
    exp_send -i $::spawnIDa "$chkversion\r"
    expect -i $::spawnIDa ">"
    puts "--------Start to check DUT2 $dut2 software version-------------"
    exp_send -i $::spawnIDb "$chkversion\r"
    expect -i $::spawnIDb ">"

}

proc mef::chkDutConnect { dut1 dut2 } {

    set aftertime 10000
	
	puts "start to check $dut1 network connectivity" 
	for {set x 1} {$x < 10} {incr x} {
	    set rt [eval chkConnect "http://$dut1"]
		if { $rt == 1 } {
		    puts "It can connect DUT1 successfully"
			break
		} else {
		    after $aftertime
			continue
		}
	}
	puts "################end of check $dut1##############"
	
	puts "start to check $dut2 network connectivity"
    for {set x 1} {$x < 10} {incr x} {
	    set rt [eval chkConnect "http://$dut2"]
		if { $rt == 1 } {
		    puts "It can connect DUT2 successfully"
			break
		} else {
		    after $aftertime
			continue
		}
	}
	puts "################end of check $dut2##############"
}
