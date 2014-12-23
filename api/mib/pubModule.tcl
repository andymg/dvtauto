#!/bin/sh
#\
exec tclsh "$0" "$@"

namespace eval util {
	namespace export *

	proc mac2index {mac} {
	    if {[string first : $mac]} {
		    set mac_str [split $mac ':']	
	    } 
	    if {[string first - $mac] != -1 } {
		    set mac_str [split $mac -]
	    }
        set index ''
        foreach i $mac_str {
    	    set hex 0x$i
    	    scan $hex %x decv
    	    set index "$index.$decv"
        }
        return [string range $index [expr [string first . $index] + 1] end]
    }

	proc getType {mibtype} {
		set type(VlanIndex) u
		set type(PortList) x
		set type(INTEGER) i
        set type(Integer32) i
		set type(RowStatus) i
		set type(TruthValue) i
		set type(InetAddress) x
		set type(Bits) x
		set type(OctetString) x
		set type(Unsigned32) u
		set type(EightOTwoOui) s
		set type(SnmpAdminString) s
		set type(DisplayString) s
		set type(IpAddress) a
		set type(MacAddress) x
		set type(InterfaceIndex) i
    #if ([catch [info exist $type($mibtype)]]) {
    #	puts "$mibtype is not mapped in getType()"
    #}
		return $type($mibtype)
	}

	proc ispingable { ip } {
		catch {
			set ret [exec ping -c 2 -w 3 $ip]
		}
		if {[info exist ret] == 0} {
			puts "$ip is not pingable"
			return -1
		}
		puts "$ip is pingable"
		return 1
	}
	
	proc getParam {params type} {
		foreach {handle para} $params {
			if {[regexp {^-(.*)} $handle all handleval]} {
				lappend handlelist $handleval
				lappend paralist $para
			}
	    }
		if {[set idx [lsearch $handlelist $type]] != -1} {
			return  [lindex $paralist $idx]
		} else {
			puts "unknow type $type"
			return -1
		}
	}

	proc portListToPort { hex } {
		if {[string length $hex] == 1} {
			set value [scan $hex %c]
		}
		if {[string length $hex] != 1} {
			set hexv 0x$hex
			scan $hexv %x value
		}
		set port ""
		set rel 2
		while { $rel > 1 } {
			set rel [expr $value/2]
			set y [expr $value%2]
			set value $rel
			append port $y
		}
		append port 1
		set len [string length $port]
		while {$len < 8} {
			incr len
			append port 0
		}
		for {set i 7} { $i > 0} {incr i -1} {
			if {[string index $port $i] == 1} {
				lappend ports [expr 8-$i]
			}
		}
		return $ports
	}
	
	proc port2Portlist {ports} {
		set max 0
		foreach port $ports {
			if { $port > $max } {
				set max $port
			}
		}
		set len [expr $max/4]
		set rev [expr $max%4]
		if { $rev != 0} {
			incr len
		}
		set top [expr $len * 4]
		set value 0
		foreach p $ports {
			set temp [expr 2**[expr $top - $p]]
			set value [expr $value + $temp]
		}
		set hex [format %x $value]
		set hlen [string length $hex]
		set pre ""
		for {set i 0} {$i < [expr $len - $hlen] } {incr i} {
			append pre "0"
		}
		set hex [append pre $hex]
	    set len [string length $hex]
		set rev [ expr $len%2 ]
		if {$rev == 1} {
			append hex "0"	
		}
		return $hex
	}

	proc getPortNo { dut } {
		set cmd "exec snmpwalk -v2c -c private $dut 1.3.6.1.2.1.31.1.1.1.1"
		set ret [eval $cmd]
		set ports [split $ret '\n']
		set count 0
		foreach str $ports {
			if {[string first "Port" $str] != -1} {
				incr count
			}
		}
		return [expr ($count/4)*4]
	}

	proc setToFactoryDefault { dut } {
		set cmd "exec snmpset -v2c -c private $dut 1.3.6.1.4.1.868.2.5.3.1.1.1.1.1.7.1 i 1"
		set ret [catch {eval $cmd} error]
		if { $ret } {puts $error;puts "setToFactoryDefault on $dut Failed"}
	}

	proc setOid {var index value} {
		set c {{$var}(oid).$index [getType {$var}(type)] $value}
		return $c
	}
	#this is the public case result print method, 
	#all MIB cases result should call this to mark the case result
	#TODO write all case result to result file
	#TODO write result to JUnit xml file for Jenkins 
	proc passed {name description} {
		puts "++++++++++++++++++++++++++++$name+++++++++++++++++++++++++++++++"
		puts "Time:[clock format [clock seconds]]"
		puts "Desc: $description"
		puts "PASS"
		puts "============================$name==============================="
		puts "\n"

	}
	proc failed {name description} {
		puts "++++++++++++++++++++++++++++$name++++++++++++++++++++++++++++++"
		puts "Time:[clock format [clock seconds]]"
		puts "Desc: $description"
		puts "FAIL"
		puts "============================$name================================="
		puts "\n"
	}
	# get the DUT's CPU MAC address
	# getDutMacAddr 192.168.4.51
	# return MAC style "00 C0 F2 56 14 A0"
	proc getDutMacAddr { dut } {
		# get value from ipNetToMediaPhysAddress variable
		set cmd "exec snmpwalk -v2c -c private $dut 1.3.6.1.2.1.4.22.1.2"
		set ret [catch {eval $cmd} e]
		if { $ret } {puts $e; puts "getDutMacAddr on $dut failed"}
		set mac [lindex [split $e "="] 1]
		set mac_str [split $mac ":"]

		set l_mac ""
		foreach m $mac_str {
			set z "0"
			if {[string length $m] == 1} {
			    set m [append z $m] 
			}
			if {[string length $m] > 2} {
				continue
			}
			append l_mac $m
			append l_mac ":"
		}
		set z "0"
		set result [string range $l_mac 0 end-1]
		set stmac [string range $result 0 1]
		if { $stmac == "0:" } {
			set result [append z $result]
		}
		if { $stmac == " 0"} {
			set result [string replace $result 0 "0"]
			set result [append z $result]
		}
		set result [join [split $result ":"] " "]
	}
	#get the MAC address of a port
	# the MAC address is from (CPU address + port No)
	#return mac type "00 C0 F2 56 14 A0"
	proc getPortMacaddr {dut port} {
		set mac [getDutMacAddr $dut]
		set l_mac [string range $mac end-1 end]
		scan $l_mac %x dmac
		set dmac [expr $dmac + $port]
		set l_mac [format %x $dmac]
		set z "0"
		if {[string length $l_mac] == 1} {
			set l_mac [append z $l_mac]
		}
		# replace the new last two hex value to mac address
		set res [string replace $mac end-1 end $l_mac]
		set result [join [split $res ":"] " "]
	}
	#execute shell command
	proc shcmd { str } {
	    exec $::env(SHELL) -c $str
    }
}

#************************************read configuration file*****************************
#refer to http://www2.tcl.tk/3295

namespace eval cfg {
    variable version 1.0

    variable sections [list DUT1]

    variable cursection DUT1
    variable DUT1;   # DUT1 section
	#namespace export *
}

proc cfg::sections {} {
    return $cfg::sections
}

proc cfg::variables {{section DUT1}} {
    return [array names ::cfg::$section]
}

proc cfg::add_section {str} {
    variable sections
    variable cursection

    set cursection [string trim $str \[\]]
    if {[lsearch -exact $sections $cursection] == -1} {
        lappend sections $cursection
        variable ::cfg::${cursection}
    }
}

proc cfg::setvar {varname value {section DUT1}} {
    variable sections
	
    if {[lsearch -exact $sections $section] == -1} {
      cfg::add_section $section
    }
    set ::cfg::${section}($varname) $value
}

proc cfg::getvar {varname {section DUT1}} {
    variable sections
	
    if {[lsearch -exact $sections $section] == -1} {
        error "No such section: $section"
    }
    return [set ::cfg::${section}($varname)]
}

proc cfg::parse_file {filename} {
    variable sections
    variable cursection
    set line_no 1
    set fd [open $filename r]
    while {![eof $fd]} {
        set line [string trim [gets $fd] " "]
        if {$line == ""} continue
        switch -regexp -- $line {
           ^#.* { }
           ^\\[.*\\]$ {
               cfg::add_section $line
           }
           .*=.* {
               set pair [split $line =]
               set name [string trim [lindex $pair 0] " "]
               set value [string trim [lindex $pair 1] " "]
               cfg::setvar $name $value $cursection
           } 
           default {
               error "Error parsing $filename (line: $line_no): $line"
           }
        }
       incr line_no
    }
    close $fd
}

#************************************read topology file*****************************

namespace eval topo {
    variable version 1.0
	
}

proc topo::setvar {left right} {
	
	#it only was available for ixia equipment(MUST two equipment, two DUT)
    if {[string equal -length 1 $left $right] == 0} {
	    if { [regexp {^(E[\w]+[\d])(\-)([\d]/[\d]/[\d])} $left total nm ds pn] == 1 } {
		    #set nm $nm
			#variable ::topo::${nm}
		    set key [append tmp1 $nm [join [split $pn /] {}]]
			set value [append tmp2 [join [split $right -] {}]]
		    variable ::topo::${key} $value
		} elseif { [regexp {^(E[\w]+[\d])(\-)([\d]/[\d]/[\d])} $right total nm ds pn] == 1 } {
		    set key [append tmp1 $nm [join [split $pn /] {}]]
			set value [append tmp2 [join [split $left -] {}]]
		    variable ::topo::${key} $value
	    } else {
		    error "Error File content,please check your topology configuration"
		}
	}
}

proc topo::parse_file {filename} {
    
	set line_no 1
    set fd [open $filename r]
    while {![eof $fd]} {
        set line [string trim [gets $fd] " "]
        if {$line == ""} continue
        switch -regexp -- $line {
           .*=.* {
                set pair [split $line =]
                set left [string trim [lindex $pair 0] " "]
                set right [string trim [lindex $pair 1] " "]
				foreach x "$left $right" {
			        switch -regexp -- $x {
			            DUT1.* {lappend dut1 $x}
				        DUT2.* {lappend dut2 $x}
			            EQPT1.* {lappend eqpt1 $x}
				        EQPT2.* {lappend eqpt2 $x}
				        default {
				            error "Error File content,please check your topology configuration"
			            }
			        }
				}
                topo::setvar $left $right
            }
            default {
                error "Error parsing $filename (line: $line_no): $line"
            }
        }
        incr line_no
    }
    close $fd

    if {[info exist dut1]} {
    	foreach x $dut1 {
	        lappend dut1lst [lindex [split $x "-"] 1]
	    }
	    variable ::topo::DUT1 [lsort $dut1lst]
    } else {
        set ::topo::DUT1 null
    }
    if {[info exist dut2]} {
    	foreach x $dut2 {
	        lappend dut2lst [lindex [split $x "-"] 1]
	    }
	    variable ::topo::DUT2 [lsort $dut2lst]
	} else {
		set ::topo::DUT2 null
	}
	if {[info exist eqpt1]} {
    	foreach x $eqpt1 {
		    #only get card/port(1,2 1,3),after removing lrange and it will get chassis/card/port
	        lappend eqptlst1 [join [lrange [split [lindex [split $x "-"] 1] "/"] end-1 end] ","]
	    }
	    variable ::topo::EQPT1 [lsort $eqptlst1]
	} else {
		set ::topo::EQPT1 null
	}
	if {[info exist eqpt2]} {
    	foreach x $eqpt2 {
		    #only get card/port(1,2 1,4),after removing lrange and it will get chassis/card/port
	        lappend eqptlst2 [join [lrange [split [lindex [split $x "-"] 1] "/"] end-1 end] ","]
	    }
	    variable ::topo::EQPT2 [lsort $eqptlst2]
    } else {
    	set ::topo::EQPT2 null
    }
}

#-------------------------------------initial environment variables-------------------------------------
namespace eval initEnv {
	variable version 1.0
}

proc initEnv::ixiawin { product uservrsn } {
	set productKey "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\$product"
    if { [catch {registry keys $productKey} err] } {
        puts "please check whether you have installed IXIA SOFTWARE in your operation system"
        exit 1
   	} else {
   		set versionKey [registry keys $productKey] ;#5.70.600.13 6.30.850.23
   	}
    
    set ver [lsearch -all $versionKey $uservrsn]

    if { $ver == -1 || [llength $ver] != 1 } {
    	puts "please check ixia SOFTWARE version in use, it doesn't match your current system yet"
    	puts "Try to completion of all version information, e.g. 6.30.850.23 or 5.70.600.13"
    	exit 1
    } else {
    	set ver [lsearch -all -inline $versionKey $uservrsn]
    }
    set installInfo [append productKey \\ $ver \\ InstallInfo]
    return [registry get $installInfo HOMEDIR]
   #to get latest version
   #set latestKey      [lindex $versionKey end]
   #if { $latestKey == "Multiversion" } {
   #   set latestKey   [lindex $versionKey [ expr [ llength $versionKey ] - 2 ]]
   #}
   #set installInfo    [append productKey \\ $latestKey \\ InstallInfo]
   #return [registry get $installInfo  HOMEDIR]
}

proc initEnv::unixcommon {id cnt file} {
	puts $id $cnt
    close $id
    shcmd "chmod +x $file"
    puts "Configure bashrc can't take effect immediately,please try to logout/login your operation system"
    puts "this feature is ongoing"
    shcmd "source $file"
}

proc initEnv::ixiaunix { product uservrsn } {
    
    #there are 3 method to find out whether your system has been installed ixia 
    #whereis ixos, even your system has been installed, but sometimes it isn't successful 
    #or locate IxOS_Tcl_Client_InstallLog.log/IxOS_Tcl_Client_xx_xx_xx_InstallLog.log

    set srchixiafile "ixwish"
	if { [catch {exec locate $srchixiafile} err] } {
	   puts "please check your operation system and make sure which has been installed $product"
	   exit 1
	} else {
		set ixpath [exec locate $srchixiafile]
         #it only consider ixos, should be modified if add ixia other product
        if { [llength $ixpath] == 1 && [file executable $ixpath] && [regexp {ixwish} [file tail $ixpath]] } {
            set ixpath [file dirname [file dirname [file nativename $ixpath]]]
        } else {
            puts "please check if you have installed $product rightly,Can't find out "ixwish" path"
            exit 1
        }
	}

	set tclfile "tclsh"
	if { [catch {exec which $tclfile} err] } {
	   puts "please check your operation system and make sure which has been installed tcl/tk"
	   exit 1
	} else {
       set tclpath [exec which $tclfile]
	}
    
    set bshfile "~/.bashrc"
    set ixia_content [subst -novariables {
[list IXIA_HOME=$ixpath]
[list TCL_HOME=$tclpath]
[list IXIA_VERSION=$uservrsn]
TCLver=8.4
IxiaLibPath=$IXIA_HOME/lib
IxiaBinPath=$IXIA_HOME/bin
TCLLibPath=$TCL_HOME/lib
TCLBinPath=$TCL_HOME/bin
TCL_LIBRARY=$TCLLibPath/tcl$TCLver
TK_LIBRARY=$TCLLibPath/tk$TCLver
PATH=$IxiaBinPath:.:$TCLBinPath:$PATH
TCLLIBPATH=$IxiaLibPath
LD_LIBRARY_PATH=$IxiaLibPath:$TCLLibPath:$LD_LIBRARY_PATH
IXIA_RESULTS_DIR=/tmp/Ixia/Results
IXIA_LOGS_DIR=/tmp/Ixia/Logs
IXIA_TCL_DIR=$IxiaLibPath
IXIA_SAMPLES=$IxiaLibPath/ixTcl1.0
export IXIA_HOME TCL_LIBRARY TK_LIBRARY TCLLIBPATH
export LD_LIBRARY_PATH IXIA_RESULTS_DIR
export IXIA_LOGS_DIR IXIA_TCL_DIR IXIA_SAMPLES
export IXIA_TCL_DIR PATH IXIA_VERSION
$TCLBinPath/wish ${@+"$@"}
}]


	if {[file exist $bshfile]} {
        set bf [open $bshfile r+]
        set data [string trim [read $bf]]
        if {[llength [subst -novariables {$data}]] == 0} {
            puts "This is empty file,will write ixia && tcl/tk variable"
            initEnv::unixcommon $bf $ixia_content $bshfile
        } else {
            if { [lsearch [string trim [split $data "\n"]] {IXIA*}] != -1 } {
                puts "you have configured ixia environment,suggest to check whether it is valid?"
                close $bf
            } else {
                seek $bf 0 end
                initEnv::unixcommon $bf $ixia_content $bshfile
            }
        }
    } else {
	   set bf [open $bshfile w+]
	   initEnv::unixcommon $bf $ixia_content $bshfile
    }
}

proc initEnv::spntwin { } {

	 #need to be developed in the future

}

proc initEnv::spntunix { } {
	
    #need to be developed in the future
}

proc initEnv::chkPlatform {  }  {
    
    #most of test cases developed based on IxOS.
    set product [string tolower [string trim $cfg::EQPT1(PLATFORM)]]
    set uservrsn [string trim $cfg::EQPT1(VERSION)]

    switch $::tcl_platform(platform) {
        windows {
            catch {package require registry} err
            puts "Currently it doesn't configure ixia/tcl variable in windows 7, please try to use unix/windows xp OS"
            source [initEnv::ixiawin $product $uservrsn]/TclScripts/bin/ixiawish.tcl
        }
        unix {
            initEnv::ixiaunix $product $uservrsn
        }
    }
}


variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]
if {![file exists $path/config.cfg]} {
	puts stderr "Error: config.cfg not exists! \n Please copy from config.cfg.example and create config.cfg according to your own network Topo!"
}
if {![file exists $path/topo.cfg]} {
	puts stderr "Error: topo.cfg not exists! \n Please copy from topo.cfg.example and create topo.cfg according to your own network Topo!"
}
#catch {source ../eqpt/smartbits/..} err
catch {cfg::parse_file $path/config.cfg} err
catch {topo::parse_file $path/topo.cfg} err

if { [string match $cfg::EQPT1(PLATFORM) $cfg::EQPT2(PLATFORM)] != 1 || [string match $cfg::EQPT1(VERSION) $cfg::EQPT2(VERSION)] != 1 } {
	puts "please check your EQPT PLATFORM and VERSION and make sure that they are the same"
	exit 1
} else {
	initEnv::chkPlatform
	catch {source $path/../eqpt/ixia/ixia.tcl} err
}
