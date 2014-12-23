#!/bin/tcl

#Filename: arpInspec.tcl
#History:
#        12/23/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

namespace eval arpInspecoid {
set tnARPInspectionMode(oid) 1.3.6.1.4.1.868.2.5.3.1.1.22.1.1.1
set tnARPInspectionMode(type) INTEGER 
set tnARPInspectionMode(access) read-write
set tnARPInspectionTranslation(oid) 1.3.6.1.4.1.868.2.5.3.1.1.22.1.1.2
set tnARPInspectionTranslation(type) INTEGER 
set tnARPInspectionTranslation(access) read-write
set tnARPInspectionPortMode(oid) 1.3.6.1.4.1.868.2.5.3.1.1.22.2.1.1
set tnARPInspectionPortMode(type) INTEGER 
set tnARPInspectionPortMode(access) read-write
set tnStaticARPInspectionRowStatus(oid) 1.3.6.1.4.1.868.2.5.3.1.1.22.3.1.5
set tnStaticARPInspectionRowStatus(type)  INTEGER
set tnStaticARPInspectionRowStatus(access) read-write
set tnDynamicARPInspectionTable(oid)  1.3.6.1.4.1.868.2.5.3.1.1.22.4.1
set tnDynamicARPInspectionTable(access) read-only
set tnDynamicARPInspectionTable(type) INTEGER
}

namespace eval arpInspec {
namespace export *
}
#set arp inspection global mode 
proc arpInspec::globalMode { dut value } {
	set mode [string toupper $value]
	switch   -exact -- $mode {

		DISABLE    {set modevalue 2}
		ENABLE     {set modevalue 1}
	}
    set cmd "exec snmpset $::session $dut"
    set setarpInspecMode "$arpInspecoid::tnARPInspectionMode(oid).1 [getType $arpInspecoid::tnARPInspectionMode(type)] $modevalue"
    append cmd " $setarpInspecMode"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
    	puts $error
        puts "set arp inspection global mode  \"$mode\" for  dut $dut Failed!"
    } else {

        puts "set arp inspection global mode  \"$mode\" for  dut $dut successed!"
    }
}
#set arp inspection port mode 
proc arpInspec::portMode { dut  port value } {
    set mode [string toupper $value]
    switch   -exact -- $mode {

        DISABLE    {set modevalue 2}
        ENABLE     {set modevalue 1}
    }
    set cmd "exec snmpset $::session $dut"
    set setarpInspecMode "$arpInspecoid::tnARPInspectionPortMode(oid).$port [getType $arpInspecoid::tnARPInspectionPortMode(type)] $modevalue"
    append cmd " $setarpInspecMode"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "set arp inspection port $port  mode  \"$mode\" for  dut $dut Failed!"
    } else {

        puts "set arp inspection port $port  mode  \"$mode\" for  dut $dut successed!"
    }
}

##input mac address format is "00 00 00 11 11 11" 
##RowStatus value :active(1),notInService(2),notReady(3),createAndGo(4),createAndWait(5),destory(5)
proc arpInspec::createStaticTable { dut  port vlan mac ip } {
            ######chage mac address format from "00 00 00 11 11 11" to "000000111111"
            set mac1 [join [split $mac " "] ""]
    if { [string is xdigit $mac1 ] != 0} {
            ######change mac address  from hexademcimal to decimal
        for {set i 0 } {$i <= 11 } {incr i 2} {
           set a [string rang $mac1 $i [expr $i+1]]
           set b [join "0x $a" ""]
           set c [format %d $b]
           lappend d $c
        }
           set macaddress [join $d .]
          ###### out put macaddress format is 0.0.0.17.17.17
       set cmd "exec snmpset $::session $dut"
       set setarpInspecMode "$arpInspecoid::tnStaticARPInspectionRowStatus(oid).$port.$vlan.$macaddress.$ip [getType $arpInspecoid::tnStaticARPInspectionRowStatus(type)] 4"
       append cmd " $setarpInspecMode"
       set ret [catch {eval $cmd} error]
          if {$ret == 1} { 
          puts $error
          puts "create a new entry in arp inspection static table  Failed!"
        } else {
          puts "create a new entry in arp inspection static table successed!"
          puts " new arp inspection static entry is : port $port vlan is $vlan mac address is $mac and ip address is $ip "
        }
    } else {
         string is xidgit -failindex index $mac1
         puts " the format of mac address is error from $index character "
    }
}


# translate Dynamic table to static table
proc arpInspec::transDtoS { dut value } {
  set mode [string toupper $value]
  switch   -exact -- $mode {
    DISABLE    {set modevalue 2}
    ENABLE     {set modevalue 1}
  }
    set cmd "exec snmpset $::session $dut"
    set translateDtoS "$arpInspecoid::tnARPInspectionTranslation(oid).1 [getType $arpInspecoid::tnARPInspectionTranslation(type)] $modevalue"
    append cmd " $translateDtoS"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
      puts $error
        puts "Translating ARP Inspection Dynamic table to Static table Failed!"
    } else {
        puts "Translating ARP Inspection Dynamic table to Static table successed!"
    }
}

#walk ARP Inspeciton Dynamic table

proc arpInspec::walkdynamictable {dut} {
     set cmd "exec snmpwalk $::session $dut"
     set walkdynatable "$arpInspecoid::tnDynamicARPInspectionTable(oid) [getType $arpInspecoid::tnARPInspectionTranslation(type)] "
     append cmd " $walkdynatable"
     set result [eval $cmd]
     set ret [catch {eval $cmd} error]
     set result [eval $cmd]
     set ip [string trim  [lindex [split $result : ] 3]  " "]
     # SNMPv2-SMI::enterprises 868 2 5 3 1 1 22 4 1 4 6 1 0 0 22 74 185 {169 = IpAddress: 192} 168 0 200
     #change mac address "0 0 22 74 185 169 " to "00 00 16 4a b9 a9"
     set mac  [lrange  [split [string trim [lindex  [split $result =] 0] " "] .] end-5 end] 
    foreach i $mac {
       set a [format "%x" $i]
       if {$a == 0 } {
          set a "00"
          }
      lappend b $a
     }
    set vlan  [lindex  [split [string trim [lindex  [split $result =] 0] " "] .] end-6 ]
    set  port   [lindex  [split [string trim [lindex  [split $result =] 0] " "] .] end-7 ]
     if {$ret == 1} { 
      puts $error
        puts "walk ARP Inspection dynamic table Failed!"
    } else {
        puts "walk ARP Inspection dynamic table successed!"
        puts "++++ARP Inspection dynamic table++++"
        puts "  PORT        VLAN             MAC                       IP "
        puts "  $port           $vlan             $b        $ip "
        puts "++++ARP Inspection dynamic table++++"
    }
}
