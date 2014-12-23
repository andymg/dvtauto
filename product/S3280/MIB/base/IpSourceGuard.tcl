#!/bin/tcl

#Filename: IpSourceGuard.tcl
#History:
#        1/14/2014- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2014

namespace eval IPSGoid {
set tnIPSourceGuardGlobalMode(oid) 1.3.6.1.4.1.868.2.5.31.1.1.1.1.1
set tnIPSourceGuardGlobalMode(type) INTEGER 
set tnIPSourceGuardGlobalMode(access) read-write
set tnIPSourceGuardDynamicToStatic(oid) 1.3.6.1.4.1.868.2.5.31.1.1.1.1.2
set tnIPSourceGuardDynamicToStatic(type) TruthValue 
set tnIPSourceGuardDynamicToStatic(access) read-write
set tnIPSourceGuardIfMode(oid) 1.3.6.1.4.1.868.2.5.31.1.1.2.1.1
set tnIPSourceGuardIfMode(type) INTEGER
set tnIPSourceGuardIfMode(access) read-write
set tnIPSourceGuardIfMaxDynamicClients(oid) 1.3.6.1.4.1.868.2.5.31.1.1.2.1.2
set tnIPSourceGuardIfMaxDynamicClients(type) INTEGER 
set tnIPSourceGuardIfMaxDynamicClients(access) read-write
set tnIPSourceGuardStaticMacAddress(oid) 1.3.6.1.4.1.868.2.5.31.1.1.3.1.6
set tnIPSourceGuardStaticMacAddress(type) MacAddress 
set tnIPSourceGuardStaticMacAddress(access) read-create
set tnIPSourceGuardStaticRowStatus(oid) 1.3.6.1.4.1.868.2.5.31.1.1.3.1.7
set tnIPSourceGuardStaticRowStatus(type) RowStatus 
set tnIPSourceGuardStaticRowStatus(access) read-create
set tnIPSourceGuardDynamicMacAddress(oid) 1.3.6.1.4.1.868.2.5.31.1.1.4.1.6
set tnIPSourceGuardDynamicMacAddress(type)  INTEGER
set tnIPSourceGuardDynamicMacAddress(access) read-only
}

namespace eval IPSG {
namespace	export  *
}


#set Ip Source Guard  global mode 
proc IPSG::setglobalMode { dut value } {
	set mode [string toupper $value]
	switch   -exact -- $mode {

		DISABLE    {set modevalue 2}
		ENABLE     {set modevalue 1}
	}
    set cmd "exec snmpset $::session $dut"
    set setIpSourceGuardMode "$IPSGoid::tnIPSourceGuardGlobalMode(oid).1 [getType $IPSGoid::tnIPSourceGuardGlobalMode(type)] $modevalue"
    append cmd " $setIpSourceGuardMode"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
    	puts $error
        puts "set Ip Source Guard global mode  \"$mode\" for  dut $dut Failed!"
    } else {

        puts "set Ip Source Guard global mode  \"$mode\" for  dut $dut successed!"
    }
}

#set Ip Source Guard port mode 
proc IPSG::setportMode { dut  port value } {
    set mode [string toupper $value]
    switch   -exact -- $mode {

        DISABLE    {set modevalue 2}
        ENABLE     {set modevalue 1}
    }
    set cmd "exec snmpset $::session $dut"
    set setIpSGportMode "$IPSGoid::tnIPSourceGuardIfMode(oid).$port [getType $IPSGoid::tnIPSourceGuardIfMode(type)] $modevalue"
    append cmd " $setIpSGportMode"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "set Ip Source Guard port $port  mode  \"$mode\" for  dut $dut Failed!"
    } else {

        puts "set Ip Source Guard port $port  mode  \"$mode\" for  dut $dut successed!"
    }
}

#set max dynamic client 
proc IPSG::MaxDynaClient { dut port value} {
	set valuemode [string toupper $value]
	switch $valuemode {
    0            {set modevalue 0}
    1            {set modevalue 1}
    2            {set modevalue 2}
    UNLIMITED    {set modevalue 65535}
	}
    set cmd "exec snmpset $::session $dut"
    set translateDtoS "$IPSGoid::tnIPSourceGuardIfMaxDynamicClients(oid).$port [getType $IPSGoid::tnIPSourceGuardIfMaxDynamicClients(type)] $modevalue"
    append cmd " $translateDtoS"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "set Ip Source Guard port $port  Max Dynamic client value  \"$value\" for  dut $dut Failed!"
    } else {
        puts "set Ip Source Guard port $port  Max Dynamic client value   \"$value\" for  dut $dut successed!"
    }
}

#create static table
##input mac address format is "000000111111" 
##RowStatus value :active(1),notInService(2),notReady(3),createAndGo(4),createAndWait(5),destory(5)
##example  IPSG::createStaticTable $dut1  2 8 000000555555 192.16.1.1
proc IPSG::createStaticTable { dut  port vlan mac ip } {
       set cmd "exec snmpset $::session $dut"
       set creStaticTable " $IPSGoid::tnIPSourceGuardStaticMacAddress(oid).$port.$vlan.1.4.$ip.32 [getType $IPSGoid::tnIPSourceGuardStaticMacAddress(type)] $mac "
       set rowStatus "  $IPSGoid::tnIPSourceGuardStaticRowStatus(oid).$port.$vlan.1.4.$ip.32  [getType $IPSGoid::tnIPSourceGuardStaticRowStatus(type)]  4"
       append creStaticTable " $rowStatus"
       append cmd "$creStaticTable"
       set ret [catch {eval $cmd} error] 
        if {$ret == 1} { 
          puts $error
          puts "create a new entry in Ip Source Guard static table  Failed!"
        } else {
          puts "create a new entry in Ip Source Guard static table successed!"
          puts "new Ip Source Guard static entry is : port $port vlan is $vlan mac address is $mac and ip address is $ip "
        }
}


# translate Dynamic table to static table
proc IPSG::transDtoS { dut  } {
    set cmd "exec snmpset $::session $dut"
    set translateDtoS "$IPSGoid::tnIPSourceGuardDynamicToStatic(oid).1 [getType $IPSGoid::tnIPSourceGuardDynamicToStatic(type)] 1"
    append cmd " $translateDtoS"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
      puts $error
        puts "Translating Ip Source Guard Dynamic table to Static table Failed!"
    } else {
        puts "Translating Ip Source Guard Dynamic table to Static table successed!"
    }
}




#walk IPSG Inspeciton Dynamic table
proc IPSG::walkdynamictable {dut} {
     set cmd "exec snmpwalk $::session $dut"
     set walkdynatable "$IPSGoid::tnIPSourceGuardDynamicMacAddress(oid) [getType $IPSGoid::tnIPSourceGuardDynamicMacAddress(type)] "
     append cmd " $walkdynatable"
     set result [eval $cmd]
     set ret [catch {eval $cmd} error]
     set result [eval $cmd]
     set a  [string trim [lindex  [split $result =] 1 ] " "]
     set b "No Such Instance currently exists at this OID"
    if [string equal $a $b] {
       puts "no binding entry in Ip Source Guard dynamic table"
       return 0
    } else {
         #the result of processing snmpwalk command like this 
          #SNMPv2-SMI::enterprises.868.2.5.31.1.1.4.1.6.5.1.1.4.45.54.55.45.32 = Hex-STRING: 00 14 22 8C 3B B9
          set mac [string trim  [lindex [split $result : ] 3]  " "]
          set ipaddress  [lrange  [split [string trim [lindex  [split $result =] 0] " "] .] end-4 end-1]
         # set ip [byte2IpAddr "$ipaddress"]
         set ip [join $ipaddress .]
          set vlan  [lindex  [split [string trim [lindex  [split $result =] 0] " "] .] end-7 ]
           set  port   [lindex  [split [string trim [lindex  [split $result =] 0] " "] .] end-8 ]
          if {$ret == 1} { 
               puts $error
               puts "walk Ip Source Guard dynamic table Failed!"
            } else {
              puts "walk Ip Source Guard dynamic table successed!"
              puts "++++Ip Source Guard dynamic table++++"
              puts "  PORT        VLAN             MAC                       IP "
              puts "  $port           $vlan             $mac        $ip "
              puts "++++Ip Source Guard dynamic table++++"
              return 1
            }
    }
}


#walk IPSG Inspeciton static table
proc IPSG::walkStatictable {dut} {
     set cmd "exec snmpwalk $::session $dut"
     set walkstatable "$IPSGoid::tnIPSourceGuardStaticMacAddress(oid) [getType $IPSGoid::tnIPSourceGuardStaticMacAddress(type)] "
     append cmd " $walkstatable"
     set result [eval $cmd]
     set ret [catch {eval $cmd} error]
     set result [eval $cmd]
     set a  [string trim [lindex  [split $result =] 1 ] " "]
     set b "No Such Instance currently exists at this OID"
    if [string equal $a $b] {
       puts "no binding entry in Ip Source Guard static table"
       return 0
    } else {
         #the result of processing snmpwalk command like this 
          #SNMPv2-SMI::enterprises.868.2.5.31.1.1.4.1.6.5.1.1.4.45.54.55.45.32 = Hex-STRING: 00 14 22 8C 3B B9
          set mac [string trim  [lindex [split $result : ] 3]  " "]
          set ipaddress  [lrange  [split [string trim [lindex  [split $result =] 0] " "] .] end-4 end-1]
         # set ip [byte2IpAddr "$ipaddress"]
         set ip [join $ipaddress .]
          set vlan  [lindex  [split [string trim [lindex  [split $result =] 0] " "] .] end-7 ]
           set  port   [lindex  [split [string trim [lindex  [split $result =] 0] " "] .] end-8 ]
          if {$ret == 1} { 
               puts $error
               puts "walk Ip Source Guard static table Failed!"
            } else {
              puts "walk Ip Source Guard static table successed!"
              puts "++++Ip Source Guard static table++++"
              puts "  PORT        VLAN             MAC                       IP "
              puts "  $port           $vlan             $mac        $ip "
              puts "++++Ip Source Guard static table++++"
              return 1
            }
    }
}