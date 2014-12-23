		#!/bin/tcl
	#source $::g_ixwishdir
	package req IxTclHal
	set ::errorInfo ""
	set ::packet_path [file normalize [info script]]
	set ::packet_path [file join [file dirname $::packet_path] packets]
	
	# -ipaddr		x.x.x.x           ( The target IXIA IP address)
	# -portlist		slot,port,alias   (ports that user want to control to test)
	# -alias		string (optional) (alias all ports together)
	# -loginname	dvtAuto           (login user name)
	# -dbgprt		[1|0]             (dbg parameter, optional)
	# connect_ixia -ipaddr 192.168.0.21 -portlist 3,2,ixiap1,3,3,ixiap2 -alias allport -loginname auto -dbgprt 1
	# function: Connect ixia 192.168.0.21, use card 3 port 2 and card 3 port 3 to test
	#           Login with name "auto", with -dbgprt 1, debug info will be printed
	proc connect_ixia {args} {
		global tcLogId 
		set aftertime 5000
		#1. get command and handle/parameters
		foreach {handle para} $args {
			if {[regexp {^-(.*)$} $handle all handleval]} {
				lappend handlelist $handleval
				lappend paralist $para
			}
		}
		
		#2. set all parameter(default) value according user defination
		if {[info exist handlelist] && [info exist paralist]} {
			if {[set idx [lsearch $handlelist dbgprt]] != -1} {
				set dbgprtVal [lindex $paralist $idx]
			} else {
				set dbgprtVal 0
			}
			# check whether loginname parameter is configured
			if {[set idx [lsearch $handlelist loginname]] != -1} {
				set userName [lindex $paralist $idx]
			} else {
				#the default user name would be "dvtAuto"
				set userName dvtAuto
			}
			if {$dbgprtVal == 1} {puts "@@ loginname: $userName"}
			# check the IXIA ipaddr parameter
			if {[set idx [lsearch $handlelist ipaddr]] != -1} {
				set ixiaIp [lindex $paralist $idx]
				if {$dbgprtVal == 1} {puts "@@ ipaddr: $ixiaIp"}
			} else {
				uWriteExp -errorinfo "proc: connect_ixia, ipaddress is a mandatory parameter but missing"
			}
			
			
			# login and connected to chassis
			if [isUNIX] {
				# this is only for linux platform, you have to connect TclServer firstly
				if [ixConnectToTclServer $ixiaIp] {
					puts "Could not connect to $ixiaIp"
				}
			}
		# login IXIA with IXIA API
			ixLogin $userName
			ixConnectToChassis $ixiaIp
			set chasId [ixGetChassisID $ixiaIp]
			if {$dbgprtVal == 1} {puts "@@ chasId: $chasId"}
			
			if {[set idx [lsearch $handlelist alias]] != -1} {
				set aliasval [lindex $paralist $idx]
				if {$dbgprtVal == 1} {puts "@@ alias: $aliasval"}
			}
			
			if {[set idx [lsearch $handlelist portlist]] != -1} {
				set portval [lindex $paralist $idx]
				set portlistval [split $portval ,]
				if {$dbgprtVal == 1} {puts "@@ portlistval: $portlistval"}
				foreach {slotid portid portalias} $portlistval {
					set $portalias [list [list $chasId $slotid $portid]]
					if {$dbgprtVal == 1} {puts "@@ $portalias: [list [list $chasId $slotid $portid]]"}
					eval [subst {uplevel #0 {set $portalias "[list [list $chasId $slotid $portid]]"}}]
					lappend allList [list $chasId $slotid $portid]
				}
				if {[info exist aliasval]} {
					set $aliasval $allList
					if {$dbgprtVal == 1} {puts "@@ $aliasval: $allList"}
					eval [subst {uplevel #0 {set $aliasval "$allList"}}]
				}
			} else {
				uWriteExp -errorinfo "proc: connect_ixia, portlist is a mandatory parameter but missing"
				
			}
		
		} else {
			uWriteExp -errorinfo "proc: connect_ixia, args: $args, input parameter error!"
		}
		
		#3. take ownership and set factory default
		ixTakeOwnership $allList force
		foreach port $allList {
			scan $port "%d %d %d" chasNum cardNum portNum
			port setFactoryDefaults $chasNum $cardNum $portNum
			port write $chasNum $cardNum $portNum
		}
		after $aftertime
		
		#4. put ixia versions
		version get
		set osVer [version cget -installVersion]
		if {$dbgprtVal == 1} {puts "@@ osVer is $osVer"}
		set halVer [version cget -ixTclHALVersion]
		if {$dbgprtVal == 1} {puts "@@ halVer is $halVer"}
		set pdtVer [version cget -productVersion]
		if {$dbgprtVal == 1} {puts "@@ pdtVer $pdtVer"}
		
		set logInfo "connect_ixia,take ownership and set factory default of port(s)"
		#printlog -fileid $tcLogId -res conf -cmd $logInfo -comment $allList
		set verStr "ixia version, product: $pdtVer, OS: $osVer, HAL: $halVer"
		#printlog -fileid $tcLogId -res chck -cmd $verStr
		after $aftertime
		puts $verStr
		
	}
	
	# -alias         (select which port you want to config)
	# -autonego      (set port negotiate paramter)
	# -duplex        (set port duplex mode )
	# -phymode       (set port phymode [copper|fiber])
	# -dbgprt [0|1]  (debug paramter, 1 will print debug info)
	# config_portprop -alias allport -autonego enable -phymode copper -duplex 10h,10f,100h,100f -dbgprt 1
	# Function:       Set all ports to autonegotiate mdoe ,wth copper mode 10M half, 10M full, 100M half 100M full
	proc config_portprop {args} {
	
		global tcLogId
		set aftertime 1000
		#port properties, check link status, clear stat, 
		#1. get command and handle/parameters
		foreach {handle para} $args {
			if {[regexp {^-(.*)$} $handle all handleval]} {
				lappend handlelist $handleval
				lappend paralist $para
			}
		}
		
		#2. set all parameter(default) value according user defination
		if {[info exist handlelist] && [info exist paralist]} {
			if {[set idx [lsearch $handlelist dbgprt]] != -1} {
				set dbgprtVal [lindex $paralist $idx]
			} else {
				set dbgprtVal 0
			}
			# check whether autonego parameter is configured, and set the autoNegoMode
			if {[set idx [lsearch $handlelist autonego]] != -1} {
				set autonegoVal [lindex $paralist $idx]
				switch $autonegoVal {
					enable 	{set autoNegoMode true}
					disable {set autoNegoMode false}
					default {uWriteExp -errorinfo "wrong autonego parameter"}
				}
				if {$dbgprtVal == 1} {puts "@@ autonego: $autonegoVal"}
			}
			# check whether the portPhyMode is configured, and set the phymode with IXIA api 
			if {[set idx [lsearch $handlelist phymode]] != -1} {
				set phymodeVal [lindex $paralist $idx]
				switch $phymodeVal {
					copper {set phymode portPhyModeCopper}
					fiber {set phymode portPhyModeFiber}
					default {uWriteExp -errorinfo "wrong phymode parameter"}
				}
				if {$dbgprtVal == 1} {puts "@@ phymode: $phymodeVal"}
			}
			
			if {[set idx [lsearch $handlelist alias]] != -1} {
				set aliasval [lindex $paralist $idx]
				if {$dbgprtVal == 1} {puts "@@ alias: $aliasval"}
			}
			
			if {[set idx [lsearch $handlelist duplex]] != -1} {
				set duplexVal [lindex $paralist $idx]
				if {$dbgprtVal == 1} {puts "@@ duplex: $duplexVal"}
			}
		
		} else {
			uWriteExp -errorinfo "proc: connect_ixia, args: $args, input parameter error!"
		}
		
		global [subst $aliasval]
		if {$dbgprtVal == 1} {puts "@@ portList: [subst $$aliasval]"}	
		foreach port [subst $$aliasval] {
			scan $port "%d %d %d" chasNum cardNum portNum
			# set phymode with IXIA API port setPhyMode
			if {[info exist phymodeVal]} {
				port setPhyMode $phymode $chasNum $cardNum $portNum
			}
			# set autonegotiate with IXIA API port config
			if {[info exist autonegoVal]} {
				port config -autonegotiate $autoNegoMode
			}
			
			if {[info exist duplexVal]} {
				set duplexList [split $duplexVal ,]
				if {$dbgprtVal == 1} {puts "@@ duplexList: $duplexList"}
				set falseDuplex [list 10h 10f 100h 100f 1000f]
				foreach duplexItem $duplexList {
					set idx [string first $duplexItem $falseDuplex]
					if {$idx != -1 } {
						set falseDuplex [string replace $falseDuplex $idx [string length $duplexItem]]
					}
					switch $duplexItem {
						# these "port config " are IXIA APIS, these are the functional part of this API
						10h 	{port config -advertise10HalfDuplex true}
						10f 	{port config -advertise10FullDuplex true}
						100h 	{port config -advertise100HalfDuplex true}
						100f 	{port config -advertise100FullDuplex true}
						1000f 	{port config -advertise1000FullDuplex true}
						default {uWriteExp -errorinfo "input duplex value error of duplexList"}
					}
					puts "set duplexItem "
				}
				
				if {$dbgprtVal == 1} {puts "@@ falseDuplex: $falseDuplex"}
				
				foreach forceDuplexItem $falseDuplex {
					switch $forceDuplexItem {
						10h 	{port config -advertise10HalfDuplex false}
						10f 	{port config -advertise10FullDuplex false}
						100h 	{port config -advertise100HalfDuplex false}
						100f 	{port config -advertise100FullDuplex false}
						1000f 	{port config -advertise1000FullDuplex false}
						default {uWriteExp -errorinfo "input duplex value error of falseDuplex"}
					}
				}
			}
		
			port set $chasNum $cardNum $portNum
			port write $chasNum $cardNum $portNum
		}
		
		for {set i 1} {$i<=10} {incr i} {
			after $aftertime
			if {[ixCheckLinkState $aliasval] == 0} {
				set linkst [ixCheckLinkState $aliasval]
				puts "ixCheckLinkState $linkst"
				break
			}
			if {$i == 10 && [ixCheckLinkState $aliasval] !=0} {
				#printlog -fileid $tcLogId -res chck -cmd "check all connected link status" -comment "One or more links status are down!"
			}
		}
		set logStr "config_portprop $args"
		puts $logStr
		#printlog -fileid $tcLogId -res conf -cmd $logStr
	}
	#ethernetname      (ip|ipv4|ipv6)
	# -frametype       (The frametype: [ethernetii|none])
	# -vlanmode        (vlan mode : [singlevlan|qinq|none])
	# -vlanid          (vlan id value:)
	# -priority        (vlan user priority value)
	# -tpid            (vlan type id,8100,88a8,9100,9200 etc)
	# -innervlanid     (when vlan mode is qinq, this is the inervlan id value)
	# -innerpriority   (when vlan mode is qinq, use this to set inter vlan user priority)
	# -innertpid       (when vlan mode is qinq, use this to set inter vlan type id)
	# -qosmode         (qos mode [dscp|toss])
	# -dscpmode        (is qosmode is dscp,set the dscpmode [custom] )
	# -dscpvalue       (the dscp value)
	# -srcip           (src ip address)
	# -dstip           (dst ip address)
	# -srcmac          (src mac address, format as "00 00 00 00 00 11")
	# -srcmacmode      (repeat mode [increment|fixed] default is fixed)
	# -srcrepeatcount  (repeat range count)
	# -srcstep         (repeat incress step)
	# -dstmac          (dst mac address, format as "00 00 00 00 00 11")
	# -dstmacmode      (repeat mode [increment|fixed] default is fixed)
	# -dstrepeatcount  (repeat range count)
	# -dststep         (repeat increase step)
	# -framesize       (packet frame size,bits)
	# config_frame -alias allport -frametype none -vlanmode singlevlan -vlanid 10 -priority 3 -dbgprt 1
	# -igmptype [query v1report v2report v3report leave]
	# -groupip 
	# -v3groupip (225.0.0.1)
	# -v3includeip ([list 1.1.1.1 2.2.2.2])
	# -v3excludeip ([list 1.1.1.1 2.2.2.2])
	# -ipv6src  (fe80::4)
	# -ipv6des  (ff01::5)
	# -mldv1 [query report done]
	# -groupmldv1 
	
	########## ARP parameters start
	#-operation           The type of operation the ARP process  is attempting :(arpRequest,arpReply,rarpRequest,rarpReply)
	#-sendHardAdd         The MAC address of the sending ARP interface.  (default = 00 de bb 00 00 00
	#-sendHardMode        Indicates how the sourceHardwareAddr  field is to vary between consecutive  frames.                
	#-sendHardRepCou      Indicates the repeat count for the  sourceHardwareAddrMode  increment and  decrement options.  (default = 0)                 
	#-sendProtAdd         Protocol address of the station that is sending the ARP message. (default  =127.0.0.1)                  
	#-sendProtMode        Indicates how the sourceProtocolAddr field is to vary between consequtive  frames.                       
	#-sendProtRepCou      Indicates the repeat count for the  sourceProtocolAddrMode  increment and   decrement options.  (default = 0)                       
	#-targetHardAdd       The MAC address of the interface receiving the ARP message. (default = 00 de  bb 00 00 01)                        
	#-targetHardMode      Indicates how the destHardwareAddr  field is to vary between consequtive  frames.                          
	#-targetHardRepCou    Indicates the repeat count for the  destHardwareAddrMode  increment and decrement options.  (default = 0)                         
	#-targetProtAdd      Protocol address of the station that is receiving the ARP message.  (default =   127.0.0.1)                       
	#-targetProtMode      Indicates how the destProtocolAddr field is to vary between consequtive frames.   
	#-targetProtRepCou    Indicates the repeat count for the  destProtocolAddrMode increment and  decrement options.  (default = 0)     
	########## ARP parameters end


	########## DHCP parameters start
	#-opCode          Operation code (dhcpBootRequest,dhcpBootReply) 
    #-hwType          Hardware address types ( dhcpEthernet10Mb ,dhcpEthernet3Mb ,dhcpAmateur ,dhcpProteon ,dhcpChaos ,dhcpIEEE ,dhcpARCNET ,
    #                                     dhcpHyperchannel, dhcpLanstar, dhcpAutonet, dhcpLocalTalk, dhcpLocalNet, dhcpUltraLink, 
    #                                     dhcpSMDS,dhcpFrameRelay dhcpATM1,dhcpHDLC, dhcpFibreChannel, dhcpSerialLine , dhcpATM3 )                                   	        
    #-hwLen           Hardware address length. (default = 6 )          
    #-hops            Set to zero by client. (default = 0)          
    #-transactionID   Random number chosen by client and used by the client and server to associate 
    #                messages and responses between a client and a server.  (default = 0)
    #-seconds         Seconds elapsed since client began address acquisition or renewal process. (default = 0)
    #-flags           Available option values are: (dhcpNoBroadcast,dhcpBroadcast)
    #-clientIpAddr    Client IP address. Only filled in if client is in BOUND, RENEW or REBINDING state and can respond to ARP requests.  (default = 0.0.0.0)
    #-yourIpAddr      'your' (client) IP address.  (default = 0.0.0.0)
    #-serverIpAddr   IP address of next server to use in  bootstrap; returned in DHCPOFFER, DHCPACK by server. (default = 0.0.0.0) 
    #-relayAgentIpAddr Relay agent IP address, used  in booting by a relay agent. (default = 0.0.0.0)             
    #-clientHwAddr    Client hardware address. (default = 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00)           
    #-serverHostName   Optional server host name, null terminated string. (default =”“)       
    #-bootFileName     Boot file name, null terminated string; "generic" name or null in DHCPDISCOVER, fully qualified folder-path name in DHCPOFFER         
    #-option           option inclue optionCode and optionData separated by ","  one option and another option separated by ";" ,for example     
    #                     "1,255.255.255.0;3,192.168.100.100;53,5" 
    ##!!!!configure example :
    # config_frame  -alias ixiap1 -srcmac $srcMac  -dstmac $destBroMac -frametype $ethtype  -framesize 600 -protocol dhcp  -opCode dhcpBootReply \
       -hwType    dhcparcnet -hwLen 5  -hops 6 -transactionID 123456 -seconds 8  -flags dhcpNoBroadcast -clientIpAddr "192.168.1.1" -yourIpAddr "192.168.1.2" \
       -serverIpAddr "192.168.3.1" -relayAgentIpAddr "192.168.5.1" -clientHwAddr "00 22 22 22 22"     \
       -bootFileName  "ming"  -serverHostName "dhcpserver" -option  "1,255.255.255.0;3,192.168.100.100;53,5;51,10;6,192.168.100.128"  
	########## DHCP parameters end


	# -import xxx.enc 
# Function: config a new frame for IXIA on -alias port
proc config_frame {args} {
	global tcLogId
	#1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "config_frame: alias is a mandatory parameter but missing"
	}
	
	foreach port [subst $$alias_value] {
		scan $port "%d %d %d" chasNum cardNum portNum
		stream get $chasNum $cardNum $portNum 1
		ip get $chasNum $cardNum $portNum
		#vlan get $chasNum $cardNum $portNum
		#stackedVlan get $chasNum $cardNum $portNum

#######################jerry add start 2013.12.24
		if {[info exist import_value]} {

			set path [file join $::packet_path $import_value]
			captureBuffer import  $path $chasNum $cardNum $portNum
			captureBuffer getframe 1
			set frame_mld [captureBuffer cget -frame]
			set string_length [string length $frame_mld]
			set frame_length [expr [expr $string_length+1]/3]
			set pad [string range $frame_mld 36 end]
			stream get $chasNum $cardNum $portNum 1
			stream setDefault
			stream config -framesize $frame_length
			stream config -da [string range $frame_mld 0 16]

			stream config -sa [string range $frame_mld 18 34]
			protocol setDefault
			protocolOffset setDefault
			protocol config -ethernetType protocolOffsetType
			protocolOffset config -offset [expr $frame_length-4]
			protocolOffset config -userDefinedTag $pad
			protocolOffset set $chasNum $cardNum $portNum
		}
################jerry add end 2013.12.24




		if {[info exist frametype_value]} {
			if {$dbgprt_value == 1} {puts "@@ frametype: $frametype_value"}
			switch [string tolower $frametype_value] {
			    #remove "protocol config -name ipV4"
			    #initial format: ethernetii {protocol config -ethernetType ethernetII; protocol config -name ipV4}
				ethernetii {protocol config -ethernetType ethernetII}
				none {protocol config -ethernetType noType}
				default {uWriteExp -errorinfo "input frametype error"}
			}
		}



		if {[info exist vlanmode_value]} {
			if {$dbgprt_value == 1} {puts "@@ vlanmode: $vlanmode_value"}
			switch $vlanmode_value {
				singlevlan {protocol config -enable802dot1qTag vlanSingle; vlan get $chasNum $cardNum $portNum}
				qinq {protocol config -enable802dot1qTag vlanStacked; stackedVlan get $chasNum $cardNum $portNum}
				none {protocol config -enable802dot1qTag vlanNone}
				default {uWriteExp -errorinfo "input frame vlanmode error"}
			}
		}
		# ethernetname_value ??????????
		if {[info exist ethernetname_value]} {
			if {$dbgprt_value == 1} {puts "@@ ethernetname: $ethernetname_value"}
			switch $ethernetname_value {
				ip {protocol config -name ip}
				ipv4 {protocol config -name ipV4}
				ipv6 {protocol config -name ipV6; ipV6 setDefault}
				default {uWriteExp -errorinfo "input frame ethernetname error"}
			}
		}		

		if {[info exist vlanid_value]} {
			if {$dbgprt_value == 1} {puts "@@ vlanid: $vlanid_value"}
			vlan config -vlanID	$vlanid_value
			set getvlanmode [protocol cget -enable802dot1qTag]
			if {$getvlanmode == "2"} {
				stackedVlan setVlan 1
			}
		}
		if {[info exist priority_value]} {
			if {$dbgprt_value == 1} {puts "@@ priority: $priority_value"}
			vlan config -userPriority $priority_value
			set getvlanmode [protocol cget -enable802dot1qTag]
			if {$getvlanmode == "2"} {
				stackedVlan setVlan 1
			}
		}				
		if {[info exist tpid_value]} {
			vlan config -protocolTagId	0x$tpid_value
			set getvlanmode [protocol cget -enable802dot1qTag]
			if {$getvlanmode == "2"} {
				stackedVlan setVlan 1
			}
		}
		if {[info exist innervlanid_value]} {
			vlan config -vlanID	$innervlanid_value
			set getvlanmode [protocol cget -enable802dot1qTag]
			if {$getvlanmode == "2"} {
				stackedVlan setVlan 2
			}
		}
		if {[info exist innerpriority_value]} {
			vlan config -userPriority	$innerpriority_value
			set getvlanmode [protocol cget -enable802dot1qTag]
			if {$getvlanmode == "2"} {
				stackedVlan setVlan 2
			}
		}					
		if {[info exist innertpid_value]} {
			vlan config -protocolTagId	0x$innertpid_value
			set getvlanmode [protocol cget -enable802dot1qTag]
			if {$getvlanmode == "2"} {
				stackedVlan setVlan 2
			}		
		}
		if {[info exist qosmode_value]} {
			switch $qosmode_value {
				dscp {ip config -qosMode ipV4ConfigDscp}
				tos {ip config -qosMode ipV4ConfigTos}
				default {uWriteExp -errorinfo "input frame qosmode error"}
			}
		}
		if {[info exist dscpmode_value]} {
			switch $dscpmode_value {
				custom {ip config -dscpMode ipV4DscpCustom}
				default {ip config -dscpMode ipV4DscpDefault}
			}
		}
#####################################----miles add ARP API------##########################################
# 12/23/2013
       if {[info exist protocol_value]} {
               if {$dbgprt_value == 1} {puts "@@ protocol: $protocol_value"}
                     set protocol  [string toupper $protocol_value]
               if { [string equal $protocol ARP]} {
                        protocol config -name mac
                        protocol config -appName Arp
                        arp get $chasNum $cardNum $portNum
                        arp setDefault 
                   if {[info exist operation_value]} {
                       if {$dbgprt_value == 1} {puts "@@ arpoperation: $operation_value"}
                           switch [string tolower $operation_value] {
                                arprequest {arp config -operation  arpRequest}
                                arpreply {arp config -operation  arpReply}
                                rarprequest {arp config -operation  rarpRequest
                                }
                                rarpreply {arp config -operation  rarpReply}
                                default {puts  "config_frame: input arp operation  error"}
                            }
                    } 
                   if {[info exist sendHardAdd_value]} {
                        if {$dbgprt_value == 1} {puts "@@ arpsendHardAdd: $sendHardAdd_value"}
                           arp config -sourceHardwareAddr  $sendHardAdd_value
                    }
                   if {[info exist sendHardMode_value]} {
                       if {$dbgprt_value == 1} {puts "@@ sendHardMode: $sendHardMode_value"}
                            switch [string tolower $sendHardMode_value] {
                                  arpidle                    {arp config -sourceHardwareAddrMode arpIdle}
                                  arpIncrement               {arp config -sourceHardwareAddrMode arpIncrement }
                                  arpDecrement               {arp config -sourceHardwareAddrMode arpDecrement}
                                  arpContinuousIncrement     {arp config -sourceHardwareAddrMode arpContinuousIncrement}
                                  arpContinuousDecrement     {arp config -sourceHardwareAddrMode arpContinuousDecrement}
                                  default {puts  "config_frame: input arp source hardware address mode  error"}
                                }    
                    }
                   if {[info exist sendHardRepCou_value]} {
                        if {$dbgprt_value == 1} {puts "@@ arpsendHardRepCou: $sendHardRepCou_value"}
                            arp config -sourceHardwareAddrRepeatCount  $sendHardRepCou_value
                    }
                    if {[info exist sendProtAdd_value]} {
                        if {$dbgprt_value == 1} {puts "@@ arpsendProtAdd: $sendProtAdd_value"}
                          arp  config -sourceProtocolAddr  $sendProtAdd_value
                    }
                   if {[info exist sendProtMode_value]} {
                        if {$dbgprt_value == 1} {puts "@@ sendProtMode: $sendProtMode_value"}
                             switch [string tolower $sendProtMode_value] {
                                 arpidle                    {arp config -sourceProtocolAddrMode arpIdle}
                                 arpIncrement               {arp config -sourceProtocolAddrMode arpIncrement }
                                 arpDecrement               {arp config -sourceProtocolAddrMode arpDecrement}
                                 arpContinuousIncrement     {arp config -sourceProtocolAddrMode arpContinuousIncrement}
                                 arpContinuousDecrement     {arp config -sourceProtocolAddrMode arpContinuousDecrement}
                                 default {puts  "config_frame: input arp source protocol address mode  error"}
                                }    
                    }
                   if {[info exist sendProtRepCou_value]} {
                        if {$dbgprt_value == 1} {puts "@@ sendProtRepCou: $sendProtRepCou_value"}
                                 arp config -sourceProtocolAddrRepeatCount  $sendProtRepCou_value
                    }
                   if {[info exist targetHardAdd_value]} {
                        if {$dbgprt_value == 1} {puts "@@ arptargetHardAdd: $targetHardAdd_value"}
                            arp config -destHardwareAddr  $targetHardAdd_value
                    }
                  if {[info exist targetHardMode_value]} {
                       if {$dbgprt_value == 1} {puts "@@ targetHardMode: $targetHardModee_value"}
                            switch [string tolower $targetHardMode_value] {
                                arpidle                    {arp config -destHardwareAddrMode arpIdle}
                                arpIncrement               {arp config -destHardwareAddrMode arpIncrement }
                                arpDecrement               {arp config -destHardwareAddrMode arpDecrement}
                                arpContinuousIncrement     {arp config -destHardwareAddrMode arpContinuousIncrement}
                                arpContinuousDecrement     {arp config -destHardwareAddrMode arpContinuousDecrement}
                                default { puts "config_frame: input arp destinate hardware address mode  error"}
                            }    
                    }
                  if {[info exist targetHardRepCou_value]} {
                       if {$dbgprt_value == 1} {puts "@@ targetHardRepCou: $targetHardRepCou_value"}
                            arp config -destHardwareAddrRepeatCount  $targetHardRepCou_value
                    }
                  if {[info exist targetProtAdd_value]} {
                      if {$dbgprt_value == 1} {puts "@@ arptargetProtAdd: $targetProtAdd_value"}
                            arp config  -destProtocolAddr  $targetProtAdd_value
                    }
                  if {[info exist targetProtMode_value]} {
                        if {$dbgprt_value == 1} {puts "@@ targetProtMode: $targetProtMode_value"}
                             switch [string tolower $targetProtMode_value] {
                                  arpidle                    {arp config -destProtocolAddrMode arpIdle}
                                  arpIncrement               {arp config -destProtocolAddrMode arpIncrement }
                                  arpDecrement               {arp config -destProtocolAddrMode arpDecrement}
                                  arpContinuousIncrement     {arp config -destProtocolAddrMode arpContinuousIncrement}
                                  arpContinuousDecrement     {arp config -destProtocolAddrMode arpContinuousDecrement}
                                  default {puts  "config_frame: input arp destinate protocol address mode  error"}
                                }    
                    }
                   if {[info exist targetProtRepCou_value]} {
                        if {$dbgprt_value == 1} {puts "@@ targetProtRepCou: $targetProtRepCou_value"}
                            arp config -destProtocolAddrRepeatCount  $targetProtRepCou_value
                    } 
                } 
                 arp set $chasNum $cardNum $portNum
        } 

####################################----miles add ARP API------#########################################
#####################################----miles add DHCP API------##########################################
# 1/3/2014
       if {[info exist protocol_value]} {
               if {$dbgprt_value == 1} {puts "@@ protocol: $protocol_value"}
                                 set protocol  [string toupper $protocol_value]
                            if { [string equal $protocol  DHCP]} {
                            	   puts "!!!!Note: If you want to config DHCP frame ,packet frame size should be at least 346 bytes"
                            	   puts "--------DHCP parameters start-------"
                            	   protocol config -name ipV4
                                   protocol config -appName Dhcp
                                   dhcp get $chasNum $cardNum $portNum
                                   dhcp setDefault 
                                if {[info exist opCode_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ opCode: $opCode_value"}
                                    switch  -regexp -nocase -- $opCode_value {
                                        dhcpbootrequest { dhcp config -opCode dhcpBootRequest }
                                        dhcpbootreply  { dhcp config -opCode dhcpBootReply }
                                        default {puts  "!!!!config_frame: input dhcp opCode  error"}
                                    }
                                } 
                                if {[info exist hwType_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ hwType: $hwType_value"}
                                    switch -regexp -nocase -- $hwType_value {
                                        dhcpethernet10mb  { dhcp config -hwType 1 }
                                        dhcpethernet3mb   { dhcp config -hwType 2 }
                                        dhcpamateur       { dhcp config -hwType 3 }
                                        dhcpproteon       { dhcp config -hwType 4 }
                                        dhcpchaos         { dhcp config -hwType 5 }
                                        dhcpieee          { dhcp config -hwType 6 }
                                        dhcparcnet        { dhcp config -hwType 7 }
                                        dhcphyperchannel  { dhcp config -hwType 8 }
                                        dhcplanstar       { dhcp config -hwType 9 }
                                        dhcpautonet       { dhcp config -hwType 10 }
                                        dhcplocaltalk     { dhcp config -hwType 11 }
                                        dhcplocalnet      { dhcp config -hwType 12 }
                                        dhcpultraLink     { dhcp config -hwType 13 }
                                        dhcpsmds          { dhcp config -hwType 14 }
                                        dhcpFrameRelay    { dhcp config -hwType 15 }
                                        dhcpATM1          { dhcp config -hwType 16 }
                                        dhcpHDLC          { dhcp config -hwType 17 }
                                        dhcpFibreChannel  { dhcp config -hwType 18 }
                                        dhcpATM2          { dhcp config -hwType 19 }
                                        dhcpSerialLine    { dhcp config -hwType 20 }
                                        dhcpATM3          { dhcp config -hwType 21 }
                                        default {puts  "!!!!config_frame: input dhcp hwType  error"}
                                    }
                                }
                                if {[info exist hwLen_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ hwLen: $hwLen_value"}
                                    dhcp config -hwLen $hwLen_value
                                }
                                if {[info exist hops_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ hops: $hops_value"}
                                    dhcp config -hops $hops_value
                                }
                                if {[info exist transactionID_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ transactionID: $transactionID_value"}
                                    dhcp config -transactionID $transactionID_value
                                }
                                 if {[info exist seconds_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ seconds: $seconds_value"}
                                    dhcp config -seconds $seconds_value
                                }
                                if {[info exist flags_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ flags: $flags_value"}
                                    switch  -regexp -nocase -- $flags_value {
                                        dhcpnobroadcast { dhcp config -flags 0 }
                                        dhcpbroadcast  { dhcp config -flags 0x8000 }
                                        default {puts  "!!!!config_frame: input dhcp flags error"}
                                    }
                                } 
                                if {[info exist clientIpAddr_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ clientIpAddr: $clientIpAddr_value"}
                                    dhcp config -clientIpAddr $clientIpAddr_value
                                }
                                if {[info exist yourIpAddr_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ yourIpAddr: $yourIpAddr_value"}
                                    dhcp config -yourIpAddr $yourIpAddr_value
                                }
                                if {[info exist serverIpAddr_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ serverIpAddr: $serverIpAddr_value"}
                                    dhcp config -serverIpAddr $serverIpAddr_value
                                }
                                if {[info exist relayAgentIpAddr_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ relayAgentIpAddr: $relayAgentIpAddr_value"}
                                    dhcp config -relayAgentIpAddr $relayAgentIpAddr_value
                                }
                                if {[info exist clientHwAddr_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ clientHwAddr: $clientHwAddr_value"}
                                    dhcp config -clientHwAddr $clientHwAddr_value
                                }
                                if {[info exist serverHostName_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ serverHostName: $serverHostName_value"}
                                    dhcp config -serverHostName $serverHostName_value
                                }
                                if {[info exist bootFileName_value]} {
                                    if {$dbgprt_value == 1} {puts "@@ bootFileName: $bootFileName_value"}
                                      dhcp config -bootFileName $bootFileName_value
                                }
                                if {[info exist option_value]} { 
                                	set A [split $option_value \;] 
                                    foreach B $A { 
                                       set value  [split $B ,]
                                	   set option [lindex $value 0]
                                	   set data [lindex $value 1] 
                                	       if {$dbgprt_value == 1} {
                                             puts "@@ optionCode: $option"
                                             puts "@@ optionData: $data"
                                        }
                                          dhcp config -optionData $data
                                          dhcp setOption $option
                                    }       
                                }
                                dhcp config -optionCode                         0
                                dhcp config -optionDataLength                   0
                                dhcp setOption                dhcpEnd
                                puts "--------DHCP parameters end-------"
                                dhcp set $chasNum $cardNum $portNum
                            }                            
        }
####################################----miles add DHCP API------#########################################
		if {[info exist dscpvalue_value]} {
			ip config -dscpValue [dectohex $dscpvalue_value]
		}		
		if {[info exist srcip_value]} {
			ip config -sourceIpAddr $srcip_value
		}
		if {[info exist dstip_value]} {
			ip config -destIpAddr $dstip_value 
		}
		# added by jerry 20131204,start
		if {[info exist ipv6src_value]} {
			if {$dbgprt_value == 1} {puts "@@ ipv6src_value: $ipv6src_value"}
			ipV6 config -sourceAddr $ipv6src_value
		}
		if {[info exist ipv6des_value]} {
			if {$dbgprt_value == 1} {puts "@@ ipv6des_value: $ipv6des_value"}
			ipV6 config -destAddr $ipv6des_value
		}

		if {[info exist mldv1_value]} {
			
			ipV6 config -hopLimit 1
			ipV6 clearAllExtensionHeaders
			ipV6HopByHop clearAllOptions
			ipV6OptionPADN setDefault
			ipV6HopByHop addOption ipV6OptionPADN
			ipV6OptionRouterAlert setDefault
			ipV6HopByHop addOption ipV6OptionRouterAlert
			ipV6 addExtensionHeader ipV6HopByHopOption
			ipV6 addExtensionHeader icmpV6
			ipV6 set $chasNum $cardNum $portNum
			icmpV6 setDefault
			switch $mldv1_value {
				query {icmpV6 setType icmpV6MulticastListenerQueryMessage }
				report {icmpV6 setType icmpV6MulticastListenerReportMessage}
				done {icmpV6 setType icmpV6MulticastListenerDoneMessage }
			}
		}
		if {[info exist groupmldv1_value]} {
			icmpV6MulticastListener setDefault
			icmpV6MulticastListener config -multicastAddress $groupmldv1_value
			icmpV6 set $chasNum $cardNum $portNum
		}
		# add by jerry 20131204,end
		# added by andym 20130521,start
		if {[info exist igmptype_value]} {
			ip setDefault
			ip config -ipProtocol igmp
			ip config -sourceIpAddr $srcip_value
			ip config -destIpAddr $dstip_value
			ip config -sourceClass classC
			ip config -destClass classC
			ip config -ttl 1

			igmp setDefault
			switch $igmptype_value {
     			query     {igmp config -type membershipQuery}
     			v1report	{igmp config -type membershipReport1}
     			v2report	{igmp config -type membershipReport2}
     			v3report    {igmp config -version igmpVersion3 ; igmp config -type membershipReport3}
     			leave       {igmp config -type leaveGroup}
			}
		}
		if {[info exist groupip_value]} {
			igmp config -groupIpAddress $groupip_value
			igmp set $chasNum $cardNum $portNum
		}
		# added by andym 20130521,end
		
		# added by jerry 20131211,start
		set v3_num 0
		set v3_include_num 0
		set v3_exclude_num 0
		set handle_length [llength $handlelist]
		foreach canshu1 $handlelist {
			if {[regexp {^v3groupip(.*)$} $canshu1 all num]} {
				incr v3_num
			}
		}
		foreach canshu2 $handlelist {
			if {[regexp {^v3includeip(.*)} $canshu2 all num]} {
				incr v3_include_num
			}
		}
		foreach canshu3 $handlelist {
			if {[regexp {^v3excludeip(.*)} $canshu3 all num]} {
				incr v3_exclude_num
			}
		}
		if {$v3_num==0} {
			igmp addGroupRecord
			igmp set $chasNum $cardNum $portNum
		}
		if {$v3_num==[expr $v3_include_num+$v3_exclude_num] && $v3_num!=0} {
			igmp clearGroupRecords
			igmpGroupRecord setDefault
			for {set n 1} {$n<=$v3_num} {incr n} {

				igmpGroupRecord config -multicastAddress [subst $[subst v3groupip[subst $n]_value]]
				set loop_temp 0

				foreach temp $handlelist {
					incr loop_temp
					set group_type [string range $temp 2 end]
					if {$group_type==[subst includeip$n]} {
						igmpGroupRecord config -type 1
						break
					} elseif {$group_type==[subst excludeip$n]} {
						igmpGroupRecord config -type 2
						break
					}
					if {$loop_temp==$handle_length} { 
						puts "the option of -v3includeip or -v3excludeip must be wrong"
						return
					}
					
				}

			igmpGroupRecord config -sourceIpAddressList  [subst $[subst [subst $temp]_value]]
			igmp addGroupRecord
			}
			igmp set $chasNum $cardNum $portNum
		}


		#added by jerry 20131211,end
		if {[info exist srcmac_value]} {
			set macsaformat [join $srcmac_value]
			stream config -sa $macsaformat
		}
		if {[info exist srcmacmode_value]} {
			switch $srcmacmode_value {
				fixed {stream config -saRepeatCounter idle}
				increment {stream config -saRepeatCounter increment}
				default {uWriteExp -errorinfo "input frame srcmacmode error"}
			} 
		}
		if {[info exist srcstep_value]} {
			stream config -saStep $srcstep_value
		}
		if {[info exist srcrepeatcount_value]} {
			stream config -numSA $srcrepeatcount_value
		}	
		if {[info exist dstmac_value]} {
			set macdaformat [join $dstmac_value]
			stream config -da $macdaformat
		}
		if {[info exist dstmacmode_value]} {
			switch $dstmacmode_value {
				fixed {stream config -daRepeatCounter idle} 
				increment {stream config -daRepeatCounter increment} 
				default {uWriteExp -errorinfo "input frame dstmacmode error"}
			} 
		}
		if {[info exist dststep_value]} {
			stream config -daStep $dststep_value
		}
		if {[info exist dstrepeatcount_value]} {
			stream config -numDA $dstrepeatcount_value
		}
		if {[info exist framesize_value]} {
			stream config -framesize $framesize_value
		}
		
		
		set getvlanmode [protocol cget -enable802dot1qTag]
		if {$getvlanmode == "2"} {
			stackedVlan set $chasNum $cardNum $portNum
		} elseif {$getvlanmode == "1"} {
			vlan set $chasNum $cardNum $portNum
		}
		
		if {[info exist vlanmode_value]} {
			switch $vlanmode_value {
				singlevlan {vlan set $chasNum $cardNum $portNum}
				qinq {stackedVlan set $chasNum $cardNum $portNum}
			}
		}
		############## andy 2014-1-14 add ipV6 set ############
		if {[info exist ethernetname_value] } {
		 	if {$ethernetname_value == "ipv6" } {
		 		ipV6 set $chasNum $cardNum $portNum
		 	} else {
		 		ip set $chasNum $cardNum $portNum
		 	}
		} else {
		 	ip set $chasNum $cardNum $portNum
		 }
		############# andy 2014-1-14##############
		stream set $chasNum $cardNum $portNum 1
		stream write $chasNum $cardNum $portNum 1
		
	}
	ixWriteConfigToHardware $alias_value
	set logStr "config_frame $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}


# -alias             (select ports to set stream)
# -sendmode          (packet send mode,[contpkt|contbst|stopstrm])
# -ratemode          (packets rate mode [fps|bps|default], the default is percent rate)
# -rate              (packets rate value)
# -fcs               (stream error mode [good|alignment|dribble|badcrc|nocrc])
# -pktperbst         (set how many pakets in a burst,used for stopstrm mode)
# -bstperstrm        (how many burst in s stream ,used for stopstrm mode)
# config_stream -alias allport -sendmode contpkt 
# Function: config the sream of the frame, set a port to send packet in which mode
proc config_stream {args} {
	global tcLogId
	#1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "config_stream: alias is a mandatory parameter but missing"
	}
	
	foreach port [subst $$alias_value] {
		scan $port "%d %d %d" chasNum cardNum portNum
		stream get $chasNum $cardNum $portNum 1
	
		if {[info exist sendmode_value]} {
			switch $sendmode_value {
				contpkt {stream config -dma contPacket}
				contbst {stream config -dma contBurst}
				stopstrm {stream config -dma stopStream}
				default {return fail}
			}			
		}
		if {[info exist fcs_value]} {
			switch $fcs_value {
				good      {stream config -fcs streamErrorGood }
				alignment {stream config -fcs streamErrorAlignment }
				dribble   {stream config -fcs streamErrorDribble }
				badcrc    {stream config -fcs streamErrorBadCRC }
				nocrc    {stream config -fcs streamErrorNoCRC }
				default {stream config -fcs streamErrorGood }
			}
		}
		if {[info exist ratemode_value]} {
			switch $ratemode_value {
				fps {stream config -rateMode streamRateModeFps }
				bps {stream config -rateMode streamRateModeBps }
				default {stream config -rateMode streamRateModePercentRate }
			}
		}
		if {[info exist fpsrate_value]} {
			stream config -fpsRate $fpsrate_value
		}
		if {[info exist rate_value]} {
			stream config -percentPacketRate $rate_value
		}
		if {[info exist pktperbst_value]} {
			stream config -numFrames $pktperbst_value
		}
		if {[info exist bstperstrm_value]} {
			stream config -numBursts $bstperstrm_value
		}
		
		stream set $chasNum $cardNum $portNum 1
		stream write $chasNum $cardNum $portNum 1
	}
	set logStr "config_stream $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}


# -alias
# -uds1   used for get port status
# -uds1da
# -uds1sa
# -uds2   used for get port status
# -uds2da
# -uds2sa
# -uds3   used for config trigger
# -uds3da
# -uds3sa
# -uds4   used for config filter
# -uds4da
# -uds4sa
# -da1addr
# -da1mask
# -da2addr
# -da2mask
# -sa1addr
# -sa1mask
# -sa2addr
# -sa2mask
# -statmode
# -qospkgtype
# config_filter -alias ixiap1 -uds3 enable -uds3sa sa1 -uds3da da1 -sa1addr "00 00 00 00 00 01" -da1addr "00 00 00 00 00 02"
proc config_filter {args} {
	global tcLogId
	#1.1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#1.2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "config_filter: alias is a mandatory parameter but missing"
	}
	
	global [subst $alias_value]
	foreach port [subst $$alias_value] {
		scan $port "%d %d %d" chasNum cardNum portNum
		filter get $chasNum $cardNum $portNum
		filterPallette get $chasNum $cardNum $portNum
		stat get allStats $chasNum $cardNum $portNum
		qos get $chasNum $cardNum $portNum
	
		#2. get and set uds1 value
		if {[info exist uds1_value]} {
			switch $uds1_value {
				enable {filter config -userDefinedStat1Enable true}
				disbale {filter config -userDefinedStat1Enable false}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds1 input error!"}
			}
		}
		#3. get and set uds1da value
		if {[info exist uds1da_value]} {
			switch $uds1da_value {
				any {filter config -userDefinedStat1DA anyAddr}
				da1 {filter config -userDefinedStat1DA addr1}
				notda1 {filter config -userDefinedStat1DA notAddr1}
				da2 {filter config -userDefinedStat1DA addr2}
				notda2 {filter config -userDefinedStat1DA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds1da input error!"}
			}
		}
		#4. get and set uds1sa value
		if {[info exist uds1sa_value]} {
			switch $uds1sa_value {
				any {filter config -userDefinedStat1SA anyAddr}
				sa1 {filter config -userDefinedStat1SA addr1}
				notsa1 {filter config -userDefinedStat1SA notAddr1}
				sa2 {filter config -userDefinedStat1SA addr2}
				notsa2 {filter config -userDefinedStat1SA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds1sa input error!"}
			}
		}
		#5. get and set uds2 value
		if {[info exist uds2_value]} {
			switch $uds2_value {
				enable {filter config -userDefinedStat2Enable true}
				disbale {filter config -userDefinedStat2Enable false}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds2 input error!"}
			}
		}
		#6. get and set uds2da value
		if {[info exist uds2da_value]} {
			switch $uds2da_value {
				any {filter config -userDefinedStat2DA anyAddr}
				da1 {filter config -userDefinedStat2DA addr1}
				notda1 {filter config -userDefinedStat2DA notAddr1}
				da2 {filter config -userDefinedStat2DA addr2}
				notda2 {filter config -userDefinedStat2DA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds2da input error!"}
			}
		}
		#7. get and set uds2sa value
		if {[info exist uds2sa_value]} {
			switch $uds2sa_value {
				any {filter config -userDefinedStat2SA anyAddr}
				sa1 {filter config -userDefinedStat2SA addr1}
				notsa1 {filter config -userDefinedStat2SA notAddr1}
				sa2 {filter config -userDefinedStat2SA addr2}
				notsa2 {filter config -userDefinedStat2SA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds2sa input error!"}
			}
		}
		#8. get and set uds3 value
		if {[info exist uds3_value]} {
			switch $uds3_value {
				enable {filter config -captureTriggerEnable true}
				disbale {filter config -captureTriggerEnable false}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds3 input error!"}
			}
		}
		#9. get and set uds3da value
		if {[info exist uds3da_value]} {
			switch $uds3da_value {
				any 	{filter config -captureTriggerDA anyAddr}
				da1		{filter config -captureTriggerDA addr1}
				notda1	{filter config -captureTriggerDA notAddr1}
				da2		{filter config -captureTriggerDA addr2}
				notda2	{filter config -captureTriggerDA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds3da input error!"}
			}
		}
		#10. get and set uds3sa value
		if {[info exist uds3sa_value]} {
			switch $uds3sa_value {
				any 	{filter config -captureTriggerSA anyAddr}
				sa1     {filter config -captureTriggerSA addr1}
				notsa1  {filter config -captureTriggerSA notAddr1}
				sa2     {filter config -captureTriggerSA addr2}
				notsa2  {filter config -captureTriggerSA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds3sa input error!"}
			}
		}
		#11. get and set uds4 value
		if {[info exist uds4_value]} {
			switch $uds4_value {
				enable {filter config -captureTriggerEnable true}
				disbale {filter config -captureTriggerEnable false}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds4 input error!"}
			}
		}
		#12. get and set uds4da value
		if {[info exist uds4da_value]} {
			switch $uds4da_value {
				any 	{filter config -captureFilterDA anyAddr}
				da1     {filter config -captureFilterDA addr1}
				notda1	{filter config -captureFilterDA notAddr1}
				da2		{filter config -captureFilterDA addr2}
				notda2	{filter config -captureFilterDA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds4da input error!"}
			}
		}
		#13. get and set uds4sa value
		if {[info exist uds4sa_value]} {
			switch $uds4sa_value {
				any 	{filter config -captureFilterSA anyAddr}
				sa1		{filter config -captureFilterSA addr1}
				notsa1	{filter config -captureFilterSA notAddr1}
				sa2		{filter config -captureFilterSA addr2}
				notsa2	{filter config -captureFilterSA notAddr2}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, uds4sa input error!"}
			}
		}
		#14. get and set da1addr value
		if {[info exist da1addr_value]} {
			filterPallette config -DA1 $da1addr_value
		}
		#15. get and set da1mask value
		if {[info exist da1mask_value]} {
			filterPallette config -DAMask1 $da1mask_value
		}
		#16. get and set da2addr value
		if {[info exist da2addr_value]} {
			filterPallette config -DA2 $da2addr_value
		}
		#17. get and set da2mask value
		if {[info exist da2mask_value]} {
			filterPallette config -DAMask2 $da2mask_value
		}
		#18. get and set sa1addr value
		if {[info exist sa1addr_value]} {
			filterPallette config -SA1 $sa1addr_value
		}
		#19. get and set sa1mask value
		if {[info exist sa1mask_value]} {
			filterPallette config -SAMask1 $sa1mask_value
		}
		#20. get and set sa2addr value
		if {[info exist sa2addr_value]} {
			filterPallette config -SA2 $sa2addr_value
		}
		#21. get and set sa2mask value
		if {[info exist sa2mask_value]} {
			filterPallette config -SAMask2 $sa2mask_value
		}
		#22. get and set statmode value
		if {[info exist statmode_value]} {
			switch $statmode_value {
				normal	{stat config -mode statNormal}
				qos		{stat config -mode statQos}
				default {uWriteExp -errorinfo "proc: config_filter, args: $args, statmode input error!"}
			}
		}
		#23. get and set qospkgtype value
		if {[info exist qospkgtype_value]} {
			switch $qospkgtype_value {
				ethernetii  {qos config -packetType ipEthernetII}
				802.3		{qos config -packetType ip8023Snap}
				vlan		{qos config -packetType vlan}
				default 	{uWriteExp -errorinfo "proc: config_filter, args: $args, qospkgtype input error!"}
			}
		}
		
		filter set $chasNum $cardNum $portNum
		filterPallette set $chasNum $cardNum $portNum
		stat set $chasNum $cardNum $portNum
		qos set $chasNum $cardNum $portNum
	}
	ixWriteConfigToHardware $alias_value
	
	set logStr "config_filter $args"
	puts $logStr
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}


# -alias
# clear_stat -alias allport
# clear_stat -alias ixiap1
# Function: clear all status or counter value of the port
#           This should be used before you start a new capture
proc clear_stat {args} {
	global tcLogId
	set aftertime 1000
	#1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "clear_stat: alias is a mandatory parameter but missing"
	}

	ixClearStats $alias_value
	after $aftertime
	set logStr "clear_stat $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}

# -actiontype     (the operator type [start|stop])
# -time           (how long you keep sending the stream)
# send_traffic -alias allport -actiontype start -time 5
# Function: after you config a frame and stream, you can start to send traffic with this API
proc send_traffic {args} {
	global tcLogId
	set aftertime 200
	#1. get command and handle/parameters
	set dbgprt_value 0
	after 1000
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "send_traffic: alias is a mandatory parameter but missing"
	}
	
	if {[info exist actiontype_value]} {
		#ixConnectToChassis $glipaddress
		switch $actiontype_value {
			start {ixStartTransmit $alias_value; after $aftertime; puts "start to transmit the traffic"}
			stop {ixStopTransmit $alias_value; after $aftertime}
			default {uWriteExp -errorinfo "input actiontype error"}
		}
	}	
	if {[info exist time_value]} {
		after [expr $time_value *1000]
		ixStopTransmit $alias_value
		puts "stop transmit the traffic"
		after $aftertime
	}
	set logStr "send_traffic $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}


# -alias
# -txframe
# -txbyte
# -rxframe
# -rxbyte
# -rxundersize
# -rxoversize
# -rxvlantagged
# -rxcrcerror
# -rxqos0
# -rxqos1
# -rxqos2
# -rxqos3
# -rxqos4
# -rxqos5
# -rxqos6
# -rxqos7
# -rxuds1
# -rxuds2
# -rxuds3
# -rxuds4
# get_stat -alias ixiap1 -txframe ixiap1tx -rxframe ixiap1rx (Get the counter of frames)
proc get_stat {args} {
	global tcLogId
	#1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#2. get all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "get_framestat: alias is a mandatory parameter but missing"
	}
	
	foreach port [subst $$alias_value] {
		scan $port "%d %d %d" chasNum cardNum portNum
		stat get statAllStats $chasNum $cardNum $portNum
	}
	
	if {[info exist txframe_value]} {
		set framesend [stat cget -framesSent]
		eval [subst {uplevel 1 {set $txframe_value $framesend}}]
	}
	if {[info exist txbyte_value]} {
		set bytessend [stat cget -bytesSent]
		eval [subst {uplevel 1 {set $txbyte_value $bytessend}}]
	}
	if {[info exist rxframe_value]} {
		set framesreceived [stat cget -framesReceived]
		eval [subst {uplevel 1 {set $rxframe_value $framesreceived}}]
	}
	if {[info exist rxbyte_value]} {
		set bytesreceived [stat cget -bytesReceived]
		eval [subst {uplevel 1 {set $rxbyte_value $bytesreceived}}]
	}
	if {[info exist rxundersize_value]} {
		set undersize [stat cget -undersize]
		eval [subst {uplevel 1 {set $rxundersize_value $undersize}}]
	}
	if {[info exist rxoversize_value]} {
		set oversize [stat cget -oversize]
		eval [subst {uplevel 1 {set $rxoversize_value $oversize}}]		
	}	
	if {[info exist rxvlantagged_value]} {
		set vlantagged [stat cget -vlanTaggedFramesRx]
		eval [subst {uplevel 1 {set $rxvlantagged_value $vlantagged}}]				
	}
	if {[info exist rxcrcerror_value]} {
		set crcerrors [stat cget -codingErrorFramesReceived] 
		eval [subst {uplevel 1 {set $rxcrcerror_value $crcerrors}}]		
	}
	if {[info exist rxqos0_value]} {
		set qualityofservice0 [stat cget -qualityOfService0]
		eval [subst {uplevel 1 {set $rxqos0_value $qualityofservice0}}]				
	}
	if {[info exist rxqos1_value]} {
		set qualityofservice1 [stat cget -qualityOfService1]
		eval [subst {uplevel 1 {set $rxqos1_value $qualityofservice1}}]						
	}
	if {[info exist rxqos2_value]} {
		set qualityofservice2 [stat cget -qualityOfService2]
		eval [subst {uplevel 1 {set $rxqos2_value $qualityofservice2}}]								
	}
	if {[info exist rxqos3_value]} {
		set qualityofservice3 [stat cget -qualityOfService3]
		eval [subst {uplevel 1 {set $rxqos3_value $qualityofservice3}}]							
	}	
	if {[info exist rxqos4_value]} {
		set qualityofservice4 [stat cget -qualityOfService4]
		eval [subst {uplevel 1 {set $rxqos4_value $qualityofservice4}}]							
	}		
	if {[info exist rxqos5_value]} {
		set qualityofservice5 [stat cget -qualityOfService5]
		eval [subst {uplevel 1 {set $rxqos5_value $qualityofservice5}}]								
	}			
	if {[info exist rxqos6_value]} {
		set qualityofservice6 [stat cget -qualityOfService6]
		eval [subst {uplevel 1 {set $rxqos6_value $qualityofservice6}}]							
	}			
	if {[info exist rxqos7_value]} {
		set qualityofservice7 [stat cget -qualityOfService7]
		eval [subst {uplevel 1 {set $rxqos7_value $qualityofservice7}}]							
	}			
	if {[info exist rxqos8_value]} {
		set qualityofservice8 [stat cget -qualityOfService8]
		eval [subst {uplevel 1 {set $rxqos8_value $qualityofservice8}}]							
	}				
	if {[info exist rxuds1_value]} {
		set userdefinedstat1 [stat cget -userDefinedStat1]
		eval [subst {uplevel 1 {set $rxuds1_value $userdefinedstat1}}]
	}
	if {[info exist rxuds2_value]} {
		set userdefinedstat2 [stat cget -userDefinedStat2]
		eval [subst {uplevel 1 {set $rxuds2_value $userdefinedstat2}}]		
	}
	if {[info exist rxuds3_value]} {
		set trigger [stat cget -captureTrigger]
		eval [subst {uplevel 1 {set $rxuds3_value $trigger}}]		
	}
	if {[info exist rxuds4_value]} {
		set filter [stat cget -captureFilter]
		eval [subst {uplevel 1 {set $rxuds4_value $filter}}]		
	}
	#puts "get_stat $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}

# -alias
# -txframe
# -txbyte
# -rxframe
# -rxbyte
# -rxundersize
# -rxoversize
# -rxvlantagged
# -rxcrcerror
# -rxqos0
# -rxqos1
# -rxqos2
# -rxqos3
# -rxqos4
# -rxqos5
# -rxqos6
# -rxqos7
# -rxuds1
# -rxuds2
# -rxuds3
# -rxuds4
# -times
# get_ratestat -alias ixiap1 -txframe ixiap1tx -rxframe ixiap1rx -times 10
proc get_ratestat {args} {
	global tcLogId
	set aftertime 1000
	#1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#2. get all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "get_framestat: alias is a mandatory parameter but missing"
	}
	
	after $aftertime
	foreach port [subst $$alias_value] {
		scan $port "%d %d %d" chasNum cardNum portNum
		stat getRate statAllStats $chasNum $cardNum $portNum
	}
	
	if {[info exist txframe_value]} {
		set framesend [stat cget -framesSent]
		eval [subst {uplevel 1 {set $txframe_value $framesend}}]
	}
	if {[info exist txbyte_value]} {
		set bytessend [stat cget -bytesSent]
		eval [subst {uplevel 1 {set $txbyte_value $bytessend}}]
	}
	if {[info exist rxframe_value]} {
		set framesreceived [stat cget -framesReceived]
		eval [subst {uplevel 1 {set $rxframe_value $framesreceived}}]
	}
	if {[info exist rxbyte_value]} {
		set bytesreceived [stat cget -bytesReceived]
		eval [subst {uplevel 1 {set $rxbyte_value $bytesreceived}}]
	}
	if {[info exist rxundersize_value]} {
		set undersize [stat cget -undersize]
		eval [subst {uplevel 1 {set $rxundersize_value $undersize}}]
	}
	if {[info exist rxoversize_value]} {
		set oversize [stat cget -oversize]
		eval [subst {uplevel 1 {set $rxoversize_value $oversize}}]		
	}	
	if {[info exist rxvlantagged_value]} {
		set vlantagged [stat cget -vlanTaggedFramesRx]
		eval [subst {uplevel 1 {set $rxvlantagged_value $vlantagged}}]				
	}
	if {[info exist rxcrcerror_value]} {
		set crcerrors [stat cget -codingErrorFramesReceived] 
		eval [subst {uplevel 1 {set $rxcrcerror_value $crcerrors}}]		
	}
	if {[info exist rxqos0_value]} {
		set qualityofservice0 [stat cget -qualityOfService0]
		eval [subst {uplevel 1 {set $rxqos0_value $qualityofservice0}}]				
	}
	if {[info exist rxqos1_value]} {
		set qualityofservice1 [stat cget -qualityOfService1]
		eval [subst {uplevel 1 {set $rxqos1_value $qualityofservice1}}]						
	}
	if {[info exist rxqos2_value]} {
		set qualityofservice2 [stat cget -qualityOfService2]
		eval [subst {uplevel 1 {set $rxqos2_value $qualityofservice2}}]								
	}
	if {[info exist rxqos3_value]} {
		set qualityofservice3 [stat cget -qualityOfService3]
		eval [subst {uplevel 1 {set $rxqos3_value $qualityofservice3}}]							
	}	
	if {[info exist rxqos4_value]} {
		set qualityofservice4 [stat cget -qualityOfService4]
		eval [subst {uplevel 1 {set $rxqos4_value $qualityofservice4}}]							
	}		
	if {[info exist rxqos5_value]} {
		set qualityofservice5 [stat cget -qualityOfService5]
		eval [subst {uplevel 1 {set $rxqos5_value $qualityofservice5}}]								
	}			
	if {[info exist rxqos6_value]} {
		set qualityofservice6 [stat cget -qualityOfService6]
		eval [subst {uplevel 1 {set $rxqos6_value $qualityofservice6}}]							
	}			
	if {[info exist rxqos7_value]} {
		set qualityofservice7 [stat cget -qualityOfService7]
		eval [subst {uplevel 1 {set $rxqos7_value $qualityofservice7}}]							
	}			
	if {[info exist rxqos8_value]} {
		set qualityofservice8 [stat cget -qualityOfService8]
		eval [subst {uplevel 1 {set $rxqos8_value $qualityofservice8}}]							
	}				
	if {[info exist rxuds1_value]} {
		set userdefinedstat1 [stat cget -userDefinedStat1]
		eval [subst {uplevel 1 {set $rxuds1_value $userdefinedstat1}}]
	}
	if {[info exist rxuds2_value]} {
		set userdefinedstat2 [stat cget -userDefinedStat2]
		eval [subst {uplevel 1 {set $rxuds2_value $userdefinedstat2}}]		
	}
	if {[info exist rxuds3_value]} {
		set trigger [stat cget -captureTrigger]
		eval [subst {uplevel 1 {set $rxuds3_value $trigger}}]		
	}
	if {[info exist rxuds4_value]} {
		set filter [stat cget -captureFilter]
		eval [subst {uplevel 1 {set $rxuds4_value $filter}}]		
	}
	set logStr "get_ratestat $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}


# -para1 		number
# -para2 		number
# -condition 	[=|!=|>|<|>=|<=]	default =
#			 	[equal|notequal|more|less|moreequal|lessequal]
# -percentage 	20
# -number		100
# -log 			string
# check_result -para1 $ixiap1tx -para2 $ixiap2rx -condition = -log "ixiap1tx: $ixiap1tx equal ixiap2rx $ixiap2rx"
proc check_result {args} {
	global tcLogId
	#1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#2. get all of the parameters value
	if {[info exist para1_value]} {
		if {$dbgprt_value == 1} {puts "@@ para1: $para1_value"}
	} else {
		uWriteExp -errorinfo "check_result: para1 is a mandatory parameter but missing"
	}
	
	if {[info exist para2_value]} {
		if {$dbgprt_value == 1} {puts "@@ para2: $para2_value"}
	} else {
		uWriteExp -errorinfo "check_result: para2 is a mandatory parameter but missing"
	}
	
	if {![info exist condition_value]} {
		set condition_value =
	}
	if {$dbgprt_value == 1} {puts "@@ condition: $condition_value"}
	
	if {[info exist percentage_value]} {
		if {$dbgprt_value == 1} {puts "@@ percentage: $percentage_value"}
	}

	if {[info exist number_value]} {
		if {$dbgprt_value == 1} {puts "@@ number: $number_value"}
	}
	
	if {![info exist log_value]} {
		set log_value ""
	}
	
	# condition: =
	if {[regexp {^=$|^equal$} $condition_value]} {
		if {[expr $para1_value - $para2_value] == 0} {
			set res 1
		} else {
			set res 0
		}
	}
	# condition: !=	,abs(1-2)/2<=percentage and abs(1-2)<=number
	if {[regexp {^!=$|^notequal$} $condition_value]} {
		if {[expr $para1_value - $para2_value] == 0} {
			set res 0
		} elseif {[expr $para1_value - $para2_value] != 0} {
			if {[info exist percentage_value] | [info exist number_value]} {
				set res21 [expr abs([expr $para1_value - $para2_value]) * 1.00 / $para2_value]
				set res22 [expr abs([expr $para1_value - $para2_value]) * 1.00]
				if {[info exist percentage_value]} {
					if {$res21 <= [expr $percentage_value / 100.00]} {
						set res1 1
					} else {
						set res1 0
					}
				} else {
					set res1 1
				}
				if {[info exist number_value]} {
					if {$res22 <= $number_value} {
						set res2 1
					} else {
						set res2 0
					}
				} else {
					set res2 1
				}
				set res [expr $res1 && $res2]
			} else {
				set res 1
			}
		}
	}
	
	# condition: >	, 1-2<number and (1-2)/2<percentage
	if {[regexp {^>$|^more$} $condition_value]} {
		if {[expr $para1_value - $para2_value] <= 0} {
			set res 0
		} elseif {[expr $para1_value - $para2_value] > 0} {
			if {[info exist percentage_value] | [info exist number_value]} {
				set res31 [expr ($para1_value - $para2_value) * 1.00 / $para2_value]
				set res32 [expr $para1_value - $para2_value]
				if {[info exist percentage_value]} {
					if {$res31 < [expr $percentage_value / 100.00]} {
						set res1 1
					} else {
						set res1 0
					}
				} else {
					set res1 1
				}
				if {[info exist number_value]} {
					if {$res32 < $number_value} {
						set res2 1
					} else {
						set res2 0
					}
				} else {
					set res2 1
				}
				set res [expr $res1 && $res2]
			} else {
				set res 1
			}
		}
	}
	
	# condition: <	, 2-1<number and (2-1)/2<percentage
	if {[regexp {^<$|^less$} $condition_value]} {
		if {[expr $para2_value - $para1_value] <= 0} {
			set res 0
		} elseif {[expr $para2_value - $para1_value] > 0} {
			set res 1
			if {[info exist percentage_value] | [info exist number_value]} {
				set res41 [expr ($para2_value - $para1_value) * 1.00 / $para2_value]
				set res42 [expr $para2_value - $para1_value]
				if {[info exist percentage_value]} {
					if {$res41 < [expr $percentage_value / 100.00]} {
						set res1 1
					} else {
						set res1 0
					}
				} else {
					set res1 1
				}
				if {[info exist number_value]} {
					if {$res42 < $number_value} {
						set res2 1
					} else {
						set res2 0
					}
				} else {
					set res2 1
				}
				set res [expr $res1 && $res2]
			}
		}
	}
	
	
	# condition: >=	, 1-2<=number and (1-2)/2<=percentage
	if {[regexp {^>=$|^moreequal$} $condition_value]} {
		if {[expr $para1_value - $para2_value] < 0} {
			set res 0
		} elseif {[expr $para1_value - $para2_value] >= 0} {
			if {[info exist percentage_value] | [info exist number_value]} {
				set res51 [expr ($para1_value - $para2_value) * 1.00 / $para2_value]
				set res52 [expr $para1_value - $para2_value]
				if {[info exist percentage_value]} {
					if {$res51 <= [expr $percentage_value / 100.00]} {
						set res1 1
					} else {
						set res1 0
					}
				} else {
					set res1 1
				}
				if {[info exist number_value]} {
					if {$res52 <= $number_value} {
						set res2 1
					} else {
						set res2 0
					}
				} else {
					set res2 1
				}
				set res [expr $res1 && $res2]
			} else {
				set res 1
			}
		}
	}
	
	# condition: <=	, 2-1<=number and (2-1)/1<=percentage
	if {[regexp {^<=$|^lessequal$} $condition_value]} {
		if {[expr $para2_value - $para1_value] < 0} {
			set res 0
		} elseif {[expr $para2_value - $para1_value] >= 0} {
			set res 1
			if {[info exist percentage_value] | [info exist number_value]} {
				set res61 [expr ($para2_value - $para1_value) * 1.00 / $para2_value]
				set res62 [expr $para2_value - $para1_value]
				if {[info exist percentage_value]} {
					if {$res61 <= [expr $percentage_value / 100.00]} {
						set res1 1
					} else {
						set res1 0
					}
				} else {
					set res1 1
				}
				if {[info exist number_value]} {
					if {$res62 <= $number_value} {
						set res2 1
					} else {
						set res2 0
					}
				} else {
					set res2 1
				}
				set res [expr $res1 && $res2]
			}
		}
	}
	
	if {$res} {
		set result pass
	} else {
		set result fail
	}
	set logStr "check_result, $log_value"
	set commStr "$args"
	puts "logStr: $logStr ,commStr: $commStr"
	#printlog -fileid $tcLogId -res $result -cmd $logStr -comment $commStr

}

# -alias           (the port/ports you want to capture packets)
# start_capture -alias ixiap1
# Function: start to capture packets on any port/ports
proc start_capture {args} {
	#global tcLogId
	#1.1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#1.2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "config_filter: alias is a mandatory parameter but missing"
	}
	global [subst $alias_value]
	ixStartCapture $alias_value
	set logStr "start_capture $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
}

# -alias     
# -framedata     (old parameters,abandoned)
# stop_capture -alias ixiap1
# Function: stop capture on a port
proc stop_capture {args} {
	#global tcLogId
	set aftertime 1000
	#1.1. get command and handle/parameters
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
		if {[string first length $item1] >=0} {incr paraNum}
		if {[string first srcmac $item1] >=0} {incr paraNum}
		if {[string first dstmac $item1] >=0} {incr paraNum}
		if {[string first protocol $item1] >=0} {incr paraNum}
	}
	if {$dbgprt_value == 1} {puts "@@ paraNum: $paraNum"}
	#1.2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "stop_capture: alias is a mandatory parameter but missing"
	}
	
	global [subst $alias_value]
	ixStopCapture $alias_value
	after $aftertime
	
	# foreach port [subst $$alias_value] {
	# 	scan $port "%d %d %d" chasNum cardNum portNum
	# 	capture get $chasNum $cardNum $portNum
	# 	set numCaptured [capture cget -nPackets]
	# 	if {$dbgprt_value == 1} {puts "@@ numCaptured: $numCaptured"}
	# 	#captureBuffer get $chasNum $cardNum $portNum 1 $numCaptured
	# 	captureBuffer get $chasNum $cardNum $portNum 1 100
	# }
	# #puts "Got [expr $numCaptured -1 ] packets captured"
	# set gotFrameData ""
	# set j 0
	# for {set i 1} {$i <=  $numCaptured } {incr i} {
		
	# 	captureBuffer getframe $i

	# 	set bufferdata [captureBuffer cget -frame]
	# 	if {$dbgprt_value == 1 && $i <= 10} {puts "@@ bufferdata: $bufferdata"}
	# 	if {[info exist length_value]} {
	# 		captureBuffer getframe $i
	# 		set sortframesize [captureBuffer cget -length]
	# 		if {$dbgprt_value == 1 && $i <= 10} {puts "@@ framesize: $sortframesize"}
	# 		if {"$sortframesize" != "$length_value"} {
	# 			continue
	# 		}
	# 	}
	# 	if {[info exist dstmac_value]} {
	# 		captureBuffer getframe $i
	# 		set sortdamac [lrange $bufferdata 0 5]
	# 		if {$dbgprt_value == 1 && $i <= 10} {puts "@@ damac: $sortdamac"}
	# 		if {[string first "$sortdamac" "$dstmac_value"] < 0} {
	# 			continue
	# 		}
	# 	}
	# 	if {[info exist srcmac_value]} {
	# 		captureBuffer getframe $i
	# 		set sortsamac [lrange $bufferdata 6 11]
	# 		if {$dbgprt_value == 1 && $i <= 10} {puts "@@ samac: $sortsamac"}
	# 		set re [string first "$sortsamac" "$srcmac_value"]
	# 		if {[string first "$sortsamac" "$srcmac_value"] < 0} {
	# 			continue
	# 		}
	# 	}
		
	# 	if {[info exist tpid_value]} {
	# 		captureBuffer getframe $i
	# 		set sortethernettype [lrange $bufferdata 12 13]
	# 		set numEthernetType [string replace $sortethernettype 2 2]
	# 		if {$dbgprt_value == 1 && $i <= 10} {puts "@@ ethernettype: $sortethernettype"}
	# 		if {"$numEthernetType" != "$tpid_value"} {
	# 			continue
	# 		}
	# 	}
	# 	incr j
	# 	#if {$j == $paraNum} {
	# 	#	set gotFrameData $bufferdata
	# 	#	puts "return from if paramNum is $paraNum"
	# 	#	break
	# 	#}
	# 	if {$i == 100} {
	# 		set gotFrameData $bufferdata
	# 		set failStr 1
	# 		#printlog -fileid $tcLogId -res fail -cmd "stop_capture, can't get right captured frame within first 100 farmes"
	# 		break
	# 	}
	# }
	# puts "get $j packets filtered"
	# if {[info exist framedata_value]} {
	# 	eval [subst {uplevel 1 {set $framedata_value "$gotFrameData"}}]
	# }
	
	# set logStr "stop_capture $args"
	# if {[string length $gotFrameData] < 1} {
	# 	#printlog -fileid $tcLogId -res fail -cmd $logStr -comment $gotFrameData
	# } else {
	# 	if {[info exist failStr]} {
	# 		#printlog -fileid $tcLogId -res fail -cmd $logStr -comment $gotFrameData
	# 	} else {
	# 		#printlog -fileid $tcLogId -res pass -cmd $logStr -comment $gotFrameData
	# 	}
	# }
}

# -framedata                (the packets that you captured)
# -tpid                     (the filter tpid value)
# -vlanid                   (the filter vlan id)
# -priority
# -innertpid
# -innervlanid
# -innerpriority
# check_frame -framedata $frameData -tpid 8100 -vlanid 100 -priority 2
# Function: check the packets in -framedata
proc check_frame {args} {
	global tcLogId
	#1. get command and handle/parameters
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
		if {[string first tpid $item1] >=0} {incr paraNum}
		if {[string first vlanid $item1] >=0} {incr paraNum}
		if {[string first priority $item1] >=0} {incr paraNum}
		if {[string first innertpid $item1] >=0} {incr paraNum}
		if {[string first innervlanid $item1] >=0} {incr paraNum}
		if {[string first innerpriority $item1] >=0} {incr paraNum}
	}
	
	set resNum 0
	
	#2. get the parameters value of frame data
	if {[info exist framedata_value]} {
		if {$dbgprt_value == 1} {puts "@@ framedata: $framedata_value"}
		if {[string length $framedata_value] < 1} {
			#uWriteExp -errorinfo "check_frame: invalid framedata, framedata: $framedata_value"
		}
	} else {
		uWriteExp -errorinfo "check_frame: framedata is a mandatory parameter but missing"
	}
	
	set failedLogStr ""
	
	#3. check frame via tpid
	if {[info exist tpid_value]} {
		set gotTpid [lrange $framedata_value 12 13]
		set numGotTpid [string replace $gotTpid 2 2]
		
		if {$dbgprt_value == 1} {puts "@@ tpid: $numGotTpid"}
		if {[string equal -nocase $numGotTpid $tpid_value] == 1} {
			incr resNum
		} else {
			lappend failedLogStr "tpid: $numGotTpid,"
		}
	}
	
	#4. check frame via vlanid
	if {[info exist vlanid_value]} {
		set gotVlanid [lrange $framedata_value 14 15]
		set numGotVlanid [string range [string replace $gotVlanid 2 2] 1 3]
		set actualVlanid [format "%#u" 0x$numGotVlanid]
		if {$dbgprt_value == 1} {puts "@@ vlanid: $numGotVlanid"}
		if {$vlanid_value == $actualVlanid} {
			incr resNum
		} else {
			lappend failedLogStr "vlanid: $actualVlanid,"
		}
	}
	
	#5. check frame via priority
	if {[info exist priority_value]} {
		set gotPri [lrange $framedata_value 14 15]
		set numGotPri [string range [string replace $gotVlanid 2 2] 0 0]
		set actualPri [expr 0x$numGotPri / 2]
		if {$dbgprt_value == 1} {puts "@@ priority: $actualPri"}
		if {$priority_value == $actualPri} {
			incr resNum
		} else {
			lappend failedLogStr "priority: $actualPri"
		}
	}
	
	#6. check frame via innertpid
	if {[info exist innertpid_value]} {
		set gotTpid [lrange $framedata_value 16 17]
		set numGotTpid [string replace $gotTpid 2 2]
		if {$dbgprt_value == 1} {puts "@@ innertpid: $numGotTpid"}
		if {$numGotTpid == $innertpid_value} {
			incr resNum
		} else {
			lappend failedLogStr "innertpid: $numGotTpid,"
		}
	}
	
	#7. check frame via innervlanid
	if {[info exist innervlanid_value]} {
		set gotVlanid [lrange $framedata_value 18 19]
		set numGotVlanid [string range [string replace $gotVlanid 2 2] 1 3]
		set actualVlanid [format "%#u" 0x$numGotVlanid]
		if {$dbgprt_value == 1} {puts "@@ innervlanid: $actualVlanid"}
		if {$innervlanid_value == $actualVlanid} {
			incr resNum
		} else {
			lappend failedLogStr "innervlanid: $actualVlanid,"
		}
	}
	
	#8. check frame via innerpriority
	if {[info exist innerpriority_value]} {
		set gotPri [lrange $framedata_value 18 19]
		set numGotPri [string range [string replace $gotVlanid 2 2] 0 0]
		set actualPri [expr 0x$numGotPri / 2]
		if {$dbgprt_value == 1} {puts "@@ innerpriority: $actualPri"}
		if {$innerpriority_value == $actualPri} {
			incr resNum
		} else {
			lappend failedLogStr "innerpriority: $actualPri"
		}
	}
	
	if {$resNum == $paraNum} {
		set res pass
	} else {
		set res fail
	}

	set logStr "check_frame $args"
	#printlog -fileid $tcLogId -res $res -cmd $logStr -comment $failedLogStr
	
	
}
# -alias             (config a port, that you captured packets on it already)
# -length            (set the filter of packet length)
# -srcmac            (the scrmac in filter)
# -dstmac            (the dstmac address in filter)
# -srcip             (the scrip in filter)
# -dstip             (the dstip in filter)
# -ethertype         (the ethertype in fileter only support untagged pacekts )
# -tpid              (the tpid value in filter)
# -vlanid            (vlanid vlaue in filter)
# -priority          (vlan priority value)
# -innertpid         (the inner l2 tpid value )
# -innervlanid       (inner l2 vlanid vlaue in filter)
# -innerpriority     (inner l2 vlan priority value)
# -l3innertpid       (the inner l3 tpid value )
# -l3innervlanid     (inner l3 vlanid vlaue in filter)
# -l3innerpriority   (inner l3 vlan priority value)
# -l4innertpid       (the inner l4 tpid value )
# -l4innervlanid     (inner l4 vlanid vlaue in filter)
# -l4innerpriority   (inner l4 vlan priority value)

# -dbgprt
# check_capture -alias ixiap1 -length 64 -srcmac "00 00 00 00 00 02" -dstmac "00 00 00 00 00 01"
# with the command, you can get the counter of packets with (length 64) && (srcmac ="00 00 00 00 00 02") && (dstmac = "00 00 00 00 00 01")
# Check the captured packets on a Ixia port
# if you alias more then one ports, only the last port will be checked
proc check_capture {args} {
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
		if {[string first length $item1] >=0} {incr paraNum}
		if {[string first srcmac $item1] >=0} {incr paraNum}
		if {[string first dstmac $item1] >=0} {incr paraNum}
		if {[string first protocol $item1] >=0} {incr paraNum}
         if {[string first ethertype $item1] >=0} {incr paraNum}
	}
	global [subst $alias_value]
	after 500
	set value_list {}
	global [subst index_list_$alias_value]
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
				} else {
					exit 0
				}

				captureBuffer get $chasNum $cardNum $portNum $start $end
				set gotFrameData ""
				for {set i $start} {$i <=  $end } {incr i} {
						set index [expr $i - [expr [expr $m-1]*50]]
						captureBuffer getframe $index
						
						set bufferdata [captureBuffer cget -frame]
						############################## andy 2011-1-2 check tag level
						set tpids [list 8100 88A8 9100 9200]
						set vlanlayer 0
						set ttt [lrange $bufferdata [expr $vlanlayer * 4 +12] [expr $vlanlayer*4 +13]]

						while {[lsearch -nocase $tpids [join [lrange $bufferdata [expr $vlanlayer * 4 +12] [expr $vlanlayer*4 +13] ] ""] ] >=0} {
							incr vlanlayer
						}
						if {$dbgprt_value == 1 } {puts "This packet only contains $vlanlayer VLAN Field"}
						set uppertype [join [lrange $bufferdata [expr $vlanlayer * 4 +12] [expr $vlanlayer*4 +13]] ""]
						if {$dbgprt_value == 1 } {puts "The Ethernet Type value of this packet is $uppertype"}

						############################## andy 2014-1-4 check tag level
						#1
						if {[info exist length_value]} {
							set sortframesize [captureBuffer cget -length]
							if {$dbgprt_value == 1 && $i <= 10} {puts "@@ framesize: $sortframesize"}
							if {"$sortframesize" != "$length_value"} {
								continue
							}
						}
						#2. check whether the dstmac can match the parameter values
						if {[info exist dstmac_value]} {
							set dstmac_value [string toupper $dstmac_value]
							set sortdamac [lrange $bufferdata 0 5]
							if {$dbgprt_value == 1 && $i <= 10} {puts "@@ damac: $sortdamac"}
							if {[string first "$sortdamac" "$dstmac_value"] < 0} {
								continue
							}
						}
						#3. Check whether the srcmac can match the parameter value
						if {[info exist srcmac_value]} {
							set srcmac_value [string toupper $srcmac_value]
							set sortsamac [lrange $bufferdata 6 11]
							if {$dbgprt_value == 1 && $i <= 10} {puts "@@ samac: $sortsamac"}
							set re [string first "$sortsamac" "$srcmac_value"]
							if {[string first "$sortsamac" "$srcmac_value"] < 0} {
								continue
							}
						}
						 #3.1-miles add: check whether the ethertype is the same as filtered
                        if {[info exist ethertype_value]} {
                        set sortethernettype [lrange $bufferdata [expr $vlanlayer * 4 + 12] [expr $vlanlayer * 4 + 13]]
                        set typevalue [string toupper [concat [string range $ethertype_value 0 1] [string range $ethertype_value 2 3] ] ]
                        if {$dbgprt_value == 1 && $i <= 10} {
                         puts "@@ ethernettype: $sortethernettype "
                         puts "@@ configured ethertype is $typevalue"
                        }
                        if {"$sortethernettype" != "$typevalue"} {
                            continue
                        }
                        }
						#4. check whether the tpid is the same as filtered
						if {[info exist tpid_value]} {
							set sortethernettype [lrange $bufferdata [expr $vlanlayer * 4 + 12] [expr $vlanlayer * 4 + 13]]
							set numEthernetType [join $sortethernettype ""]
							if {$dbgprt_value == 1 && $i <= 10} {puts "@@ ethernettype: $numEthernetType tpidvalue: $tpid_value"}

							if {"$numEthernetType" != "$tpid_value"} {
								continue
							}
						}
						#5. check the vlanid whether can match the vlanid configured
						if {[info exist vlanid_value]} {
							set gotVlanid [lrange $bufferdata [expr $vlanlayer * 4 + 14] [expr $vlanlayer * 4 + 15]]
							set numGotVlanid [string range [string replace $gotVlanid 2 2] 1 3]
							set actualVlanid [format "%#u" 0x$numGotVlanid]
							if {$dbgprt_value == 1} {puts "@@ vlanid: $actualVlanid"}
							if {$vlanid_value != $actualVlanid} {
								continue
							}
						}
			
						#6. check frame via priority
						if {[info exist priority_value]} {
							set gotVlanid [lrange $bufferdata [expr $vlanlayer * 4 + 14] [expr $vlanlayer * 4 + 15]]
							set gotPri [lrange $bufferdata [expr $vlanlayer * 4 + 14] [expr $vlanlayer * 4 + 15]]
							set numGotPri [string range [string replace $gotVlanid 2 2] 0 0]
							set actualPri [expr 0x$numGotPri / 2]
							if {$dbgprt_value == 1} {puts "@@ priority: $actualPri"}
							if {$priority_value != $actualPri} {
								continue
								}
						}
			
						#7. check frame via innertpid
						if {[info exist innertpid_value] && $vlanlayer >= 2} {
							set gotTpid [lrange $bufferdata [expr $vlanlayer * 4 + 16] [expr $vlanlayer * 4 + 17]]
							set numGotTpid [string replace $gotTpid 2 2]
							if {$dbgprt_value == 1} {puts "@@ innertpid: $numGotTpid"}
							if {$numGotTpid != $innertpid_value} {
								continue
							}
						}
			
						#8. check frame via innervlanid
						if {[info exist innervlanid_value] && $vlanlayer >= 2} {
							set gotVlanid [lrange $bufferdata [expr $vlanlayer * 4 + 18] [expr $vlanlayer * 4 + 19]]
							set numGotVlanid [string range [string replace $gotVlanid 2 2] 1 3]
							set actualVlanid [format "%#u" 0x$numGotVlanid]
							if {$dbgprt_value == 1} {puts "@@ innervlanid: $actualVlanid"}
							if {$innervlanid_value != $actualVlanid} {
								continue
							}
						}
			
						#9. check frame via innerpriority
						if {[info exist innerpriority_value] && $vlanlayer >= 2} {
							set gotPri [lrange $bufferdata [expr $vlanlayer * 4 + 18] [expr $vlanlayer * 4 + 19]]
							set numGotPri [string range [string replace $gotVlanid 2 2] 0 0]
							set actualPri [expr 0x$numGotPri / 2]
							if {$dbgprt_value == 1} {puts "@@ innerpriority: $actualPri"}
							if {$innerpriority_value != $actualPri} {
							continue
								}
						}
						#10. andy  check frame via level 3 innertpid
						if {[info exist l3innertpid_value] && $vlanlayer >=3} {
							set gotTpid [lrange $bufferdata [expr $vlanlayer * 4 + 20] [expr $vlanlayer * 4 + 21]]
							set numGotTpid [string replace $gotTpid 2 2]
							if {$dbgprt_value == 1} {puts "@@ level 3 VLAN innertpid: $numGotTpid"}
							if {$numGotTpid != $l3innertpid_value} {
								continue
							}
						}
						#11. andy check vlan level 3 inner vlan id
						if {[info exist l3innervlanid_value] && $vlanlayer >= 3} {
							set gotVlanid [lrange $bufferdata [expr $vlanlayer * 4 + 22] [expr $vlanlayer * 4 + 23]]
							set numGotVlanid [string range [string replace $gotVlanid 2 2] 1 3]
							set actualVlanid [format "%#u" 0x$numGotVlanid]
							if {$dbgprt_value == 1} {puts "@@ level 3 VLAN innervlanid: $actualVlanid"}
							if {$l3innervlanid_value != $actualVlanid} {
								continue
							}
						}
						#12 andy l3 vlan priority check
						if {[info exist l3innerpriority_value] && $vlanlayer >=3} {
							set gotPri [lrange $bufferdata [expr $vlanlayer * 4 + 22] [expr $vlanlayer * 4 + 23]]
							set numGotPri [string range [string replace $gotVlanid 2 2] 0 0]
							set actualPri [expr 0x$numGotPri / 2]
							if {$dbgprt_value == 1} {puts "@@ inner level 3 Vlan priority: $actualPri"}
							if {$innerpriority_value != $actualPri} {
							continue
								}
						}
						#13. andy  check frame via level 4 innertpid
						if {[info exist l4innertpid_value] && $vlanlayer >=4 } {
							set gotTpid [lrange $bufferdata [expr $vlanlayer * 4 + 24] [expr $vlanlayer * 4 + 25]]
							set numGotTpid [string replace $gotTpid 2 2]
							if {$dbgprt_value == 1} {puts "@@ level 4 VLAN innertpid: $numGotTpid"}
							if {$numGotTpid != $l3innertpid_value} {
								continue
							}
						}
						#14. andy check vlan level 4 inner vlan id
						if {[info exist l4innervlanid_value] && $vlanlayer >= 4} {
							set gotVlanid [lrange $bufferdata [expr $vlanlayer * 4 + 26] [expr $vlanlayer * 4 + 27]]
							set numGotVlanid [string range [string replace $gotVlanid 2 2] 1 3]
							set actualVlanid [format "%#u" 0x$numGotVlanid]
							if {$dbgprt_value == 1} {puts "@@ level 4 VLAN innervlanid: $actualVlanid"}
							if {$l3innervlanid_value != $actualVlanid} {
								continue
							}
						}
						#15 andy l4 vlan priority check
						if {[info exist l4innerpriority_value] && $vlanlayer >=4 } {
							set gotPri [lrange $bufferdata [expr $vlanlayer * 4 + 26] [expr $vlanlayer * 4 + 27]]
							set numGotPri [string range [string replace $gotVlanid 2 2] 0 0]
							set actualPri [expr 0x$numGotPri / 2]
							if {$dbgprt_value == 1} {puts "@@ inner level 4 Vlan priority: $actualPri"}
							if {$innerpriority_value != $actualPri} {
							continue
								}
						}
						#16 andy src ip address check
						if {[info exist srcip_value] && $uppertype == "0800"} {
							set iphead [lindex $bufferdata [expr $vlanlayer * 4 +14]]
							set ipversion [string index $iphead 0]
							if { $ipversion == 6 } {
								puts stderr "TODO: ipV6 IP packets analysis is not developed yes!! "
							}
							set iphead_len [expr [string index $iphead 1]* 4]
							# the srcip is in iphead
							set srcip_hx [lrange $bufferdata [expr $vlanlayer * 4 +14 + $iphead_len - 8] [expr $vlanlayer * 4 +14 + $iphead_len - 5] ]
							set ip_hex ""
							foreach ipbyte $srcip_hx {
								lappend ip_hex [scan $ipbyte %x]
							}
							set srcip [join $ip_hex "."]
							if {$dbgprt_value == 1} {puts "@@ the catuall src ip is : $srcip"}

							if {$srcip_value != $srcip} {
							continue
							}
						}
						#17 andy dst ip address check
						if {[info exist dstip_value] && $uppertype == "0800"} {
							set iphead [lindex $bufferdata [expr $vlanlayer * 4 +14]]
							set ipversion [string index $iphead 0]
							if { $ipversion == 6 } {
								puts stderr "TODO: ipV6 IP packets analysis is not developed yes!! "
							}
							set iphead_len [expr [string index $iphead 1]* 4]
							# the srcip is in iphead
							set dstip_hx [lrange $bufferdata [expr $vlanlayer * 4 +14 + $iphead_len - 4] [expr $vlanlayer * 4 +14 + $iphead_len - 1] ]
							set ip_hex ""
							foreach ipbyte $dstip_hx {
								lappend ip_hex [scan $ipbyte %x]
							}
							set dstip [join $ip_hex "."]
							if {$dbgprt_value == 1} {puts "@@ the catuall dst ip is : $dstip"}

							if {$dstip_value != $dstip} {
							continue
							}
						}
					incr j
					lappend value_list $i
				}	
		} 
	}
		
		set [subst ::[subst index_list_$alias_value]] $value_list
		if {$dbgprt_value == 1} {puts "@@ Got: $j packets filtered in captureBuffer"}
		return $j
}
# -alias   (select the ports you want to clear ownership)
# clear_ownership -alias allport
# Function: clear ownership on port/ports
proc clear_ownership {args} {
	global tcLogId
	set aftertime 2000
	#1.1. get command and handle/parameters
	set dbgprt_value 0
	
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}
	
	#1.2. set all of the parameters value
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"}
	} else {
		uWriteExp -errorinfo "clear_ownership: alias is a mandatory parameter but missing"
	}
	
	global [subst $alias_value]
	ixClearOwnership [subst $$alias_value]
	set logStr "clear_ownership $args"
	#printlog -fileid $tcLogId -res conf -cmd $logStr
	
}


#Function: return the specific packet's specific segment
#return_segment -alias allport  -return_type timestamp
#jerry add 
proc return_segment {args} {
	set dbgprt_value 0
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
	foreach item1 $handlelist item2 $paralist {
		set $item1\_value $item2
	}

	#1. set all of the parameter value 
	if {[info exist alias_value]} {
		global [subst $alias_value]
		if {$dbgprt_value == 1} {puts "@@ alias: [subst $$alias_value]"} 
	} else {
		uWriteExp -errorinfo "return_segment: alias is a mandatory parameter but missing"
	}

	foreach port [subst $$alias_value] {
		if {[info exist return_type_value]} {
			###########################################
			#only add the timestamp segment,user can add the segment by himself
			switch -- $return_type_value {
					"timestamp" {set packet_segment timestamp}		
				}
			scan $port "%d %d %d" chasNum cardNum portNum
			capture get $chasNum $cardNum $portNum
			set comm [subst ::[subst index_list_$alias_value]]
			#???????????????????????????????????????????????????????
			set number_packets [llength [subst $$comm]]
			for {set i 1} {$i <= $number_packets} {incr i} {
				set index_packet [lindex [subst $$comm] [expr $i - 1]]
				captureBuffer get $chasNum $cardNum $portNum $index_packet $index_packet
				captureBuffer getframe 1

				lappend return_value [captureBuffer cget -$packet_segment]

			}

		} else {
			uWriteExp -errorinfo "return_segment: return_type is a mandatory parameter but missing"
		}
		
		

	}
	return $return_value
}


#import_package -alias ixiap1 -path pathname
proc import_package {args} {
	foreach {handle para} $args {
		if {[regexp {^-(.*)$} $handle all handleval]} {
			lappend handlelist $handleval
			lappend paralist $para
		}
	}
}



