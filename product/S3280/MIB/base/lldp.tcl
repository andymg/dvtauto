#!/bin/tcl

#Filename: lldp.tcl
#Target: lldp private module
#History:
#        11/20/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

namespace eval  lldpoid {
    set lldpMessageTxInterval(oid) 1.0.8802.1.1.2.1.1.1
    set lldpMessageTxInterval(type) Integer32 
    set lldpMessageTxInterval(access) read-write
    set lldpMessageTxHoldMultiplier(oid) 1.0.8802.1.1.2.1.1.2
    set lldpMessageTxHoldMultiplier(type) Integer32 
    set lldpMessageTxHoldMultiplier(access) read-write
    set lldpReinitDelay(oid) 1.0.8802.1.1.2.1.1.3
    set lldpReinitDelay(type) Integer32 
    set lldpReinitDelay(access) read-write
    set lldpTxDelay(oid) 1.0.8802.1.1.2.1.1.4
    set lldpTxDelay(type) Integer32 
    set lldpTxDelay(access) read-write
    set lldpNotificationInterval(oid) 1.0.8802.1.1.2.1.1.5
    set lldpNotificationInterval(type) Integer32 
    set lldpNotificationInterval(access) read-write
    set lldpPortConfigAdminStatus(oid) 1.0.8802.1.1.2.1.1.6.1.2
    set lldpPortConfigAdminStatus(type) INTEGER 
    set lldpPortConfigAdminStatus(access) read-write
    set lldpPortConfigNotificationEnable(oid) 1.0.8802.1.1.2.1.1.6.1.3
    set lldpPortConfigNotificationEnable(type) TruthValue 
    set lldpPortConfigNotificationEnable(access) read-write
    set lldpPortConfigTLVsTxEnable(oid) 1.0.8802.1.1.2.1.1.6.1.4
    set lldpPortConfigTLVsTxEnable(type) Bits 
    set lldpPortConfigTLVsTxEnable(access) read-write
    set lldpConfigManAddrPortsTxEnable(oid) 1.0.8802.1.1.2.1.1.7.1.1
    set lldpConfigManAddrPortsTxEnable(type) Bits 
    set lldpConfigManAddrPortsTxEnable(access) read-write
    set lldpStatsRemTablesLastChangeTime(oid) 1.0.8802.1.1.2.1.2.1
    set lldpStatsRemTablesLastChangeTime(type) TimeStamp 
    set lldpStatsRemTablesLastChangeTime(access) read-only
    set lldpStatsRemTablesInserts(oid) 1.0.8802.1.1.2.1.2.2
    set lldpStatsRemTablesInserts(type) ZeroBasedCounter32 
    set lldpStatsRemTablesInserts(access) read-only
    set lldpStatsRemTablesDeletes(oid) 1.0.8802.1.1.2.1.2.3
    set lldpStatsRemTablesDeletes(type) ZeroBasedCounter32 
    set lldpStatsRemTablesDeletes(access) read-only
    set lldpStatsRemTablesDrops(oid) 1.0.8802.1.1.2.1.2.4
    set lldpStatsRemTablesDrops(type) ZeroBasedCounter32 
    set lldpStatsRemTablesDrops(access) read-only
    set lldpStatsRemTablesAgeouts(oid) 1.0.8802.1.1.2.1.2.5
    set lldpStatsRemTablesAgeouts(type) ZeroBasedCounter32 
    set lldpStatsRemTablesAgeouts(access) read-only
    set lldpStatsTxPortFramesTotal(oid) 1.0.8802.1.1.2.1.2.6.1.2
    set lldpStatsTxPortFramesTotal(type) Counter32 
    set lldpStatsTxPortFramesTotal(access) read-only
    set lldpStatsRxPortFramesDiscardedTotal(oid) 1.0.8802.1.1.2.1.2.7.1.2
    set lldpStatsRxPortFramesDiscardedTotal(type) Counter32 
    set lldpStatsRxPortFramesDiscardedTotal(access) read-only
    set lldpStatsRxPortFramesErrors(oid) 1.0.8802.1.1.2.1.2.7.1.3
    set lldpStatsRxPortFramesErrors(type) Counter32 
    set lldpStatsRxPortFramesErrors(access) read-only
    set lldpStatsRxPortFramesTotal(oid) 1.0.8802.1.1.2.1.2.7.1.4
    set lldpStatsRxPortFramesTotal(type) Counter32 
    set lldpStatsRxPortFramesTotal(access) read-only
    set lldpStatsRxPortTLVsDiscardedTotal(oid) 1.0.8802.1.1.2.1.2.7.1.5
    set lldpStatsRxPortTLVsDiscardedTotal(type) Counter32 
    set lldpStatsRxPortTLVsDiscardedTotal(access) read-only
    set lldpStatsRxPortTLVsUnrecognizedTotal(oid) 1.0.8802.1.1.2.1.2.7.1.6
    set lldpStatsRxPortTLVsUnrecognizedTotal(type) Counter32 
    set lldpStatsRxPortTLVsUnrecognizedTotal(access) read-only
    set lldpStatsRxPortAgeoutsTotal(oid) 1.0.8802.1.1.2.1.2.7.1.7
    set lldpStatsRxPortAgeoutsTotal(type) ZeroBasedCounter32 
    set lldpStatsRxPortAgeoutsTotal(access) read-only
    set lldpLocChassisIdSubtype(oid) 1.0.8802.1.1.2.1.3.1
    set lldpLocChassisIdSubtype(type) LldpChassisIdSubtype 
    set lldpLocChassisIdSubtype(access) read-only
    set lldpLocChassisId(oid) 1.0.8802.1.1.2.1.3.2
    set lldpLocChassisId(type) LldpChassisId 
    set lldpLocChassisId(access) read-only
    set lldpLocSysName(oid) 1.0.8802.1.1.2.1.3.3
    set lldpLocSysName(type) SnmpAdminString 
    set lldpLocSysName(access) read-only
    set lldpLocSysDesc(oid) 1.0.8802.1.1.2.1.3.4
    set lldpLocSysDesc(type) SnmpAdminString 
    set lldpLocSysDesc(access) read-only
    set lldpLocSysCapSupported(oid) 1.0.8802.1.1.2.1.3.5
    set lldpLocSysCapSupported(type) LldpSystemCapabilitiesMap 
    set lldpLocSysCapSupported(access) read-only
    set lldpLocSysCapEnabled(oid) 1.0.8802.1.1.2.1.3.6
    set lldpLocSysCapEnabled(type) LldpSystemCapabilitiesMap 
    set lldpLocSysCapEnabled(access) read-only
    set lldpLocPortIdSubtype(oid) 1.0.8802.1.1.2.1.3.7.1.2
    set lldpLocPortIdSubtype(type) LldpPortIdSubtype 
    set lldpLocPortIdSubtype(access) read-only
    set lldpLocPortId(oid) 1.0.8802.1.1.2.1.3.7.1.3
    set lldpLocPortId(type) LldpPortId 
    set lldpLocPortId(access) read-only
    set lldpLocPortDesc(oid) 1.0.8802.1.1.2.1.3.7.1.4
    set lldpLocPortDesc(type) SnmpAdminString 
    set lldpLocPortDesc(access) read-only
    set lldpLocManAddrLen(oid) 1.0.8802.1.1.2.1.3.8.1.3
    set lldpLocManAddrLen(type) Integer32 
    set lldpLocManAddrLen(access) read-only
    set lldpLocManAddrIfSubtype(oid) 1.0.8802.1.1.2.1.3.8.1.4
    set lldpLocManAddrIfSubtype(type) LldpManAddrIfSubtype 
    set lldpLocManAddrIfSubtype(access) read-only
    set lldpLocManAddrIfId(oid) 1.0.8802.1.1.2.1.3.8.1.5
    set lldpLocManAddrIfId(type) Integer32 
    set lldpLocManAddrIfId(access) read-only
    set lldpLocManAddrOID(oid) 1.0.8802.1.1.2.1.3.8.1.6
    set lldpLocManAddrOID(type) ObjectID 
    set lldpLocManAddrOID(access) read-only
    set lldpRemChassisIdSubtype(oid) 1.0.8802.1.1.2.1.4.1.1.4
    set lldpRemChassisIdSubtype(type) LldpChassisIdSubtype 
    set lldpRemChassisIdSubtype(access) read-only
    set lldpRemChassisId(oid) 1.0.8802.1.1.2.1.4.1.1.5
    set lldpRemChassisId(type) LldpChassisId 
    set lldpRemChassisId(access) read-only
    set lldpRemPortIdSubtype(oid) 1.0.8802.1.1.2.1.4.1.1.6
    set lldpRemPortIdSubtype(type) LldpPortIdSubtype 
    set lldpRemPortIdSubtype(access) read-only
    set lldpRemPortId(oid) 1.0.8802.1.1.2.1.4.1.1.7
    set lldpRemPortId(type) LldpPortId 
    set lldpRemPortId(access) read-only
    set lldpRemPortDesc(oid) 1.0.8802.1.1.2.1.4.1.1.8
    set lldpRemPortDesc(type) SnmpAdminString 
    set lldpRemPortDesc(access) read-only
    set lldpRemSysName(oid) 1.0.8802.1.1.2.1.4.1.1.9
    set lldpRemSysName(type) SnmpAdminString 
    set lldpRemSysName(access) read-only
    set lldpRemSysDesc(oid) 1.0.8802.1.1.2.1.4.1.1.10
    set lldpRemSysDesc(type) SnmpAdminString 
    set lldpRemSysDesc(access) read-only
    set lldpRemSysCapSupported(oid) 1.0.8802.1.1.2.1.4.1.1.11
    set lldpRemSysCapSupported(type)  LldpSystemCapabilitiesMap
    set lldpRemSysCapSupported(access) read-write
    set lldpRemSysCapEnabled(oid) 1.0.8802.1.1.2.1.4.1.1.12
    set lldpRemSysCapEnabled(type) LldpSystemCapabilitiesMap 
    set lldpRemSysCapEnabled(access) read-only
    set lldpRemManAddrIfSubtype(oid) 1.0.8802.1.1.2.1.4.2.1.3
    set lldpRemManAddrIfSubtype(type) LldpManAddrIfSubtype 
    set lldpRemManAddrIfSubtype(access) read-only
    set lldpRemManAddrIfId(oid) 1.0.8802.1.1.2.1.4.2.1.4
    set lldpRemManAddrIfId(type) Integer32 
    set lldpRemManAddrIfId(access) read-only
    set lldpRemManAddrOID(oid) 1.0.8802.1.1.2.1.4.2.1.5
    set lldpRemManAddrOID(type) OBJECT 
    set lldpRemManAddrOID(access) IDENTIFIER
    set sysNameOID(oid) 1.3.6.1.2.1.1.5
    set sysNameOID(type) DisplayString
    set sysName(access) read-write
    set ipAdEntAddrOID(oid) 1.3.6.1.2.1.4.20.1.1
    set ipAdEntAddrOID(type) IpAddress
    set ipAdEntAddr(access) read-only
    set lldpPortConfigCdpAwareEnabledOID(oid) 1.3.6.1.4.1.868.2.5.137.2.1.1.1
    set lldpPortConfigCdpAwareEnabled(type) Integer32 
    set lldpPortConfigCdpAwareEnabled(access) read-write
}  

namespace eval lldp {
namespace export *
}

#LLDP txInterval from 5s~32768s ,default is 30s 
#1.get lldp txInterval  value 
proc lldp::gettxInterval { dut }  { 
    set txInterval "exec snmpget $::session $dut $lldpoid::lldpMessageTxInterval(oid).0 "
    set ret [catch {eval $txInterval} error]
    set txintervalvalue [eval $txInterval ]
    if { $ret == 1 } {
        puts "error $error"
    }  
       return [string trim [lindex [split $txintervalvalue :] 1] " "]
}

#2.get dut management ip address
proc ManIPadd { dut }  { 
    set ManIP "exec snmpwalk $::session $dut $lldpoid::ipAdEntAddrOID(oid) "
    set ret [catch {eval $ManIP} error]
    set  ip [eval $ManIP ]
    if { $ret == 1 } {
        puts "error $error"
    }  
       return  [string trim [lindex [split $ip :] 3] " "]
}

#3.set a new value for LLDP txInterval
proc lldp::settxInterval { dut value } {
    set cmd "exec snmpset $::session $dut"
    set setTxInterval "$lldpoid::lldpMessageTxInterval(oid).0 [getType $lldpoid::lldpMessageTxInterval(type)] $value"
    append cmd " $setTxInterval"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { puts $error
                puts "set lldp txInterval value for $dut:  $value Failed!"; return 0
            }
                puts "set lldp txInterval value for $dut:  $value successed!"
    }

#4.set a new value for LLDP txdelay 
proc lldp::settxdelay { dut value } {
    set cmd "exec snmpset $::session $dut"
    set setTxdelay "$lldpoid::lldpTxDelay(oid).0 [getType $lldpoid::lldpTxDelay(type)] $value"
    append cmd " $setTxdelay"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { puts $error
                puts "set lldp txdelay value for $dut:  $value Failed!"; return 0
            }
                puts "set lldp txdely value for $dut:  $value successed!"
    }

#5.set a new value for LLDP txdelay 
proc lldp::settxReinit { dut value } {
    set cmd "exec snmpset $::session $dut"
    set setTxreinit "$lldpoid::lldpReinitDelay(oid).0 [getType $lldpoid::lldpReinitDelay(type)] $value"
    append cmd " $setTxreinit"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { puts $error
                puts "set lldp txReinit value for $dut:  $value Failed!"; return 0
            }
                puts "set lldp txReinit value for $dut:  $value successed!"
    }

#6.set lldp port mode 
# (Enable means TXANDRX ,tyevalue 4 is Disable.) 
proc lldp::setlldpportmode { dut port mode } {
	set cmd "exec snmpset $::session $dut "
	set Type [string toupper $mode]
    if {$Type == "TXONLY"} {
    	set typeValue 1
    } elseif {$Type == "RXONLY"} {
    	set typeValue 2
    } elseif {$Type == "TXANDRX"} {
    	set typeValue 3
    } else {
    	set typeValue 4
    } 
    set setPortmode "$lldpoid::lldpPortConfigAdminStatus(oid).$port [getType $lldpoid::lldpPortConfigAdminStatus(type)] $typeValue"
    append cmd "$setPortmode"
    puts "$cmd"
    set ret [catch {eval $cmd} error]
   if { $ret == 1 } { puts "lldp: set port mode  $mode for  $port  Failed!"}
    puts "lldp: set port mode  $mode for $dut port $port  successed!"
}
proc lldp::getlldpportmode { dut port } {
    set cmd "exec snmpget $::session $dut "
    set Portmode "$lldpoid::lldpPortConfigAdminStatus(oid).$port "
    append cmd "$Portmode"
    puts "$cmd"
    set ret [catch {eval $cmd} error]
    set Rescmd [eval $cmd]
    set result  [string  trim [lindex [split $Rescmd : ] 1] " "] 
    if { $ret == 1 } { 
        puts "lldp: get lldp port mode   Failed!"
    } else {
        puts "lldp: get lldp port mode successed "  
        return $result  
    }
}

#7. set lldp txhold
proc lldp::settxHold { dut value } {
    set cmd "exec snmpset $::session $dut"
    set setTxHold "$lldpoid::lldpMessageTxHoldMultiplier(oid).0 [getType $lldpoid::lldpMessageTxHoldMultiplier(type)] $value"
    append cmd " $setTxHold"
    set ret [catch {eval $cmd} error]
    if {$ret} { puts $error
            puts "set lldp txHold value for $dut:  $value Failed!" 
    } else {
            puts "set lldp txHold value for $dut:  $value successed!"
    }
}
#8.set system name 
proc lldp::setsystmName { dut  name } {
    set cmd "exec snmpset $::session $dut "
    set setsysname "$lldpoid::sysNameOID(oid).0 [getType $lldpoid::sysNameOID(type)] $name"
    append cmd "$setsysname"
    set ret [catch {eval $cmd} error]
   if { $ret } { puts "set system name $name for dut $dut  Failed!"}
    puts "set system name $name for dut $dut  successed!"
}

#set lldp port optional TLV

#get LLDP remote system table as following :
#9. get lldp remoteChiss ID the format is  "00 c0 f2 22 67 4f"
proc lldp::walkRemChassisID {dut }  { 
    set remChassisID "exec snmpwalk $::session $dut $lldpoid::lldpRemChassisId(oid) "
    set ret [catch {eval $remChassisID} error]
    set chassid [eval $remChassisID]
    puts "Remchassid is $chassid"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $chassid =] 1] " "]
    set a [string trim [lindex [string trim [split $chassid =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $chassid
    } else {
       return [string toupper [concat [split [string trim [lindex [split $chassid \"\"] 1] " "] -]]]
    }   
}

#10. get lldp remotePort description 
proc lldp::walkRemPortDesc {dut }  { 
    set remRemPortDesc "exec snmpwalk $::session $dut $lldpoid::lldpRemPortDesc(oid) "
    set ret [catch {eval $remRemPortDesc } error]
    set PortDesc [eval $remRemPortDesc]
    puts "RemPortDesc is $PortDesc"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $PortDesc =] 1] " "]
    set a [string trim [lindex [string trim [split $PortDesc =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $PortDesc
    } else {
       return [string toupper  [string trim [lindex [split $PortDesc \"\"] 1] " "] ]
    }   
}

#11. get lldp remotSysname
proc lldp::walkRemSysName {dut }  { 
    set remRemSysName "exec snmpwalk $::session $dut $lldpoid::lldpRemSysName(oid) "
    set ret [catch {eval $remRemSysName } error]
    set sysName [eval $remRemSysName]
    puts "RemSysname  is $sysName"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $sysName =] 1] " "]
    set a [string trim [lindex [string trim [split $sysName =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $sysName
    } else {
       return [string toupper  [string trim [lindex [split $sysName \"\"] 1] " "] ]
    }   
}

#12. get lldp remotSys description
proc lldp::walkRemSysDesc {dut }  { 
    set remRemSysDesc "exec snmpwalk $::session $dut $lldpoid::lldpRemSysDesc(oid) "
    set ret [catch {eval $remRemSysDesc } error]
    set sysDesc [eval $remRemSysDesc]
    puts "RemSysDesc  is $sysDesc"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $sysDesc =] 1] " "]
    set a [string trim [lindex [string trim [split $sysDesc =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $sysDesc
    } else {
       return [string toupper  [string trim [lindex [split $sysDesc \"\"] 1] " "] ]
    }   
}

#13. get lldp remotSys management ip 
#get dut2 ip address from dut1 in lldp remote system table

proc lldp::walkRemManAddr {dut1  dut2 }  { 
    set remRemManAddr "exec snmpwalk $::session $dut1 $lldpoid::lldpRemManAddrIfId(oid) "
    set ret [catch {eval $remRemManAddr } error]
    set sysManAddr [eval $remRemManAddr]
    puts "RemsysManAddr  is $sysManAddr"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $sysManAddr =] 1] " "]
    set a [string trim [lindex [string trim [split $sysManAddr =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    set remoteIP [ManIPadd $dut2]
    puts "remote device ip address is:$remoteIP"
    set ipLength  [string length [string trim [ManIPadd $dut2] " "]]
    set c [expr $ipLength-1]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $sysManAddr
    } else {
       return [string range  [string trim [lindex [split $sysManAddr =] 0] " "]  end-$c  end]
    }   
}

#14. get lldp remotSys compability
#values form :LLDP system compability 
#bit map as following
#value  0          1             2           3           4         5             6                     7
#cap   other    repeater    bridge   wlanAccessPoint   router  telephone   docsisCableDevice      stationOnly
proc lldp::walkRemSysCapSupported {dut }  { 
    set remRemSysCap "exec snmpwalk $::session $dut $lldpoid::lldpRemSysCapSupported(oid) "
    set ret [catch {eval $remRemSysCap } error]
    set sysCap [eval $remRemSysCap]
    puts "RemsysCap  is $sysCap"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $sysCap =] 1] " "]
    set a [string trim [lindex [string trim [split $sysCap =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $sysCap
    } else {
       return [string toupper  [string trim [lindex [split $sysCap :] 1] " "] ]
    }   
}

#get LLDP local system table as following 

#15. get lldp Local Chiss ID the format is  "00 c0 f2 22 67 4f"
proc lldp::getLocChassisID {dut }  { 
    set locChassisID "exec snmpget $::session $dut $lldpoid::lldpLocChassisId(oid).0 "
    set ret [catch {eval $locChassisID} error]
    set chassid [eval $locChassisID]
    puts "LocChassid is $chassid"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $chassid =] 1] " "]
    set a [string trim [lindex [string trim [split $chassid =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $chassid
    } else {
       return [string toupper [concat [split [string trim [lindex [split $chassid \"\"] 1] " "] -]]]
    }   
}

#16. get lldp remotePort description 
proc lldp::getlocPortDesc {dut port}  { 
    set locPortDesc "exec snmpget $::session $dut $lldpoid::lldpLocPortDesc(oid).$port "
    set ret [catch {eval $locPortDesc } error]
    set PortDesc [eval $locPortDesc]
    puts "LocPortDesc is $PortDesc"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $PortDesc =] 1] " "]
    set a [string trim [lindex [string trim [split $PortDesc =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $PortDesc
    } else {
       return [string toupper  [string trim [lindex [split $PortDesc \"\"] 1] " "] ]
    }   
}
#17. get lldp local Sysname
proc lldp::getlocSysName {dut }  { 
    set locSysName "exec snmpget $::session $dut $lldpoid::lldpLocSysName(oid).0 "
    set ret [catch {eval $locSysName } error]
    set sysName [eval $locSysName]
    puts "LocSysname  is $sysName"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $sysName =] 1] " "]
    set a [string trim [lindex [string trim [split $sysName =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $sysName
    } else {
       return [string toupper  [string trim [lindex [split $sysName \"\"] 1] " "] ]
    }   
}

#18. get lldp local Sys description
proc lldp::getlocSysDesc {dut }  { 
    set locSysDesc "exec snmpget $::session $dut $lldpoid::lldpLocSysDesc(oid).0 "
    set ret [catch {eval $locSysDesc } error]
    set sysDesc [eval $locSysDesc]
    puts "LocsysDesc  is $sysDesc"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $sysDesc =] 1] " "]
    set a [string trim [lindex [string trim [split $sysDesc =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $sysDesc
    } else {
       return [string toupper  [string trim [lindex [split $sysDesc \"\"] 1] " "] ]
    }   
}
#19. get lldp local Sys compability
#values form :LLDP system compability 
#bit map as following
#value  0          1             2           3           4         5             6                     7
#cap   other    repeater    bridge   wlanAccessPoint   router  telephone   docsisCableDevice      stationOnly
proc lldp::getLocSysCapSupported {dut } { 
    set locSysCap "exec snmpget $::session $dut $lldpoid::lldpLocSysCapSupported(oid).0 "
    set ret [catch {eval $locSysCap } error]
    set sysCap [eval $locSysCap]
    puts "LocsysCap  is $sysCap"
    set noexist "No Such Instance currently exists at this OID"
    set renn  [string trim [lindex [split $sysCap =] 1] " "]
    set a [string trim [lindex [string trim [split $sysCap =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    if { $ret == 1 } {
        puts "error $error"
    } elseif {  $b  } {
       return $sysCap
    } else {
       return   [string toupper  [string trim [lindex [split $sysCap :] 1] " "] ]
    }   
}
#20 set port option TLV except Man TLV 
proc lldp::setportOptionalTLV { dut port value } {
    set cmd "exec snmpset $::session $dut"
    set setOptionalTLV "$lldpoid::lldpPortConfigTLVsTxEnable(oid).$port [getType $lldpoid::lldpPortConfigTLVsTxEnable(type)] $value"
    append cmd " $setOptionalTLV"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "set lldp OptionalTLV  value for $dut port $port:  $value Failed!"; return 0
    }
    puts "set lldp OptionalTLV  value for $dut port $port:  $value  successed!"
}
#21 check port option TLV function  except Man TLV
proc lldp::checkportOptionalTLV { dut1 dut2 port value } {
   setToFactoryDefault $dut1
   setToFactoryDefault $dut2
   after 6000
   lldp::settxInterval  $dut1 600
   lldp::settxInterval  $dut2 600
   lldp::settxHold $dut1 10
   lldp::settxHold $dut2 10
   lldp::setsystmName  $dut1  ming 
   set Hexvalue [string toupper $value]
   lldp::setportOptionalTLV  $dut1 $port  $Hexvalue
   lldp::setlldpportmode   $dut1  $port DISABLE
   lldp::setlldpportmode   $dut2  $port DISABLE
   lldp::setlldpportmode   $dut1  $port TXANDRX
   lldp::setlldpportmode   $dut2  $port TXANDRX
   after 6000
    set a [string equal  [lldp::walkRemPortDesc  $dut2] [lldp::getlocPortDesc $dut1 $port]]
    set b [string equal  [lldp::walkRemSysName    $dut2] [lldp::getlocSysName  $dut1 ]]
    set c [string equal  [lldp::walkRemSysDesc   $dut2] [lldp::getlocSysDesc $dut1 ]]
    set d [string equal  [lldp::walkRemSysCapSupported $dut2] [lldp::getLocSysCapSupported $dut1]]
    set mm [string equal $Hexvalue 00]
    if { [string equal $Hexvalue 00] } {
            if {$a == 0 && $b == 0 && $c == 0 && $d == 0 } {
                passed OptionalTLV    "Doesn't Select all OptionalTLV except Mgmt Add test successed"
            } else {
                failed  OptionalTLV  "Doesn't Select all OptionalTLV except Mgmt Add test failed"
            }
    } elseif { [string equal $Hexvalue 10] } {
            if {$d == 1 && ( $a == 0 || $b ==0 || 0 || $c == 0)} {
                passed OptionalTLV    "Sys Capa TLV  test successed"
            } else {
                failed  OptionalTLV  "Sys Capa TLV  test failed"
            } 

   } elseif {[string equal $Hexvalue 20]} {
            if {$c == 1 && ( $a == 0 || $b == 0|| 0 || $d == 0)} {
                passed OptionalTLV    "Sys Descr TLV  test successed"
            } else {
                failed  OptionalTLV  "Sys Descr TLV  test failed"
            } 
   } elseif {[string equal $Hexvalue 40]} { 
           if {$b == 1 && ( $a == 0 || $c == 0 || 0 || $d == 0)} {
                passed OptionalTLV    "Sys Name TLV  test successed"
            } else {
               failed  OptionalTLV  "Sys Name TLV  test failed"
            } 
   } elseif {[string equal $Hexvalue 80]} { 
           if {$a == 1 && ( $b == 0 || $c == 0 || 0 || $d == 0)} {
                passed OptionalTLV    "Port Descr TLV  test successed"
            } else {
               failed  OptionalTLV  "Port Descr TLV test  failed"
            }
   } elseif {[string equal $Hexvalue "F0"]} {
            if {$a == 1 && $b == 1 && $c == 1 && $d == 1} {
                passed OptionalTLV    "Select all OptionalTLV except Mgmt Add test successed"
            } else {
                failed  OptionalTLV  "Select all OptionalTLV except Mgmt Add test failed"
            }           
   } else {

         puts "Optional TLV value doesn't correct ,which value only include \"00 , 01,02,04,08,F0\" "
    }
}

#the value format must be XXCO,XX identify port bit maps ,11C0 means enable port 1 and port5 Man Add TLV,FFCO means enable 
#all ports' Man Add TLV
#22 enable port Man
proc  lldp::enableportManTLV {dut value} {
    set cmd "exec snmpset $::session $dut"
    set setOptionalTLV "$lldpoid::lldpConfigManAddrPortsTxEnable(oid).1.4.$dut [getType $lldpoid::lldpConfigManAddrPortsTxEnable(type)] $value"
    append cmd " $setOptionalTLV"
    puts "cmd is $cmd"
    set ret [catch {eval $cmd} error]
    if {$ret == 1} { 
        puts $error
        puts "Enable lldp port  OptionalTLV  Mgmt Addr Failed!"; return 0
    } else {
        puts "Enable lldp port  OptionalTLV  Mgmt Addr  successed!"
    }
}
#23 select port management TLV
#the value format must be XXCO,XX identify port bit maps ,11C0 means enable port 1 and port5 Man Add TLV,FFCO means enable 
#all ports' Man Add TLV
proc lldp::selectportManTLV {dut1 dut2 port value} {
   setToFactoryDefault $dut1
   setToFactoryDefault $dut2
   after 6000
   lldp::settxInterval  $dut1 600
   lldp::settxInterval  $dut2 600
   lldp::settxHold $dut1 10
   lldp::settxHold $dut2 10
   lldp::enableportManTLV $dut1 $value
   lldp::setlldpportmode  $dut1 $port TXANDRX
   lldp::setlldpportmode  $dut2 $port TXANDRX
   after 6000
   set dut1ip [lldp::walkRemManAddr $dut2 $dut1]
   if {[string equal $dut1ip $dut1]} {
        passed OptionalTLV  "Man Add TLV test succeed "
    } else {
        failed OptionalTLV  "Man Add TLV test failed " 
    }
}
#24 didn't select port management TLV 
#the value format must be XXCO,XX identify port bit maps ,11C0 means enable port 1 and port5 Man Add TLV,FFCO means enable 
#all ports' Man Add TLV
proc lldp::NotselectportManTLV {dut1 dut2 port value} {
   setToFactoryDefault $dut1
   setToFactoryDefault $dut2
   after 6000
   lldp::settxInterval  $dut1 600
   lldp::settxInterval  $dut2 600
   lldp::settxHold $dut1 10
   lldp::settxHold $dut2 10
   lldp::enableportManTLV $dut1 $value
   lldp::setlldpportmode  $dut1 $port TXANDRX
   lldp::setlldpportmode  $dut2 $port TXANDRX
   after 6000
   set dut1ip [lldp::walkRemManAddr $dut2 $dut1]
   puts "dut ip address $dut1ip"
   set noexist "No Such Instance currently exists at this OID"
    set renn  [lldp::walkRemManAddr  $dut2 $dut1]
    set a [string trim [lindex [string trim [split $dut1ip =] " "] 1 ] " "]
    set b [string equal $a $noexist]
    set c [string equal [lldp::walkRemChassisID $dut2] [lldp::getLocChassisID $dut1] ]
   if {$b && $c} {
        passed OptionalTLV  "Doesn't select Man Add TLV test succeed "
    } else {
        failed OptionalTLV  "Doesn't select Man Add TLV test failed " 
    }
}
#25  filter lldp packets 
# -alias             (config a port, that you captured packets on it already)
# -dstmac             (lldp  destination mac 01 80 C2 00 00 0E)
# -ethertype          (lldp ethertype 88CC )
# - hold              (lldp time to live value  hold = txinterval*txhold ,which must be hex 2Byte)
proc check_lldppacket {args} {
    set dbgprt_value 0
    foreach {handle para} $args {
        if {[regexp {^-(.*)$} $handle all handleval]} {
            lappend handlelist $handleval
            lappend paralist $para
        }
    }
    set paraNum 0
    foreach item1 $handlelist item2 $paralist {
        set $item1\_value $item2
        
        if {[string first dstmac $item1] >=0} {incr paraNum}
        if {[string first ethertype $item1] >=0} {incr paraNum}
        if {[string first hold $item1] >=0} {incr paraNum}
    }
    global [subst $alias_value]
    after 500

    foreach port [subst $$alias_value] {
        scan $port "%d %d %d" chasNum cardNum portNum
        capture get $chasNum $cardNum $portNum
        set numCaptured [capture cget -nPackets]
        if {$dbgprt_value == 1} {puts "@@ numCaptured: $numCaptured"}
        set loop [expr $numCaptured / 50]
        set mod [expr $numCaptured % 50]
        set j 0

        for {set m 1} {$m <= [expr $loop + 1]} {incr m} {
                set start [expr [expr [expr $m - 1] * 50] + 1]
                if {$m==[expr $loop + 1] && $mod==0} { break }
                if {$m==[expr $loop + 1] && $mod>0 } {
                        set end [expr $start + $mod -1]
                } elseif {$m <= $loop} {
                    set end [expr $start + 49]
                }

                captureBuffer get $chasNum $cardNum $portNum $start $end
                set gotFrameData ""
                for {set i $start} {$i <=  $end } {incr i} {
                        set index [expr $i - [expr [expr $m-1]*50] ]
                        captureBuffer getframe $index
                        
                        set bufferdata [captureBuffer cget -frame]
                    
                    


                        #2. check whether the dstmac can match the parameter values
                        if {[info exist dstmac_value]} {
                        set dstmac_value [string toupper $dstmac_value]
                        set sortdamac [lrange $bufferdata 0 5]
                        if {$dbgprt_value == 1 && $i <= 10} {puts "@@ damac: $sortdamac"}
                        if {[string first "$sortdamac" "$dstmac_value"] < 0} {
                            continue
                        }
                        }
                        

                        #3.1-miles add: check whether the ethertype is the same as filtered
                        if {[info exist ethertype_value]} {
                        set sortethernettype [lrange $bufferdata 12 13]
                        set typevalue [string toupper [concat [string range $ethertype_value 0 1] [string range $ethertype_value 2 3] ] ]
                        if {$dbgprt_value == 1 && $i <= 10} {
                         puts "@@ ethernettype: $sortethernettype "
                         puts "@@ configured ethertype is $typevalue"
                        }
                        if {"$sortethernettype" != "$typevalue"} {
                            continue
                        }
                        }
                        
                        #6. check lldp hold value
                        if {[info exist hold_value]} {
                        set lldphold [lrange $bufferdata 29 30]
                        set holdvalue [string toupper [concat [string range $hold_value 0 1] [string range $hold_value 2 3] ] ]
                        if {$dbgprt_value == 1 && $i <= 10} {
                        
                         puts "@@ lldpholdvalue: $holdvalue " 
                         puts "@@ configured Tx Hold is $lldphold"
                        }
                        if {"$lldphold" != "$holdvalue"} {
                            continue
                        }
                        }
                        incr j

                    }   
            } 
        }

    if {$dbgprt_value == 1} {puts "@@ Got: $j packets filtered in captureBuffer"}
    return $j
}
#enable port CDP aware
proc lldp::setCDPaware { dut port value } {
    set mode [string toupper $value]
    if {[string equal "ENABLE" $mode]} {
           set cmd "exec snmpset $::session $dut"
           set setCDP "$lldpoid::lldpPortConfigCdpAwareEnabledOID(oid).$port [getType $lldpoid::lldpPortConfigCdpAwareEnabled(type)] 1"
           append cmd " $setCDP"
           set ret [catch {eval $cmd} error]
               if {$ret == 1} { 
                     puts $error
                     puts "enable dut $dut port $port CDP aware  Failed!"
                } else {
                      puts "enable dut $dut port $port CDP aware  successed!"
                }
    } elseif {[string equal "DISABLE" $mode]} {
           set cmd "exec snmpset $::session $dut"
           set setCDP "$lldpoid::lldpPortConfigCdpAwareEnabledOID(oid).$port [getType $lldpoid::lldpPortConfigCdpAwareEnabled(type)] 2"
           append cmd " $setCDP"
           set ret [catch {eval $cmd} error]
               if {$ret == 1} { 
                     puts $error
                     puts "Disable dut $dut port $port CDP aware  Failed!"
                } else {
                      puts "Disable dut $dut port $port CDP aware  successed!"
                }
   } else {
           puts "Input parameter values have some errors"
   }
}