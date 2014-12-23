
################################################################################
# PPP/ATM Phase 1 test:
# This test is to test the PPP frames encapsulated over ATM using LLC Encapsulation
# as per RFC1483 "Multiprotocol encapsulation over ATM AAL-5", or the VC based
# multiplexing techinique a per RFC2364 - "PPP over AAL-5".
#
# Requirements for Phase 1 are as follows:
# 1. Support for AT-9155 SmartCard, implying 2048 sessions per SmartCard, with 
# firmware version 3.0 or later.
#
# 2. ATM PVCs supported.
#
# ASSUMPTIONS:
# 1. AT-9155C SmartCards are in Slots 1 and 3 respectively.
#
# 2. The maximum number of streams (2048) are being tested.
#
# 3. et1000.tcl has been sourced and the SmartBits is linked to PC.
#
# 4. misc.tcl is local.
#
# The steps required in establishing a PPP session and obtaining
# PPP status information is as follows:
# 1. Disconnect and remove all streams from cards.
#
# 2. Configure the line params (this script uses the default values).
#
# 3. Configure the streams setting the Encapsulation type to be either LLC PPP or
#	  VC Multiplexed PPP.
#
# 4. Configure the frame definition based on the Encapsulation type.
#
# 5. Set up the PPP configuration parameters, required to issue a Configure-Req.
#
# 6. Set up the PPP control parameters, used to enable, disable open and close
#    a PPP session.  It is also used to turn on and off the LCP echo requests.
#    NOTE:  In the case where PPP is running over AAL5, we use this to only
# 				do the latter (i.e. Enabling and disabling the echo requests.
#
# 7. Connect.  This will establish a PPP session.
#
# 8. Check the connection status to make sure that the streams are connected.
#
# 9. Check the PPP Status to make sure that the PPP session(s) are up.
#
# 10. Transmit for 10 seconds.
#
# 11. Obtain the VCC Frame counts.  This will include the PPP Management frames
# 	   as well.
#
################################################################################

#########################################
if  {$tcl_platform(platform) == "windows"} {
   set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
   set libPath "../../../../include/et1000.tcl"
}

if { ! [info exists __ET1000_TCL__] } {
   if {[file exists $libPath]} {
      source $libPath
   } else {
      puts "et1000.tcl is not loaded and could not be located at $libPath"
      gets stdin response
      exit
   }
}  

if {[ETGetLinkStatus] < 0} {
     puts "SmartBits not linked - Enter chassis IP address"
     gets stdin ipaddr
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]
     if { $retval < 0 } {
      puts "Unable to connect to $ipaddr. Please try again."
      exit
     }
}
#######################################


# Tx card in slot 1...
set iHub 0
set iSlot 0
set iPort 0

# Rx card in slot 3
set iHub2 0
set iSlot2 2
set iPort2 0


set FRAME_LENGTH 40
set MAX_PPP_SESSION_RETRIEVAL 30
set TX_SECONDS	10
set Count 0
set EncapType 0
set NumberOfPPPSessions 10


# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

###########################################################
# Open Files to store the log and the results
# File names are ppp.log  and ppp.txt
###########################################################

set logFile [open "ppp.log" w]
set outFile [open "ppp.txt" w]
puts $logFile "          *************** PPP TEST LOG ****************   "

puts $outFile "          *************** PPP TEST RESULTS ****************   "

######################################################################
# Link to SmartBits 2000 chassis
######################################################################
puts " "
GetVersions

#######################################################################
#
# ATMCardCapabilities structure retrieves the capabilities of a particular
# card type.
#######################################################################

struct_new CardCapabilities ATMCardCapabilities

set iRsp [LIBCMD HTGetStructure $ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in retrieving Card Capabilities"
}


#######################################################################
# ATMStreamControl is used to connect, disconnect
# start, stop, and reset streams.
#######################################################################

struct_new StreamControl ATMStreamControl

#Deletes all streams(connections)
set StreamControl(ucAction) [format %c $ATM_STR_ACTION_RESET]
set StreamControl(ulStreamIndex) 0
set StreamControl(ulStreamCount) $CardCapabilities(uiMaxStream)
set iRsp [LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 StreamControl 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in resetting Streams on Slot#: $iSlot"
}

set iRsp [LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 StreamControl 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts $logFile "Problem in resetting Streams on Slot#: $iSlot2"
}


#######################################################################
#
# ATMLineParams structure sets up the line parameters...
#
#  Line parameters are card dependent. The settings below are for an AT-9155
#  SmartCard. For more information about which paramaters work with a given
#  card, see comments in the SmartLib Message Function manual for the relevant
#  commands.
#######################################################################
struct_new LineParams ATMLineParams

puts "\nSetting ATM line parameters..."
set LineParams(ucFramingMode) [format %c $ATM_OC3_FRAMING]
set LineParams(ucTxClockSource) [format %c $ATM_INTERNAL_CLOCK]
set LineParams(ucCellScrambling) [format %c $TRUE]
set LineParams(ucHecCoset) [format %c $TRUE]
set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS]
set LineParams(ucLoopbackEnable) [format %c $ATM_LOOPBACK_DISABLED]

for {set i 0} {$i < 4} {incr i} {
	set LineParams(ucIdleCellHeader.$i.uc) [format %c 0]
}

set iRsp [LIBCMD HTSetStructure $ATM_LINE 0 0 0 LineParams 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {	
	puts $logFile "Problem in setting Line params on Slot#: $iSlot"
}

set iRsp [LIBCMD HTSetStructure $ATM_LINE 0 0 0 LineParams 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts $logFile "Problem in setting Line params on Slot#: $iSlot2"
}

unset LineParams

#######################################################################
# Create New Streams with $ATM_STREAM
#
# This defines HOW the traffic is going to be transmitted. This information
# affects frame, but does not specify frame contents.
#
# This example prints out the stream number,
# the cell header, and the PeakCellRate of each stream.
#
# The peak cell rate for each connection is calculated by
# dividing the max cell rate of the port by the number of streams.
#######################################################################

puts "\nSetting up Streams..."
struct_new Stream ATMStream

set Stream(uiIndex) 0
set Stream(ucConnType) [ format %c $ATM_PVC ]
set Stream(ucEncapType) [ format %c $STR_ENCAP_TYPE_VC_MULTIPLEXED_PPP ]
set EncapType $Stream(ucEncapType)

set Stream(ucGenRateClass) [ format %c $STR_RATE_CLASS_UBR ]
set Stream(ulGenPCR) [expr $CardCapabilities(ulLineCellRate) / $NumberOfPPPSessions]
set Stream(ulCellHeader) 0x00000200
puts -nonewline "Creating stream $Stream(uiIndex) - Cell Header [format "%08X" $Stream(ulCellHeader)]"
puts " - PCR $Stream(ulGenPCR) cells/sec"

set iRsp [LIBCMD HTSetStructure $ATM_STREAM 0 0 0 Stream 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in setting Streams on Slot#: $iSlot"
}

set iRsp [LIBCMD HTSetStructure $ATM_STREAM 0 0 0 Stream 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts $logFile "Problem in setting Streams on Slot#: $iSlot2"
}


unset Stream


#######################################################################
# Create Addtional streams with $ATM_STREAM_PARAMS_COPY
#
# This defines how many additional streams to create based
# on a stream that has already been created.
#
#######################################################################

puts "\nCreating additional streams..."
struct_new StreamCopy ATMStreamParamsCopy


set StreamCopy(uiSrcStrNum) 0
set StreamCopy(uiDstStrNum) 1
set StreamCopy(uiDstStrCount) [expr $NumberOfPPPSessions - 1]

set iRsp [LIBCMD HTSetStructure $ATM_STREAM_PARAMS_COPY 0 0 0 StreamCopy 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in copying Streams on Slot#: $iSlot"
}


set iRsp [LIBCMD HTSetStructure $ATM_STREAM_PARAMS_COPY 0 0 0 StreamCopy 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts $logFile "Problem in copying Streams on Slot#: $iSlot2"
}


unset StreamCopy


#######################################################################
# Modify the Cell Header parameter by incrementing the VCI infomation
# portion of the Cell header.   Message type: ATM_STREAM_PARAMS_FILL
#
# This will be applicable to all the new streams created above using the
# ATM_STREAM_PARAMS_COPY command.
#
#######################################################################

puts "\nIncrementing the Cell Header..."
struct_new StreamFill ATMStreamParamsFill

set StreamFill(uiSrcStrNum) 0
set StreamFill(uiDstStrNum) 1
set StreamFill(uiDstStrCount) [expr $NumberOfPPPSessions - 1]
set StreamFill(uiParamItemID) $ATM_STR_PARAM_CELL_HEADER


for {set i 0} {$i < 4} {incr i} {
	if {$i == 3} {
		set StreamFill(ucDelta.$i.uc) [format %c 0x10]
	} else {
		set StreamFill(ucDelta.$i.uc) [format %c 0x00]
	}
}


set iRsp [LIBCMD HTSetStructure $ATM_STREAM_PARAMS_FILL 0 0 0 StreamFill 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in modifying Cell Header on Slot#: $iSlot"
}

set iRsp [LIBCMD HTSetStructure $ATM_STREAM_PARAMS_FILL 0 0 0 StreamFill 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts $logFile "Problem in modifying Cell Header on Slot#: $iSlot2"
}


unset StreamFill


################################################################################
# Procedure is calculate the IP Checksum
################################################################################
proc CalcIPCheckSum {start} {

global Frame
set sum 0

	for {set i 0} {$i < [expr $start + 10]} {incr i} {
		if {$i != [expr $start + 5]} {
			set a [ConvertCtoI $Frame(ucFrameData.[expr $start + (2*$i)].uc)]
			set b [ConvertCtoI $Frame(ucFrameData.[expr $start + ((2*$i)+1)].uc)]
			set a [expr $a << 8]
			set a [expr $a | $b]

			set sum [expr $sum + $a]
		}
	}

	set sum [expr ~$sum]
	set a [expr $sum % 256]
	set  Frame(ucFrameData.[expr $start + 11].uc) [format %c $a]

	set sum [expr $sum >> 8]
	set a [expr $sum % 256]
	set  Frame(ucFrameData.[expr $start + 10].uc) [format %c $a]

}


#######################################################################
# Define a stream with $ATM_FRAME_DEF
#
# Associate a data frame with each stream.  The AAL-5 payload contains
# the appropriate PPP encapsulation header information followed by the
# IP Header.  The checksum is then calculated.
# The IP payload is filled with 0's.
#######################################################################

puts "\nDefining frame..."
struct_new Frame ATMFrameDefinition

set Frame(uiFrameFillPattern) 0
set Frame(ulFrameFlags) 0


for {set i 0} {$i < $Frame(uiDataLength)} {incr i} {
	set Frame(ucFrameData.$i.uc) \0
}


if {$EncapType == [format %c $STR_ENCAP_TYPE_LLC_PPP]} {
	set offset 4
	set Frame(ucFrameData.0.uc) [format %c 0xFE]			;# DSAP
	set Frame(ucFrameData.1.uc) [format %c 0xFE]			;# SSAP
	set Frame(ucFrameData.2.uc) [format %c 0x03]			;# Ctrl
	set Frame(ucFrameData.3.uc) [format %c 0xCF]			;# OUI

} elseif  {$EncapType == [format %c $STR_ENCAP_TYPE_VC_MULTIPLEXED_PPP]} {
	set offset 0
} else {
	puts "ERROR>>>> Invalid PPP Encapsulation type"
}

set Frame(uiFrameLength) [expr ($FRAME_LENGTH + 2 + $offset)]
set Frame(uiDataLength) [expr (22 + $offset)]

set Frame(ucFrameData.[expr $offset+0].uc) [format %c 0x00]		;# OUI
set Frame(ucFrameData.[expr $offset+1].uc) [format %c 0x21]		;# OUI
set Frame(ucFrameData.[expr $offset+2].uc) [format %c 0x45]		;# ver / len
set Frame(ucFrameData.[expr $offset+3].uc) [format %c 0x00]		;# ToS
set Frame(ucFrameData.[expr $offset+6].uc) [format %c 0x00]		;# ID
set Frame(ucFrameData.[expr $offset+7].uc) [format %c 0x00]		;# ID
set Frame(ucFrameData.[expr $offset+8].uc) [format %c 0x00]		;# flags / frag
set Frame(ucFrameData.[expr $offset+9].uc) [format %c 0x00]		;# frag
set Frame(ucFrameData.[expr $offset+10].uc) [format %c 0x40]		;# TTL
set Frame(ucFrameData.[expr $offset+11].uc) [format %c 0x04]		;# prot

#set tot field
set b $FRAME_LENGTH
set a [expr $b % 256]
set  Frame(ucFrameData.[expr $offset + 5].uc) [format %c $a]
set b [expr $b >> 8]
set a [expr $b % 256]
set  Frame(ucFrameData.[expr $offset + 4].uc) [format %c $a]


for {set i 0} {$i < 2} {incr i} {
	set byte0 0x64
	set byte1 0x64
	set byte2 0x65
	set byte3 0x00

	set Frame(ucFrameData.[expr $offset+14].uc) [format %c $byte0]
	set Frame(ucFrameData.[expr $offset+18].uc) [format %c $byte0]

	if {$i == 0} {
		set Frame(ucFrameData.[expr $offset+15].uc) [format %c $byte1]
		set Frame(ucFrameData.[expr $offset+19].uc) [format %c [expr $byte1+1]]
	} else {
		set Frame(ucFrameData.[expr $offset+15].uc) [format %c [expr $byte1+1]]
		set Frame(ucFrameData.[expr $offset+19].uc) [format %c $byte1]
	}
	for {set j 0} {$j < $NumberOfPPPSessions} {incr j} {

		set Frame(uiStreamIndex) $j

# 		Src IP Address
		set Frame(ucFrameData.[expr $offset+16].uc) [format %c $byte2]
		set Frame(ucFrameData.[expr $offset+17].uc) [format %c $byte3]

#		Dst IP Address
		set Frame(ucFrameData.[expr $offset+20].uc) [format %c $byte2]
		set Frame(ucFrameData.[expr $offset+21].uc) [format %c $byte3]

		set Frame(ucFrameData.[expr $offset+12].uc) [format %c 0x00]
		set Frame(ucFrameData.[expr $offset+13].uc) [format %c 0x00]

# 		IP checksum
		CalcIPCheckSum [expr $offset + 2]

		if {$i == 0} {
			LIBCMD HTSetStructure $ATM_FRAME_DEF 0 0 0 Frame 0 $iHub $iSlot $iPort
		} else {
			LIBCMD HTSetStructure $ATM_FRAME_DEF 0 0 0 Frame 0 $iHub2 $iSlot2 $iPort2
		}

		# Increment the last byte of the Src/Dest IP Addresses...
		incr byte3
		set byte3 [expr $byte3%256]
		if {$byte3 == 0} {
			incr byte2
			set byte2 [expr $byte2%256]
			if {$byte2 == 0} {
				incr byte1
				set byte1 [expr $byte1%256]
				if {$byte1 == 0} {
					incr byte0
				}
			}
		}
	}

}


unset Frame


##########################################################
# Set PPP Configuration Parameters at the Local End
##########################################################

puts "\nSetting PPP Configuration params at the local end..."
struct_new pppCfg PPPParamCfg


	set pppCfg(ulpppInstance) 0x00
	set pppCfg(ulpppCount) 0x00		;# Not used for PPP/ATM - use the
						;# PPP Copy, Modify, Fill commands

# 	LCP Negotiation options
	set pppCfg(uipppWeWish) $PPPO_USEPAPAUTH
	set pppCfg(uipppWeMust) $PPPO_USEPAPAUTH
	set pppCfg(uipppWeCan)  $PPPO_USEPAPAUTH

# LCP parameters
	set pppCfg(ucpppEnablePPP) [format %c 0x01]
	set pppCfg(ucpppCHAPAlgo) [format %c $PPP_CHAPMS]
	set pppCfg(uipppMRU) $PPP_CONFIGURE_MRU				;# 1500
	set pppCfg(uipppMaxFailure) $PPP_CONFIGURE_MAXFAILURE		;# 5
	set pppCfg(uipppMaxConfigure) $PPP_CONFIGURE_MAXCONFIGURE 	;# 10
	set pppCfg(uipppMaxTerminate) $PPP_CONFIGURE_MAXTERMINATE	;# 2
	set pppCfg(ulpppMagicNumber)  $PPP_CONFIGURE_MAGICNUMBER	;# 0


# Authentication
	for {set i 0} { $i < 32 } {incr i} {
		set pppCfg(ucpppOurID.$i.uc) [format %c 0x00]
	}

	for {set i 0} { $i < 32 } {incr i} {
		set pppCfg(ucpppOurPW.$i.uc) [format %c 0x00]
	}

	for {set i 0} { $i < 32 } {incr i} {
		set pppCfg(ucpppPeerID.$i.uc) [format %c 0x00]
	}

	for {set i 0} { $i < 32 } {incr i} {
		set pppCfg(ucpppPeerPW.$i.uc) [format %c 0x00]
	}

	set pppCfg(ucpppOurID.0.uc) "R"
	set pppCfg(ucpppOurID.1.uc) "o"
	set pppCfg(ucpppOurID.2.uc) "u"
	set pppCfg(ucpppOurID.3.uc) "t"
	set pppCfg(ucpppOurID.4.uc) "e"
	set pppCfg(ucpppOurID.5.uc) "r"


	set pppCfg(ucpppOurPW.0.uc) "7"
	set pppCfg(ucpppOurPW.1.uc) "2"
	set pppCfg(ucpppOurPW.2.uc) "0"
	set pppCfg(ucpppOurPW.3.uc) "0"

	set PPPCfg(ucpppPeerID.0.uc) "R"
	set PPPCfg(ucpppPeerID.1.uc) "o"
	set PPPCfg(ucpppPeerID.2.uc) "u"
	set PPPCfg(ucpppPeerID.3.uc) "t"
	set PPPCfg(ucpppPeerID.4.uc) "e"
	set PPPCfg(ucpppPeerID.5.uc) "r"


	set PPPCfg(ucpppPeerPW.0.uc) "7"
	set PPPCfg(ucpppPeerPW.1.uc) "2"
	set PPPCfg(ucpppPeerPW.2.uc) "0"
	set PPPCfg(ucpppPeerPW.3.uc) "0"


# 	IP parameters
	set pppCfg(ucpppIPEnable)  [format %c 0x01]
	set pppCfg(ucpppNegotiateIPAddr) [format %c 0x01]
	set pppCfg(uipppIPCompress) 0x00


	set pppCfg(ucpppOurIPAddr.0.uc) [format %c 0x64]
	set pppCfg(ucpppOurIPAddr.1.uc) [format %c 0x64]
	set pppCfg(ucpppOurIPAddr.2.uc) [format %c 0x65]
	set pppCfg(ucpppOurIPAddr.3.uc) [format %c 0x00]

	set pppCfg(uipppRestartTimer) 0x03
	set pppCfg(uipppRetryCount) 0x05


	set iRsp [LIBCMD HTSetStructure $PPP_SET_CONFIG 0 0 0 pppCfg 0 $iHub $iSlot $iPort]
	if {$iRsp < 0} {
		puts $logFile "Problem in setting PPP Configuration params on Slot#: $iSlot"
	}

	set pppCfg(ucpppPeerIPAddr.0.uc) [format %c 0x64]
	set pppCfg(ucpppPeerIPAddr.1.uc) [format %c 0x65]
	set pppCfg(ucpppPeerIPAddr.2.uc) [format %c 0x65]
	set pppCfg(ucpppPeerIPAddr.3.uc) [format %c 0x00]

	set iRsp [LIBCMD HTSetStructure $PPP_SET_CONFIG 0 0 0 pppCfg 0 $iHub2 $iSlot2 $iPort2]
	if {$iRsp < 0} {
		puts "Problem in setting PPP Configuration params on Slot#: $iSlot2"
	}


unset pppCfg


##########################################################
# Copying PPP Configuration Parameters (Local End)
# to remaining number of streams configured for PPP
##########################################################

	puts "\nCopying Configuration parameters to the remaining streams..."
	struct_new pppCopy PPPParamsCopy

	set pppCopy(uipppSrcStrNum) 0
	set pppCopy(uipppDstStrNum) 1
	set pppCopy(uipppDstStrCount) [expr $NumberOfPPPSessions - 1]

	set iRsp [LIBCMD HTSetStructure $PPP_PARAMS_COPY 0 0 0 pppCopy 0 $iHub $iSlot $iPort]
	if {$iRsp < 0} {
		puts $logFile "Problem in copying PPP params on Slot#: $iSlot"
	}

	set iRsp [LIBCMD HTSetStructure $PPP_PARAMS_COPY 0 0 0 pppCopy 0 $iHub2 $iSlot2 $iPort2]
	if {$iRsp < 0} {
		puts $logFile "Problem in copying PPP params on Slot#: $iSlot2"
	}
	unset pppCopy


##########################################################
# Modifying PPP Configuration Parameters (Local End)
# to remaining number of streams configured for PPP

# Modify the Local/Peer IP Addresses for each session.
# Message type: PPP_PARAMS_FILL
#
# This will be applicable to all the new ppp sessions created
# above using the PPP_PARAMS_COPY command.
##########################################################

	puts "\nChanging the IP Addresses..."
	struct_new pppFill PPPParamsFill

	set pppFill(uipppSrcStrNum) 0
	set pppFill(uipppDstStrNum) 1
	set pppFill(uipppDstStrCount) [expr $NumberOfPPPSessions - 1]
	set pppFill(uipppParamItemID) $PPP_LOCAL_IPADDR
	for {set i 0} {$i < 4} {incr i} {
		if {$i == 3} {
			set pppFill(ucpppDelta.$i.uc) [format %c 0x01]
		}
	}


	set iRsp [LIBCMD HTSetStructure $PPP_PARAMS_FILL 0 0 0 pppFill 0 $iHub $iSlot $iPort]
	if {$iRsp < 0} {
		puts $logFile "Problem in modifying PPP params on Slot#: $iSlot"
	}

	set iRsp [LIBCMD HTSetStructure $PPP_PARAMS_FILL 0 0 0 pppFill 0 $iHub2 $iSlot2 $iPort2]
	if {$iRsp < 0} {
		puts $logFile "Problem in modifying PPP params on Slot#: $iSlot2"
	}


	unset pppFill




########################################################
# Set PPP Echo Request Information
########################################################

puts "\nSetting up the Echo Control Information..."
struct_new pppCtl PPPControlCfg

set pppCtl(ulpppInstance) 0				;# Starting stream index
set pppCtl(ulpppCount) $NumberOfPPPSessions
set pppCtl(ucpppAction) [format %c $PPP_ECHO_START]
set pppCtl(ulpppEchoFreq) 0x10
set pppCtl(ulpppEchoErrFreq) 0x00

set iRsp [LIBCMD HTSetStructure $PPP_SET_CTRL 0 0 0 pppCtl 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in setting Control Information params on Slot#: $iSlot"
}

set iRsp [LIBCMD HTSetStructure $PPP_SET_CTRL 0 0 0 pppCtl 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts $logFile "Problem in setting Control Information params on Slot#: $iSlot2"
}


unset pppCtl

#######################################################################
# Connect Streams
#
# Similar to other ATM_STREAM_CONTROL functions
# Change ucAction to whatever action is needed and
# call HTSetSTructure with $ATM_STREAM_CONTROL to send to card.
#######################################################################

puts "\nConnecting $NumberOfPPPSessions Stream(s)..."

set StreamControl(ucAction) [format %c $ATM_STR_ACTION_CONNECT]
set StreamControl(ulStreamIndex) 0
set StreamControl(ulStreamCount) $NumberOfPPPSessions

set iRsp [LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 StreamControl 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in connecting streams on Slot#: $iSlot"
}

set iRsp [LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 StreamControl 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts $logFile "Problem in connection streams on Slot#: $iSlot2"
}


#############################################################
# Check Connection Status
#
#############################################################
struct_new StreamInfo ATMStreamDetailedInfo

puts "\nChecking Stream Detailed Info..."

# Wait for some time before checking the status
after 10000

set iRsp [LIBCMD HTGetStructure $ATM_STREAM_DETAIL_INFO 0 $NumberOfPPPSessions 0 StreamInfo 0 $iHub $iSlot $iPort]
if {$iRsp < 0} {
	puts $logFile "Problem in getting Stream Detailed information on Slot#: $iSlot"
}



set iRsp [LIBCMD HTGetStructure $ATM_STREAM_DETAIL_INFO 0 $NumberOfPPPSessions 0 StreamInfo 0 $iHub2 $iSlot2 $iPort2]
if {$iRsp < 0} {
	puts "Problem in getting Stream Detailed information on Slot#: $iSlot2"
}



unset StreamInfo


#############################################################
# Retrieve PPP status information
#############################################################

struct_new PPPInfo PPPStatusInfo*$NumberOfPPPSessions

	set iRsp [LIBCMD HTGetStructure $PPP_STATUS_INFO 0 $NumberOfPPPSessions 0 PPPInfo 0 $iHub $iSlot $iPort]
	if {$iRsp < 0} {
		puts "iRsp from HTGetStructure: $iRsp"
	}

	puts $outFile "PPP Index,LCP state,IPCP state,IPXCP state,Failure Code,Magic Number,Our IP Address,Peer IP Address,Requested options,Acked options,MRU,MTU"
	puts  $outFile ""
	puts $outFile "PPP Status info for Card#: [expr $iSlot + 1]"
	for {set j 0} {$j < $NumberOfPPPSessions} {incr j} {
		set dLatency dU64ToDouble($PPPInfo($j.ullpppLatency))
		puts  $outFile "$PPPInfo($j.ulpppInstance), [ConvertCtoI $PPPInfo($j.ucppplcpState)], \
					[ConvertCtoI $PPPInfo($j.ucpppipcpState)], [ConvertCtoI $PPPInfo($j.ucpppipxcpState)], \
					[ConvertCtoI $PPPInfo($j.ucppplcpFailCode)], [format %08x $PPPInfo($j.ulpppMagicNumber)], \
					[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.0.uc)].[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.1.uc)].[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.2.uc)].[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.3.uc)], \
					[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.0.uc)].[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.1.uc)].[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.2.uc)].[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.3.uc)], \
					$PPPInfo($j.ulpppWeGot), $PPPInfo($j.ulpppWeAcked), \
					$PPPInfo($j.uipppMRU), $PPPInfo($j.uipppMTU), \
					$PPPInfo($j.ullpppLatency)"

		}

	set iRsp [LIBCMD HTGetStructure $PPP_STATUS_INFO 0 $NumberOfPPPSessions 0 PPPInfo 0 $iHub2 $iSlot2 $iPort2]
	if {$iRsp < 0} {
		puts "iRsp from HTGetStructure: $iRsp"
	}

	puts  $outFile ""
	puts $outFile "PPP Status info for Card#: [expr $iSlot2 + 1]"
	for {set j 0} {$j < $NumberOfPPPSessions} {incr j} {
		set dLatency dU64ToDouble($PPPInfo($j.ullpppLatency))
		puts  $outFile "$PPPInfo($j.ulpppInstance), [ConvertCtoI $PPPInfo($j.ucppplcpState)], \
					[ConvertCtoI $PPPInfo($j.ucpppipcpState)], [ConvertCtoI $PPPInfo($j.ucpppipxcpState)], \
					[ConvertCtoI $PPPInfo($j.ucppplcpFailCode)], [format %08x $PPPInfo($j.ulpppMagicNumber)], \
					[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.0.uc)].[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.1.uc)].[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.2.uc)].[ConvertCtoI $PPPInfo($j.ucpppOurIPAddr.3.uc)], \
					[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.0.uc)].[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.1.uc)].[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.2.uc)].[ConvertCtoI $PPPInfo($j.ucpppPeerIPAddr.3.uc)], \
					$PPPInfo($j.ulpppWeGot), $PPPInfo($j.ulpppWeAcked), \
					$PPPInfo($j.uipppMRU), $PPPInfo($j.uipppMTU), \
					$PPPInfo($j.ullpppLatency)"

		}


unset PPPInfo


#######################################################################
# Start Transmitting
#######################################################################

LIBCMD HGClearGroup

LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

LIBCMD HGClearPort
puts ""

puts "Transmitting for $TX_SECONDS seconds..."
LIBCMD HGStart


# PAUSE for TX_SECONDS delay (multiply times 1000 to convert mS to seconds
after [expr $TX_SECONDS * 1000]

LIBCMD HGStop


#######################################################################
#######################################################################
#########  GET STATS
#######################################################################
#######################################################################

struct_new VCCInfo ATMVCCInfo

puts ""

for {set i 0} {$i < 2} {incr i} {
	puts $outFile ""
	puts $outFile "Results for Card in Card# [expr $i +1]"
	puts $outFile "=================================="
	if {$i == 0} {
		LIBCMD HTGetStructure $ATM_STREAM_VCC_INFO 0 $NumberOfPPPSessions 0 VCCInfo 0 $iHub $iSlot $iPort
	} else {
		LIBCMD HTGetStructure $ATM_STREAM_VCC_INFO 0 $NumberOfPPPSessions 0 VCCInfo 0 $iHub2 $iSlot2 $iPort2
	}

	for {set j 0} {$j < $NumberOfPPPSessions} {incr j} {
		puts $outFile [format "%4d,%08X,%10d,%10d" [expr ($j + 1)] $VCCInfo(status.$j.ulCellHeader) $VCCInfo(status.$j.ulTxFrame) $VCCInfo(status.$j.ulRxFrame)]
	}
	puts $outFile ""
}

#######################################################################
# Free Resources
#######################################################################
unset VCCInfo
unset StreamControl
unset CardCapabilities
close $outFile
close $logFile

puts ""
puts "Test Done"

#UnLink from the chassis
LIBCMD NSUnLink
