#!/bin/tcl
#file:vlan.tcl
#this is a base module for vlan testing
#Date: 2013-10-18
#Author: andym

namespace eval vlanoid {
		set tnIfVLANTagMgmt2PortType(oid) 1.3.6.1.4.1.868.2.5.4.1.4.3.1.1
		set tnIfVLANTagMgmt2PortType(type) INTEGER
		set tnIfVLANTagMgmt2PortType(access) read-write
		set tnIfVLANTagMgmt2TxTagType(oid) 1.3.6.1.4.1.868.2.5.4.1.4.3.1.2
		set tnIfVLANTagMgmt2TxTagType(type) INTEGER 
		set tnIfVLANTagMgmt2TxTagType(access) read-write
		set dot1qMaxVlanId(oid) 1.3.6.1.2.1.17.7.1.1.2
		set dot1qMaxVlanId(type) VlanId 
		set dot1qMaxVlanId(access) read-only
		set dot1qMaxSupportedVlans(oid) 1.3.6.1.2.1.17.7.1.1.3
		set dot1qMaxSupportedVlans(type) Unsigned32 
		set dot1qMaxSupportedVlans(access) read-only
		set dot1qNumVlans(oid) 1.3.6.1.2.1.17.7.1.1.4
		set dot1qNumVlans(type) Unsigned32 
		set dot1qNumVlans(access) read-only
		set dot1qFdbDynamicCount(oid) 1.3.6.1.2.1.17.7.1.2.1.1.2
		set dot1qFdbDynamicCount(type) Counter32 
		set dot1qFdbDynamicCount(access) read-only
		set dot1qTpFdbPort(oid) 1.3.6.1.2.1.17.7.1.2.2.1.2
		set dot1qTpFdbPort(type) Integer32 
		set dot1qTpFdbPort(access) read-only
		set dot1qTpFdbStatus(oid) 1.3.6.1.2.1.17.7.1.2.2.1.3
		set dot1qTpFdbStatus(type) INTEGER 
		set dot1qTpFdbStatus(access) read-only
		set dot1qTpGroupEgressPorts(oid) 1.3.6.1.2.1.17.7.1.2.3.1.2
		set dot1qTpGroupEgressPorts(type) PortList 
		set dot1qTpGroupEgressPorts(access) read-only
		set dot1qTpGroupLearnt(oid) 1.3.6.1.2.1.17.7.1.2.3.1.3
		set dot1qTpGroupLearnt(type) PortList 
		set dot1qTpGroupLearnt(access) read-only
		set dot1qStaticUnicastAllowedToGoTo(oid) 1.3.6.1.2.1.17.7.1.3.1.1.3
		set dot1qStaticUnicastAllowedToGoTo(type) PortList 
		set dot1qStaticUnicastAllowedToGoTo(access) read-write
		set dot1qStaticUnicastStatus(oid) 1.3.6.1.2.1.17.7.1.3.1.1.4
		set dot1qStaticUnicastStatus(type) INTEGER 
		set dot1qStaticUnicastStatus(access) read-write
		set dot1qStaticMulticastStaticEgressPorts(oid) 1.3.6.1.2.1.17.7.1.3.2.1.3
		set dot1qStaticMulticastStaticEgressPorts(type) PortList 
		set dot1qStaticMulticastStaticEgressPorts(access) read-write
		set dot1qStaticMulticastStatus(oid) 1.3.6.1.2.1.17.7.1.3.2.1.5
		set dot1qStaticMulticastStatus(type) INTEGER 
		set dot1qStaticMulticastStatus(access) read-write
		set dot1qVlanFdbId(oid) 1.3.6.1.2.1.17.7.1.4.2.1.3
		set dot1qVlanFdbId(type) Unsigned32 
		set dot1qVlanFdbId(access) read-only
		set dot1qVlanCurrentEgressPorts(oid) 1.3.6.1.2.1.17.7.1.4.2.1.4
		set dot1qVlanCurrentEgressPorts(type) PortList 
		set dot1qVlanCurrentEgressPorts(access) read-only
		set dot1qVlanCurrentUntaggedPorts(oid) 1.3.6.1.2.1.17.7.1.4.2.1.5
		set dot1qVlanCurrentUntaggedPorts(type) PortList 
		set dot1qVlanCurrentUntaggedPorts(access) read-only
		set dot1qVlanStatus(oid) 1.3.6.1.2.1.17.7.1.4.2.1.6
		set dot1qVlanStatus(type) INTEGER 
		set dot1qVlanStatus(access) read-only
		set dot1qVlanStaticName(oid) 1.3.6.1.2.1.17.7.1.4.3.1.1
		set dot1qVlanStaticName(type) SnmpAdminString 
		set dot1qVlanStaticName(access) read-create
		set dot1qVlanStaticEgressPorts(oid) 1.3.6.1.2.1.17.7.1.4.3.1.2
		set dot1qVlanStaticEgressPorts(type) PortList 
		set dot1qVlanStaticEgressPorts(access) read-create
		set dot1qVlanStaticUntaggedPorts(oid) 1.3.6.1.2.1.17.7.1.4.3.1.4
		set dot1qVlanStaticUntaggedPorts(type) PortList 
		set dot1qVlanStaticUntaggedPorts(access) read-create
		set dot1qVlanStaticRowStatus(oid) 1.3.6.1.2.1.17.7.1.4.3.1.5
		set dot1qVlanStaticRowStatus(type) RowStatus 
		set dot1qVlanStaticRowStatus(access) read-create
		set dot1qNextFreeLocalVlanIndex(oid) 1.3.6.1.2.1.17.7.1.4.4
		set dot1qNextFreeLocalVlanIndex(type) Integer32 
		set dot1qNextFreeLocalVlanIndex(access) read-only
		set dot1qPvid(oid) 1.3.6.1.2.1.17.7.1.4.5.1.1
		set dot1qPvid(type) VlanIndex 
		set dot1qPvid(access) read-write
		set dot1qPortAcceptableFrameTypes(oid) 1.3.111.2.802.1.1.4.1.4.5.1.2
		set dot1qPortAcceptableFrameTypes(type) INTEGER 
		set dot1qPortAcceptableFrameTypes(access) read-write
		set dot1qPortIngressFiltering(oid) 1.3.6.1.2.1.17.7.1.4.5.1.3
		set dot1qPortIngressFiltering(type) TruthValue 
		set dot1qPortIngressFiltering(access) read-write
		#Jefferson Added --"Management Port - PortType" + "Ethertype for Custom S-ports" - 01/10/2014
        set tnSysVlanExtMgmtPortType(oid) 1.3.6.1.4.1.868.2.5.4.1.1.2.1.1.1
        set tnSysVlanExtMgmtPortType(type) INTEGER
        set tnSysVlanExtMgmtPortType(access) read-write
        
        set tnSysVLANExtCustomSTag(oid) 1.3.6.1.4.1.868.2.5.4.1.1.2.1.2.1
        set tnSysVLANExtCustomSTag(type) OctetString
        set tnSysVLANExtCustomSTag(access) read-write

		#--------------End
}
namespace import util::*
namespace eval vlan {
    namespace export *
}
# add new vlan via MIB
# vlan::vlanadd 3 0x0f
proc vlan::vlanadd {vid PortList {dut 0}} {

	set index $vid
	if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
	
	puts "adding new vlan $vid in $PortList"

	set vlanPort "$vlanoid::dot1qVlanStaticEgressPorts(oid).$index [getType $vlanoid::dot1qVlanStaticEgressPorts(type)] $PortList"
	set rSt "$vlanoid::dot1qVlanStaticRowStatus(oid).$index [getType $vlanoid::dot1qVlanStaticRowStatus(type)] 4"
    append cmd " $vlanPort $rSt"
    set ret [catch {eval $cmd} error]
    if { $ret } { puts "$error vlan::vlanadd commit $vid 0x$PortList Failed"}
	puts "vlan::vlanadd commit $vid 0x$PortList success"
}

#delete vlan in device via MIB
# vlan::vlanDelete 3
proc vlan::vlanDelete {vid {dut 0}} {
	set index $vid
	if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
	puts "vlan::vlanDelete $vid"
	set rSt "$vlanoid::dot1qVlanStaticRowStatus(oid).$vid [getType $vlanoid::dot1qVlanStaticRowStatus(type)] 6"
	append cmd " $rSt"
	set ret [catch {eval $cmd} error]
	if {$ret} { puts "$error vlan:vlanDelete $vid Failed!"}
	puts "vlan:vlanDelete $vid successed!"
}

proc vlan::porttypeSet {port type {dut 0}} {
	set index $port

	if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
	set Type [string toupper $type]
    if {$Type == "UNAWARE"} {
    	set typeValue 1
    } elseif {$Type == "CPORT"} {
    	set typeValue 2
    } elseif {$Type == "SPORT"} {
    	set typeValue 3
    } elseif {$type == "SCPORT" || $Type == "CSPORT"} {
    	set typeValue 4
    }
    set setPort "$vlanoid::tnIfVLANTagMgmt2PortType(oid).$index [getType $vlanoid::tnIfVLANTagMgmt2PortType(type)] $typeValue"
    append cmd " $setPort"
    set ret [catch {eval $cmd} error]
    if {$ret} {puts "$error vlan::porttypeSet $port $type Failed!"}
    puts "vlan::porttypeSet $port $type successed!"
}

#----Jefferson Created. to ethertype for Custom S-ports
proc vlan::etherTypeSet { value {dut 0} } {
	
    if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
    
    set ethType "$vlanoid::tnSysVLANExtCustomSTag(oid) [getType $tnSysVLANExtCustomSTag(type)] $value"
    append cmd "$ethType"
    puts "cmd $cmd"

    if { [catch {eval $cmd} err] } {
        puts "$err vlan::etherTypeSet $value Failed!"
    } else {
        puts "vlan::etherTypeSet $type successed!"
    }

}


proc vlan::portIngressFilteringEnable {port enable {dut 0}} {
	set index $port
	if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
	if { $enable == True || $enable == 1} {
		set enableValue 1
	} else {
		set enableValue 2
	}
	set setIngressFiltering "$vlanoid::dot1qPortIngressFiltering(oid).$index [getType $vlanoid::dot1qPortIngressFiltering(type)] $enableValue"
	append cmd " $setIngressFiltering"
	set ret [catch {eval $cmd} error]
	if {$ret} {puts "$error vlan::portIngressFilteringEnable $port $enable Failed!"}
	puts "vlan::portIngressFilteringEnable $port $enable successed!"
}
# Set the port Frame Type via MIB
# only support ALL and TAGGED
proc vlan::portFrametypeSet {port type {dut 0}} {
	set index $port
	if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
	set Type [string toupper $type]
    if {$Type == "ALL"} {
    	set typeValue 1
    } elseif {$Type == "TAGGED"} {
    	set typeValue 3
    } elseif {$Type == "UNTAGGED"} {
    	set typeValue 2
    } 
    set setPort "$vlanoid::dot1qPortAcceptableFrameTypes(oid).1.$index [getType $vlanoid::dot1qPortAcceptableFrameTypes(type)] $typeValue"
    append cmd " $setPort"
    puts "cmd $cmd"
    set ret [catch {eval $cmd} error]
    if {$ret} {puts "$error vlan::portFrametypeSet $port $type Failed!"}
    puts "vlan::portFrametypeSet $port $type successed!"
}

proc vlan::portTxTagSet {port type {dut 0}} {
	set index $port
	if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
	set Type [string toupper $type]
	if {$Type == "UNTAGPVID"} {
		set typevalue 1
	} elseif { $Type == "TAGALL"} {
		set typevalue 2
	} elseif { $Type == "UNTAGALL"} {
		set typevalue 3
	}
	set setPortFrameType "$vlanoid::tnIfVLANTagMgmt2TxTagType(oid).$index [getType $vlanoid::tnIfVLANTagMgmt2TxTagType(type)] $typevalue"
	append cmd " $setPortFrameType"
	set ret [catch {eval $cmd} error]
	if {$ret} {puts "$error vlan::portTxTagSet $port $type Failed!"}
	puts "vlan::portTxTagSet $port $type successed!"
}

proc vlan::portVlanSet {port pvid {dut 0}} {
	set index $port
	if { $dut != "0" } {
		set cmd "exec snmpset $::session $dut"	
	} else {
		set cmd "exec snmpset $::session"
	}
	
	set setPortVlan "$vlanoid::dot1qPvid(oid).$index [getType $vlanoid::dot1qPvid(type)] $pvid"
	append cmd " $setPortVlan"
	set ret [catch {eval $cmd} error]
	if {$ret} {puts "$error vlan::portVlanSet $port $pvid Failed!"}
	puts "vlan::portVlanSet $port $pvid successed!"
}


