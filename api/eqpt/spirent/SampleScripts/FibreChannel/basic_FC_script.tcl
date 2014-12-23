#####################################################################################
# NAME
#	BasicFCScript.tcl
# DESCRIPTION                                                                 
#	This Script uses the FBC 3601A/3602B module of SmartBits to setup a number of 
#	streams and transmit them.  It is required of the Script to be Linked Up,
#	Logged In and have Discovered the other devices before reaching the Commit state
# 	to transmit traffic.
# USAGE
#	This script is to be used with the latest released FW and 3.14ver Library or higher
#
# AUTHOR/REVISION HISTORY                                                     
#	PJ Yedidsion					-Created			(Tab set to 3 spaces)
#
#####################################################################################


########################
#	Procedures Section  #
########################

###########################################################
# procNAME
#	PortConfig
# DESCRIPTION
#	Configure Fibre Channel Port Parameters
###########################################################
proc PortConfig {H S P} {

struct_new	fc_port	FCPortConfig

	# use the global parameters and configure the ports
   set fc_port(ucSpeed) 				$::speed  
   set fc_port(ucTopology)  			$::topology
   set fc_port(uiBBCreditConfigRx) 	$::bbCredit

	LIBCMD  HTSetStructure $::FC_PORT_CONFIG 0 0 0 fc_port 0 $H $S $P
}

###########################################################
# procNAME
#	DefineStream
# DESCRIPTION
#	Configure WWN and Define Fibre Channel Streams
# PARAMETERS
#	Source and Destination WWNs
###########################################################
proc Stream {H S P SWWN DWWN} {
    # two WWN wndpoints for each stream
    struct_new		wwnConfig		FCWWN*[expr $::numStreams * 2]
    struct_new 	stream 			StreamFC*$::numStreams
    
    # Loop through and populate arrays for stream, FC header and WWN endpoints
    for {set i 0} {$i < $::numStreams} {incr i} {
			#puts -nonewline "\nConfig stream [expr $i+1] on $H $S $P ... " 
			set stream($i.uiFrameLength)  $::frameLength
			set stream($i.ucActive)       1
			set stream($i.ucProtocolType) $::STREAM_PROTOCOL_FC
			set stream($i.ucTagField)     1
			set stream($i.ucRandomData)   1
			set stream($i.u64SourceWWN.high)    [expr $SWWN / 0x010000]        
			set stream($i.u64SourceWWN.low)     [expr $SWWN & 0x0FFFF]
			set stream($i.u64DestWWN.high)      [expr $DWWN / 0x010000] 
			set stream($i.u64DestWWN.low)       [expr $DWWN & 0x0FFFF] 
			set stream($i.ucCOS)				$::FC_STREAM_COS_3
			set stream($i.ucR_CTL)         0
			set stream($i.ulF_CTL)         0
			set stream($i.uiCS_CTL)        0
			set stream($i.ucDF_CTL)        0
			set stream($i.ucEnableSeqCnt)  1
			set stream($i.ucDuplexMode)    $::FULLDUPLEX_MODE
			set stream($i.ucVerifyAL_PD)   1
			set stream($i.ucVerifyAL_PS)   1
			set stream($i.ulSOF)           0
			set stream($i.ucFCType)        0
			set stream($i.uiSeqCnt)        0
			set stream($i.uiOX_ID)         0
			set stream($i.uiRX_ID)         0
			set stream($i.ulParameter)     0
			set stream($i.ulEOF)           0
			set stream($i.ucSeqID)         1 
			set stream($i.uiPayLoadLength) 28
			set stream($i.ProtocolHeader._char_)	"PayLoad Goes Here see John!"
			#
		    #################################################################
		    # Now set up a pair of endpoints for each stream.
		    # expr $i * 2 will give 0,2,4,6 sequence
		    # expr ($i * 2) + 1 will give 1,3,5,7 sequence
		    #################################################################
			#puts -nonewline "\nConfig 2 WWN endpoints for stream [expr $i+1] on $H $S $P ... "
			# local
			set wwnConfig([expr $i * 2].u64WWN.high)      [expr $SWWN / 0x10000]
			set wwnConfig([expr $i * 2].u64WWN.low)       [expr $SWWN & 0x0FFFF]
			set wwnConfig([expr $i * 2].ucRemote)         $::LOCAL_MODE
			set wwnConfig([expr $i * 2].ucSupportedCOS)   1
			set wwnConfig([expr $i * 2].ucPublic)         $::connMode
			# remote
			set wwnConfig([expr ($i * 2) + 1].u64WWN.high)      [expr $DWWN / 0x10000]
			set wwnConfig([expr ($i * 2) + 1].u64WWN.low)       [expr $DWWN & 0x0FFFF]
			set wwnConfig([expr ($i * 2) + 1].ucRemote)         $::REMOTE_MODE
			set wwnConfig([expr ($i * 2) + 1].ucSupportedCOS)   1
			set wwnConfig([expr ($i * 2) + 1].ucPublic)         $::connMode  
			# increment the WWNs
			incr SWWN
			incr DWWN                         

    }

	# make the call to define the steams
	LIBCMD HTSetStructure $::FC_WWN 0 0 0 wwnConfig  0 $H $S $P
	LIBCMD HTSetStructure $::FC_DEFINE_STREAM 0 $::numStreams 0 stream 0 $H $S $P
}

###########################################################
# procNAME
#	LinkUp
# DESCRIPTION
#	Link up the ports
###########################################################
proc LinkUp {H S P} {

	# Send LinkUp command
	LIBCMD HTSetCommand $::FC_LINKUP 0 0 0 "" $H $S $P

}

###########################################################
# procNAME
#	Login
# DESCRIPTION
#	Login the ports
###########################################################
proc Login {H S P} {

	# Send Login command
	LIBCMD HTSetCommand $::FC_WWN_LOGIN 0 0 0 "" $H $S $P

}

###########################################################
# procNAME
#	PublicDisc
# DESCRIPTION
#	Do a public discovery to the switch to find out about
#	other ports that are logged in
###########################################################
proc PublicDisc {H S P} {
    		
	# Send Discovery command
	LIBCMD HTSetCommand $::FC_PUBLIC_DISCOVERY  0 0 0 "" $H $S $P

}

###########################################################
# procNAME
#	PrivateDisc
# DESCRIPTION
#	Do a private discovery to the switch to find out about
#	other ports that are logged in
###########################################################
proc PrivateDisc {H S P} {
    		
	# Send Discovery command
	LIBCMD HTSetCommand $::FC_PRIVATE_DISCOVERY  0 0 0 "" $H $S $P

}

###########################################################
# procNAME
#	Commit
# DESCRIPTION
#	Get ports to being Ready To Test
###########################################################
proc Commit {H S P} {

	# Complete the initialization and configuration process and put ports to Ready to Test
	LIBCMD  HTSetCommand $::FC_COMMIT 0 0 0 "" $H $S $P

}

###########################################################
# display current port status - will expand error info
# if error is non-zero
###########################################################
proc Status {H S P fc_status stateBit} {

	upvar $fc_status status
	
	LIBCMD  HTGetStructure $::FC_STATUS_INFO 0 0 0 status 0 $H $S $P
	# Check if State is True
	if { $stateBit & $status(ulState) } {
	   return 1
	}
	
	# see if we totally lost link (can be used later to bring ports back up)
	if { $stateBit != $::PORT_LINK_UP } {
		if { $status(ulState) & $::PORT_LINK_UP } {
		# do nothing
	   } else {
	       #puts "LINK HAS GONE DOWN!"
	       return 0
	   }
	}
	return -1
}

proc checkStatus {H S P value action waiting} {
    struct_new status FCStatus

		while {$waiting > 0} {
			set retval [Status $H $S $P status $value]
			if {$status(ulState) & $value} {
				puts "==> Port $H $S $P successfully completed $action!\n"
				return 1
			} else {
				puts "Please wait for port status updating to $action:$waiting"
				after 1000
				incr waiting -1
			}
		}
		
		##
		##	We know that as many times as we tried, the port did not get the correct state
		##	so dump the error info to the screen
		##
		#puts " RAW ulState Value 0x[format %04X $status(ulState)]"
		puts "---------------------------------------------------------------"
		puts -nonewline "Fibre Channel Port ($H,$S,$P) Status   ==>"
		if {$status(ulState) & 0x01 } {
		puts " LINK DOWN "
		} elseif {$status(ulState) & 0x02} {
		puts " LINK INITIALIZING "
		} elseif {$status(ulState) & 0x04} {
			puts " LINK UP "
			puts -nonewline "Fabric specific Status              ==> "
			if {$status(ulState) & 0x08 } {
			    puts "LOGIN"
			} elseif {$status(ulState) & 0x10 } {
			    puts "LOGIN COMPLETE"
			} elseif {$status(ulState) & 0x20 } {
			    puts "PUBLIC DISCOVERY"
			} elseif {$status(ulState) & 0x40 } {
			    puts "PUBLIC DISCOVERY COMPLETE"
			} elseif {$status(ulState) & 0x80 } {
			    puts "PRIVATE DISCOVERY"
			} elseif {$status(ulState) & 0x100 } {
			    puts "PRIVATE DISCOVERY COMPLETE"
			} elseif {$status(ulState) & 0x200 } {
			    puts "READY TO TEST"
			} else {
			    puts "NO SPECIFIC DEFINITION"
			}
		}
		#puts "ERROR CODE RAW [format %X $status(ulError)]"
		# if error is set, print out the error info
		if {$status(ulError) != 0} {
			#puts    "------------ Fibre Channel Error Info    ------------------------"
			#puts " RAW ulError Value 0x[format %04X $status(ulError)]"
			if {$status(ulError) & 0x01 } {
				puts -nonewline "LOSS OF SYNC"
			}
			if {$status(ulError) & 0x02 } {
				puts -nonewline "LOSS OF SIGNAL"
			}
			if {$status(ulError) & 0x04 } {
				puts -nonewline "LINK RESET"
			}
			if {$status(ulError) & 0x08 } {
				puts -nonewline "PORT TX FAULT"
			}
			if {$status(ulError) & 0x010 } {
				puts -nonewline "FABRIC LOGIN ERROR"
			}
			if {$status(ulError) & 0x020 } {
				puts -nonewline "PORT LOGIN ERROR"
			}
			if {$status(ulError) & 0x040 } {
				puts -nonewline "NAME SERVER ERROR"
			}
			if {$status(ulError) & 0x080 } {
				puts -nonewline "INVALID STATE ERROR"
			}
			# Extended error reason
			switch $status(ulErrorExtendedInfo) {
			    0 { puts -nonewline " - NO REASON CODE"}
			    1 { puts -nonewline " - INVALID LS COMMAND"}
			    2 { puts -nonewline " - LOGICAL ERROR"}
			    3 { puts -nonewline " - LOGICAL INVALID IU SIZE"}
			    4 { puts -nonewline " - LOGICAL BUSY"}
			    5 { puts -nonewline " - PROTOCOL ERROR"}
			    6 { puts -nonewline " - UNABLE TO PERFORM COMMAND"}
			    7 { puts -nonewline " - COMMAND NOT SUPPORTED"}   
			    8 { puts -nonewline " - TIMEOUT"} 
			    9 { puts -nonewline " - CLASS OF SERVICE 2 NOT SUPPORTED"} 
			    10 { puts -nonewline " - CLASS OF SERVICE 3 NOT SUPPORTED"} 
			    default { puts -nonewline " - REASON CODE $reason NOT DEFINED"} 
			}
			# Detailed error explanation
			switch $status(ulErrorDetailedInfo) {
			    0 { puts " - No additional information"}
			    1 { puts " - Service parameter options"}
			    2 { puts " - Service parameter init control"}
			    3 { puts " - Service parameter recp control"}
			    4 { puts " - Service parameter receive size"}
			    5 { puts " - Service parameter concurrent seqs"}
			    6 { puts " - Service parameter credit"}
			    7 { puts " - Invalid port name"}
			    8 { puts " - Invalid node or fabric name"}
			    9 { puts " - Invalid common service parameters"}
			    10 { puts " - Command already in progress"}
			    11 { puts " - Out of resources"}
			    12 { puts " - Port identifier not registered"}
			    13 { puts " - Port name not registered"}
			    14 { puts " - Node name not registered"}
			    15 { puts " - Class of Service not registered"}
			    16 { puts " - IP Address not registered"}
			    17 { puts " - Initial Process Association not registered"}
			    18 { puts " - Fibre Channel 4 types not registered"}
			    19 { puts " - Symbolic port name not registered"}
			    20 { puts " - Symbolic node name not registered"}
			    21 { puts " - Port type not registered"}
			    22 { puts " - Port IP address not registered"}
			    23 { puts " - Fabric port name not registered"}
			    24 { puts " - Hard address not registered"}
			    25 { puts " - Access denied"}
			    26 { puts " - Unacceptable port identifier"}
			    27 { puts " - Database empty"}
			    28 { puts " - No object registered in scope"}
			    default { puts "EXPLANATION $explanation NOT DEFINED"}
			}
		}	;# end of if print out info
	puts "---------------------------------------------------------------"
	
	set ::Result 1
	puts "** ERROR ** Port $H $S $P did not complete $action!\n\n"
	unset status
	return -1
}

#################################################################
# startCapture
#
# Start capture and wait
#################################################################
proc startCapture {H S P} {
   puts "Setting Capture"
   struct_new CapSetup NSCaptureSetup
   set CapSetup(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
   set CapSetup(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
   LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 CapSetup 0 $H $S $P
   LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 "" $H $S $P
   after 2000
}

#################################################################
# stopCapture
#
# Stop capture and display results
#################################################################
proc stopCapture {H S P {numToDisplay 5}} {
   puts "Stopping Capture"
   LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 "" $H $S $P
   
   puts "Checking Capture Count"
   struct_new CapCount NSCaptureCountInfo
   LIBCMD HTGetStructure $::NS_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $H $S $P
   puts "Capture count is $CapCount(ulCount)"
   
   if {$CapCount(ulCount) < $numToDisplay} {
   	puts "Setting the number of packets to display to $CapCount(ulCount)"
   	set numToDisplay	$$CapCount(ulCount)
   }
   
   puts "Getting Captured Packets"
   struct_new CapData NSCaptureDataInfo
   for {set i 0} {$i < $numToDisplay} {incr i} {
      puts ""
      set CapData(ulFrameIndex) $i
      LIBCMD HTGetStructure $::NS_CAPTURE_DATA_INFO $i 1 0 CapData 0 $H $S $P
      puts -nonewline "Frame index = $CapData(ulFrameIndex)"
      for {set j 0} {$j < $CapData(ulRetrievedLength)} {incr j} {
         if {[expr $j % 16] == 0} {
            puts ""
            puts -nonewline [format "%4i:   " $j]
         }
         puts -nonewline " [format "%02X" $CapData(ucData.$j)]"
      }
      puts ""
   }
   puts ""
}

proc getFCCounters {H S P} {
   struct_new cs FCCounterInfo 
   LIBCMD  HTGetStructure $::FC_COUNTER_INFO 0 0 0 cs 0 $H $S $P

   puts "======================================================="
   puts "	  Counter Data = > Card [expr $S +1]  Port [expr $P + 1]  |"
   puts "======================================================="
   puts "    	   Events (Total)    |     Rates (Per Second) |"
   puts "======================================================="
   puts "Tx Packets 	[format "%12d" $cs(ulTmtPkt)] | 		 [format "%12d" $cs(ulTmtPktRate)] |"
   puts "Rx Packets 	[format "%12d" $cs(ulRcvPkt)] | 		 [format "%12d" $cs(ulRcvPktRate)] |"
   puts "Rx Bytes 	[format "%12d" $cs(ulRcvByte)] | 		 [format "%12d" $cs(ulRcvByteRate)] |"
   puts "-------------------------------------------------------"
   puts "Recvd Trigger	[format "%12d" $cs(ulRcvTrig)] | 		 [format "%12d" $cs(ulRcvTrigRate)] |"
   puts "-------------------------------------------------------"
   puts "CRC Errors	[format "%12d" $cs(ulCRC)] | 		 [format "%12d" $cs(ulCRCRate)] |"
   puts "-------------------------------------------------------"
   puts "Oversize	[format "%12d" $cs(ulOversize)] | 		 [format "%12d" $cs(ulOversizeRate)] |"
   puts "Undersize	[format "%12d" $cs(ulUndersize)] | 		 [format "%12d" $cs(ulUndersizeRate)] |"
   puts "-------------------------------------------------------"
   puts "Press ENTER to continue"
   gets stdin response

}


#########################################################################################
#########################################################################################
#########################################################################################
############################	     MAIN PROGRAM	    #####################################
#########################################################################################
#########################################################################################
#########################################################################################
source smartlib.tcl
#source show.tcl

# status checker variable
global Result
set Result 	0
set numTrys 5	;# how many times to ask for status before giving up

# capture
set numPacketsDiplay	1 ;# could be any #

# port 1
set TxHub  0
set TxSlot 0
set TxPort 0
# port 2
set RxHub  0
set RxSlot 0
set RxPort 1

# Port configuration parameteres
set topology 	$::TOPOLOGY_PT_2_PT		;# TOPOLOGY_LOOP
set speed 		$::SPEED_1GHZ				;# SPEED_2GHZ
set bbCredit 	32

# Stream parameters
set numStreams 	1
set frameLength	124
set connMode		$::PUBLIC_MODE		;# PRIVATE_MODE

# link to the chassis here
if {[ETGetLinkStatus] < 0} {
     puts "SmartBits not linked - Enter chassis IP address"
     gets stdin ipaddr
     set retval [NSSocketLink ipaddr 16385 $RESERVE_NONE]  
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit
     }
}

# Reserve the 2 slots
LIBCMD HTSlotReserve $TxHub $TxSlot  
LIBCMD HTSlotReserve $RxHub $RxSlot 

puts "Reset Fibre Channel ports ... "
LIBCMD HTResetPort $::RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $::RESET_FULL $RxHub $RxSlot $RxPort
after 2000


# 1st configure the ports using topology speed bbCredit (defined above)
puts "Configure Fibre Channel ports ... "
PortConfig $TxHub $TxSlot $TxPort
PortConfig $RxHub $RxSlot $RxPort

# Configure the WWNs, set up the streams and create the FC header
#	Stream parameters are the Source and Dest WWNs
puts "Create streams and define WWNs ...\n"
Stream $TxHub $TxSlot $TxPort 100 200
Stream $RxHub $RxSlot $RxPort 200 100

# Go through the process of linking, logging in, discover & commit

# Link up the ports
LinkUp $TxHub $TxSlot $TxPort
LinkUp $RxHub $RxSlot $RxPort
# Check the status to make sure we got LinkUp 0x04
checkStatus $TxHub $TxSlot $TxPort $::PORT_LINK_UP "Link" $numTrys
checkStatus $RxHub $RxSlot $RxPort $::PORT_LINK_UP "Link" $numTrys

# If in public mode, do Fabric Login followed by Public Discovery
# If in private mode, do Private Discovery only
if {$connMode} {
	#puts "Login..."
	Login $TxHub $TxSlot $TxPort
	Login $RxHub $RxSlot $RxPort
	# Check the status to make sure we loged in 0x10
	checkStatus $TxHub $TxSlot $TxPort $::PORT_DEVICE_LOGIN_COMPLETE "Login" $numTrys
	checkStatus $RxHub $RxSlot $RxPort $::PORT_DEVICE_LOGIN_COMPLETE "Login" $numTrys
	
	#puts "Discovery (Public)..."
	PublicDisc $TxHub $TxSlot $TxPort
	PublicDisc $RxHub $RxSlot $RxPort
	# Check the status to make sure we discovered 0x40
	checkStatus $TxHub $TxSlot $TxPort $::PORT_PUBLIC_DISCOVERY_COMPLETE "Public Discovery" $numTrys
	checkStatus $RxHub $RxSlot $RxPort $::PORT_PUBLIC_DISCOVERY_COMPLETE "Public Discovery" $numTrys

} else {
	#puts "Discovery (Private)..."
	PrivateDisc $TxHub $TxSlot $TxPort
	PrivateDisc $RxHub $RxSlot $RxPort
	# Check the status to make sure we discovered 0x40
	checkStatus $TxHub $TxSlot $TxPort $::PORT_PRIVATE_DISCOVERY_COMPLETE "Private Discovery" $numTrys
	checkStatus $RxHub $RxSlot $RxPort $::PORT_PRIVATE_DISCOVERY_COMPLETE "Private Discovery" $numTrys

}

Commit $TxHub $TxSlot $TxPort
Commit $RxHub $RxSlot $RxPort
# Check the status to make sure we are ready to test 0x200
checkStatus $TxHub $TxSlot $TxPort $::PORT_READY_TO_TEST "Commit" $numTrys
checkStatus $RxHub $RxSlot $RxPort $::PORT_READY_TO_TEST "Commit" $numTrys


    struct_new  wwnConfigInfo		   FCWWN*2

    LIBCMD HTGetStructure $::FC_WWN_INFO 0 0 0 wwnConfigInfo 0 $TxHub $TxSlot $TxPort
    for {set i 0} {$i < 2} {incr i} {                                           
        puts "---------- WWN [expr $i + 1] -----------------------------------------"
        puts "WWN ucPublic              = $wwnConfigInfo($i.ucPublic)"
        puts "WWN ucRemote              = $wwnConfigInfo($i.ucRemote)"
        puts "WWN (high)                = [format %x $wwnConfigInfo($i.u64WWN.high)]"
        puts "WWN (low)                 = [format %x $wwnConfigInfo($i.u64WWN.low)]"
        puts "WWN Address ID            = [format %x $wwnConfigInfo($i.ulAddressID)]"
    }






after 10000


# Start the capture on our receiving port
startCapture $RxHub $RxSlot $RxPort

# Start transmitting on our transmit port
HTRun $HTRUN $TxHub $TxSlot $TxPort
after 1000
# Stop transmit
HTRun $HTSTOP $TxHub $TxSlot $TxPort

# Stop the capture and display the desired # of packets
stopCapture $RxHub $RxSlot $RxPort $numPacketsDiplay

#
getFCCounters $TxHub $TxSlot $TxPort
getFCCounters $RxHub $RxSlot $RxPort



gets stdin
puts "UnLinking from the chassis now"
LIBCMD ETUnLink
puts "DONE!"
































