# atmppp.tcl
# Sets up multiple PPP sessions on two cards then starts and
# stops the streams as a group.  Displays Tx Rx counts
# on both cards.
# 
# Creates numberofPPPSessions starting at 0/32 (0/20 hex)
# and incrementing upward on each card.
#
# Program will work with two cards connected back to
# back without a DUT.
#
# ASSUMES:
# AT-9155C ATM Cards are installed in slot 1 and slot 3.
###################################################

# If smartlib.tcl is not loaded, attempt to locate it at the default location.
# The actual location is different on different platforms. 
if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/smartlib.tcl"
} else {
         set libPath "../../../../include/smartlib.tcl"
}
# if "smartlib.tcl" is not loaded, try to source it from the default path
if { ! [info exists __SMARTLIB_TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
} else {   
               
         #Enter the location of the "smartlib.tcl" file or enter "Q" or "q" to quit
         while {1} {
         
                     puts "Could not find the file $libPath."
                     puts "Enter the path of smartlib.tcl, or q to exit." 
          
                     gets stdin libPath
                     if {$libPath == "q" || $libPath == "Q"} {
                          exit
                     } 
                     if {[file exists $libPath]} {
	                  source $libPath
                          break
                     } 
       
         } 
   }
}

# If chassis is not currently linked prompt for IP and link  
if {[ETGetLinkStatus] < 0} {
     puts "SmartBits not linked - Enter chassis IP address"
     gets stdin ipaddr
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_ALL]
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit
     }
}


#cards in slots 1...
set iHub 0
set iSlot 0
set iPort 0

#... and 3
set iHub2 0
set iSlot2 2
set iPort2 0

set firstStream 0
set numberOfPPPSessions 4
set burstSize 200

# ip addresses (passed in by function call below)
set ip1 10.10.1.10 
set ip2 10.10.2.10

# create global frame definition structure
catch {unset Frame}
struct_new Frame ATMFrameDefinition 

##########################################################
##################    PROCEDURES   #######################
##########################################################


##########################################################
# LIBCMD error handler 
##########################################################
proc LIBCMD {args} {
	set iResponse [uplevel $args]
	if {$iResponse < 0} {
	   puts "$args :  $iResponse"
	}
}
#########################################################

#########################################################
# waitForInput
# Simple wait until ENTER is pressed routine
#########################################################
proc waitForInput {} {
	puts "\nPress ENTER to continue"
	gets stdin response
}

#########################################################

#########################################################
# connectToSmartBits
#
# Checks for link with chassis.  If not linked, will link to IP
# address if one was passed in, will prompt user for IP otherwise
#########################################################
proc connectToSmartBits { {ipaddr 0} } {
   # Check for link state, connect if not linked
   if {[ETGetLinkStatus] < 1} {
      if {$ipaddr == 0} {
         puts "Chassis not linked, Enter SmartBits chassis IP address"
         gets stdin ipaddr
      } 
      set retval [NSSocketLink $ipaddr 16385 $RESERVE_ALL]
   }
}
#########################################################

#########################################################
# setATMOC3
# Set line parameters for ATM OC-3 (AT-9155) card.
#########################################################
proc setATMOC3 { H S P } {
   struct_new LineParams ATMLineParams
   set LineParams(ucFramingMode)  $::ATM_OC3_FRAMING
   set LineParams(ucTxClockSource)  $::ATM_INTERNAL_CLOCK
   set LineParams(ucCellScrambling)  $::TRUE
   set LineParams(ucHecCoset)  $::TRUE
   set LineParams(ucRxErroredCells)  $::ATM_CORRECT_ERRORED_CELLS
   set LineParams(ucLoopbackEnable)  $::ATM_LOOPBACK_DISABLED
   for {set i 0} {$i < 4} {incr i} {
      set LineParams(ucIdleCellHeader.$i) 0
   }
  LIBCMD HTSetStructure $::ATM_LINE 0 0 0 LineParams 0 $H $S $P
}
#########################################################

#########################################################
# getMaxStreamCount
# Queries card for the maximum number of streams it can 
# support and returns value to caller
#########################################################
proc getMaxStreamCount {H S P} {

   struct_new CardCapabilities ATMCardCapabilities
   LIBCMD HTGetStructure $::ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $H $S $P
   return $CardCapabilities(uiMaxStream)
}
##########################################################

#########################################################
# getMaxBandwidth
# Queries card for the maximum bandwidth of card
#########################################################
proc getMaxBandwidth {H S P} {

   struct_new CardCapabilities ATMCardCapabilities
   LIBCMD HTGetStructure $::ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $H $S $P
   return $CardCapabilities(ulLineCellRate)
}
##########################################################

##########################################################
# clearATMStream
#  disconnects and resets all streams on target card
##########################################################
proc clearATMStream {H S P} {
   struct_new ATM ATMStreamControl

   set maxStreamsOnCard [getMaxStreamCount $H $S $P]
   #Disconnect all streams
   set ATM(ucAction) $::ATM_STR_ACTION_DISCONNECT
   set ATM(ulStreamIndex) 0
   set ATM(ulStreamCount) $maxStreamsOnCard
   LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P

   # Reset All Streams
   set ATM(ucAction) $::ATM_STR_ACTION_RESET
   set ATM(ulStreamIndex) 0
   set ATM(ulStreamCount) $maxStreamsOnCard
   LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P

}
##########################################################

##########################################################
# setPPPCfg
#   sets PPP parameters for the target card.  Local IP
#   address is either passed in or defaults to 10.1.1.1
#   Peer IP is passed as second argument or defaults to
#   10.1.2.1.
#
#  For simplicity running back to back we use no authorization
#  The auth enabling code is commented out,
##########################################################
proc setPPPCfg {H S P streams {localip 10.1.1.1} {peerip 10.1.2.1} } {

set enable 1
set disable 0

struct_new pppCfg PPPParamCfg
   set pppCfg(ulpppInstance) 0
   set pppCfg(ulpppCount) $streams
   # LCP Negotiation options
#   set pppCfg(uipppWeWish) $::PPPO_USECHAPAUTH
#   set pppCfg(uipppWeMust) $::PPPO_USECHAPAUTH
#   set pppCfg(uipppWeCan)  $::PPPO_USECHAPAUTH

   set pppCfg(uipppWeWish) $::PPPO_USENONE
   set pppCfg(uipppWeMust) $::PPPO_USENONE
   set pppCfg(uipppWeCan)  $::PPPO_USENONE

   # LCP parameters
   set pppCfg(ucpppEnablePPP) $enable
   set pppCfg(ucpppCHAPAlgo) $::PPP_CHAPMS
   set pppCfg(uipppMRU) $::PPP_CONFIGURE_MRU							
   set pppCfg(uipppMaxFailure) $::PPP_CONFIGURE_MAXFAILURE			
   set pppCfg(uipppMaxConfigure) $::PPP_CONFIGURE_MAXCONFIGURE 	
   set pppCfg(uipppMaxTerminate) $::PPP_CONFIGURE_MAXTERMINATE	
   set pppCfg(ulpppMagicNumber)  $::PPP_CONFIGURE_MAGICNUMBER		

   # login and password we will authenticate
   set pppCfg(ucpppOurID.0._char_) "l"
   set pppCfg(ucpppOurID.1._char_) "o"
   set pppCfg(ucpppOurID.2._char_) "g"
   set pppCfg(ucpppOurID.3._char_) "i"
   set pppCfg(ucpppOurID.4._char_) "n"

   set pppCfg(ucpppOurPW.0._char_) "p"
   set pppCfg(ucpppOurPW.1._char_) "a"
   set pppCfg(ucpppOurPW.2._char_) "s"
   set pppCfg(ucpppOurPW.3._char_) "s"
   set pppCfg(ucpppOurPW.4._char_) "w"
   set pppCfg(ucpppOurPW.5._char_) "o"
   set pppCfg(ucpppOurPW.6._char_) "r"
   set pppCfg(ucpppOurPW.7._char_) "d"

   # login and password we will send to peer 
   set PPPCfg(ucpppPeerID.0._char_) "l"
   set PPPCfg(ucpppPeerID.1._char_) "o"
   set PPPCfg(ucpppPeerID.2._char_) "g"
   set PPPCfg(ucpppPeerID.3._char_) "i"
   set PPPCfg(ucpppPeerID.4._char_) "n"

   set PPPCfg(ucpppPeerPW.0._char_) "p"
   set PPPCfg(ucpppPeerPW.1._char_) "a"
   set PPPCfg(ucpppPeerPW.2._char_) "s"
   set PPPCfg(ucpppPeerPW.3._char_) "s"
   set PPPCfg(ucpppPeerPW.4._char_) "w"
   set PPPCfg(ucpppPeerPW.5._char_) "o"
   set PPPCfg(ucpppPeerPW.6._char_) "r"
   set PPPCfg(ucpppPeerPW.7._char_) "d"

   # IP parameters
   set pppCfg(ucpppIPEnable) $enable
   set pppCfg(ucpppNegotiateIPAddr) $enable
   set pppCfg(uipppIPCompress) $disable

   # set local IP address
   for {set i 0} {$i < 4} {incr i} {
      set pppCfg(ucpppOurIPAddr.$i) [lindex [split $localip .] $i]         
   }

   set pppCfg(uipppRestartTimer) 0x03
   set pppCfg(uipppRetryCount) 0x05

   # set peer IP address
   for {set i 0} {$i < 4} {incr i} {
      set pppCfg(ucpppPeerIPAddr.$i) [lindex [split $peerip .] $i]         
   }

   LIBCMD HTSetStructure $::PPP_SET_CONFIG 0 0 0 pppCfg 0 $H $S $P

   # copy parameters to all of the streams
   struct_new pppCopy PPPParamsCopy
   set pppCopy(uipppSrcStrNum) 0
   set pppCopy(uipppDstStrNum) 1
   set pppCopy(uipppDstStrCount) [expr $streams - 1]
   LIBCMD HTSetStructure $::PPP_PARAMS_COPY 0 0 0 pppCopy 0 $H $S $P

}
##########################################################

##########################################################
# createPPPATMStream
#
# Sets up the stream parameters such as type encapsulation,
# rate class, PCR and cell header.  Equivalent to the values
# set on the top part of the Stream Setup window in 
# SmartWindows
##########################################################

proc createPPPATMStream {H S P {streams 5} {vpi 0} {vci 0x20} {clp 0} } {

   struct_new MyPVC ATMStream

   puts "\nCreating $streams new streams on card [expr $S + 1]"
   for {set i 0} {$i < $streams} {incr i} {
      set MyPVC(uiIndex) $i
      set MyPVC(ucConnType) $::ATM_PVC 
      set MyPVC(ucEncapType) $::STR_ENCAP_TYPE_VC_MULTIPLEXED_PPP
      set MyPVC(ucGenRateClass) $::STR_RATE_CLASS_UBR

      # divide total line rate by number of streams to get Peak Cell Rate for each stream
      # We call getMaxBandwidth proc to get cards max cell rate
      set maxRate [getMaxBandwidth $H $S $P]
      set MyPVC(ulGenPCR) [expr $maxRate / $streams]

      # Assemble cell header.  Since header is 32 bits arranged as follows:
      # GFC | VPI | VCI | CLP
      #  0    00   0000    0
      # We use hex multiplication to shift VPI 20 bit places left and VCI 4 bit places left
      set cellHeader [expr ($vpi * 0x00100000) + ($vci * 0x10) + $clp]

      # Add counter * 10 hex (for 4 bit position shift) to LSB of VCI for increment 
      set MyPVC(ulCellHeader) [expr $cellHeader + ($i * 0x10)]

      # display cell headers as streams are created 08X formats as 8 position hex with leading zeroes
      puts -nonewline "   Creating stream $MyPVC(uiIndex) - Cell Header [format "%08X" $MyPVC(ulCellHeader)]"
      puts " - PCR $MyPVC(ulGenPCR) cells/sec"
      # send to card
      HTSetStructure $::ATM_STREAM 0 0 0 MyPVC 0 $H $S $P
  }
}
#############################################################

################################################################################
# calcIPCheckSum - calculates IP Checksum.  Offset of IP Header in frame is 
#   passed in as the argument.  The FrameDef structure has been declared 
#   globally
################################################################################
proc calcIPCheckSum {start} {

	global Frame
	set sum 0
	for {set i 0} {$i < [expr $start + 10]} {incr i} {
		if {$i != [expr $start + 5]} {
			set a $Frame(ucFrameData.[expr $start + (2*$i)])
			set b $Frame(ucFrameData.[expr $start + ((2*$i)+1)])
			set a [expr $a << 8]
			set a [expr $a | $b]
			set sum [expr $sum + $a]
		}
	}
	set sum [expr ~$sum]
	set a [expr $sum % 256]
	set  Frame(ucFrameData.[expr $start + 11]) $a

	set sum [expr $sum >> 8]
	set a [expr $sum % 256]
	set  Frame(ucFrameData.[expr $start + 10]) $a
}

#############################################################
# createPPPFrame
# creates contents of our frame
##############################################################

proc createPPPFrame {H S P {sip 1.1.1.1} {dip 1.1.2.1} {streams 5} } {

   global Frame
   set frameLength 60
   set userDataLength 24

   set Frame(uiFrameLength) $frameLength
   set Frame(uiDataLength) $userDataLength

   set Frame(ucFrameData.0) 0x00		
   set Frame(ucFrameData.1) 0x21
   # start of IP header - version and length		
   set Frame(ucFrameData.2) 0x45		
   set Frame(ucFrameData.3) 0x00
   # Length - you will need to account for 2nd byte with a length larger than 255
   # Here we just set the LSB
   set Frame(ucFrameData.4) 0x00
   set Frame(ucFrameData.5) [expr $frameLength - 2]
   		
   set Frame(ucFrameData.6) 0x00			
   set Frame(ucFrameData.7) 0x00		
   set Frame(ucFrameData.8) 0x00		
   set Frame(ucFrameData.9) 0x00
   # TTL 64 (0x40 hex)		
   set Frame(ucFrameData.10) 0x40
   # protocol IP in IP equals 4	
   set Frame(ucFrameData.11) 0x04	
   # source IP
   set base 14
   for {set i 0} {$i < 4} {incr i} {
      set Frame(ucFrameData.[expr $base + $i]) [lindex [split $sip .] $i]         
   }
   # destination IP
   set base 18
   for {set i 0} {$i < 4} {incr i} {
      set Frame(ucFrameData.[expr $base + $i]) [lindex [split $dip .] $i]        
   }

   set ipOffset 2
   for {set j 0} {$j < $streams} {incr j} {
      set Frame(uiStreamIndex) $j
      set Frame(ucFrameData.19) [expr $Frame(ucFrameData.19) + $j]
      set Frame(ucFrameData.23) [expr $Frame(ucFrameData.23) + $j]
      # calculate IP checksum 
      calcIPCheckSum $ipOffset
     LIBCMD HTSetStructure $::ATM_FRAME_DEF 0 0 0 Frame 0 $H $S $P
   }		
}

############################################################

############################################################
# connectATMStream
#
############################################################
proc connectATMStream {H S P {streams 5} } {
   struct_new ATM ATMStreamControl
   set ATM(ulStreamIndex) 0
   set ATM(ulStreamCount) $streams
   set ATM(ucAction) $::ATM_STR_ACTION_CONNECT
  LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P
}
#############################################################

#############################################################
# setATMBurst - sets the burst size for a group of streams
# index is first stream to set, count is how many
#############################################################
proc setATMBurst {H S P index count {burstCount 100} } {
  struct_new atm_burst ATMPerConnBurstCount

  set atm_burst(ucFunction) $::BURST_ENABLE
  set atm_burst(uiConnCount) $count
  set atm_burst(uiStartConnIdx) $index
  set atm_burst(ulFrameBurstSize) $burstCount
  HTSetStructure $::ATM_PER_STREAM_BURST 0 0 0 atm_burst 0 $H $S $P
}
#############################################################

#############################################################
# getStreamState
# Prints out stream state string corresponding to returned
# value.  Number of streams to check is passed in as 
# streamCount
#############################################################
proc getStreamState {H S P streamCount} {

struct_new StreamInfo ATMStreamDetailedInfo

   LIBCMD HTGetStructure $::ATM_STREAM_DETAIL_INFO 0 $streamCount 0 StreamInfo 0 $H $S $P
   puts "\nCONNECTION STATUS CARD [expr $S + 1]"
   for {set i 0} {$i < $streamCount} {incr i} {
      puts -nonewline "   Current state stream $i: "
      set streamState $StreamInfo(status.$i.ucStreamState)
      switch $streamState {
         0 { puts " Idle"}
	 1 { puts " Address resolution proceeding"}
         2 { puts " Address resolution failed"}
	 3 { puts " Address resolution retry"}
	 4 { puts " Connection proceeding"}
	 5 { puts " Connection established"}
	 6 { puts " Connection released"}
	 7 { puts " Connection failed"}
	 default { puts " Unknown state"}
      } 
   }
}
############################################################

#############################################################
# showATMCount
# Displays the per stream information (other counts triggers
# CRC32 errors etc are also available with this iType
#############################################################
proc showATMCount {H S P streams} {

  struct_new ExtVCCInfo ATMExtVCCInfo
  LIBCMD HTGetStructure $::ATM_STREAM_EXT_VCC_INFO 0 $streams 0 ExtVCCInfo 0 $H $S $P

  for {set i 0} {$i < $streams} {incr i} {
     puts  "==> Card [expr $S + 1] - Stream $i - Cell Header [format %08X $ExtVCCInfo(status.$i.ulCellHeader) Card [expr $S + 1]]" 
     puts  "   -------------------------------------------"
     puts  "   | Tx Frames |   $ExtVCCInfo(status.$i.ulTxFrame)"
     puts  "   | Rx Frames |   $ExtVCCInfo(status.$i.ulRxFrame)"
     puts  "   -------------------------------------------"
  }

}

#############################################################


#############################################
#############################################
################    MAIN    #################
#############################################
#############################################
# check for SmartLib.tcl load and connection
# to SmartBits chassis
connectToSmartBits

# set line parameters for both cards
setATMOC3  $iHub $iSlot $iPort
setATMOC3  $iHub2 $iSlot2 $iPort2

# erase any existing streams...
clearATMStream $iHub $iSlot $iPort
clearATMStream $iHub2 $iSlot2 $iPort2

# ...and create NumberOfPPPSessions new ones
createPPPATMStream $iHub $iSlot $iPort $numberOfPPPSessions
createPPPATMStream $iHub2 $iSlot2 $iPort2 $numberOfPPPSessions

# set up PPP configuration parameters  
setPPPCfg $iHub $iSlot $iPort $numberOfPPPSessions $ip1 $ip2
setPPPCfg $iHub2 $iSlot2 $iPort2 $numberOfPPPSessions $ip2 $ip1

# set frame data for the new streams. The IP addresses are passed in
createPPPFrame $iHub $iSlot $iPort $ip1 $ip2 $numberOfPPPSessions 
createPPPFrame $iHub2 $iSlot2 $iPort2 $ip2 $ip1 $numberOfPPPSessions 

# connect the streams
connectATMStream $iHub $iSlot $iPort $numberOfPPPSessions
connectATMStream  $iHub2 $iSlot2 $iPort2 $numberOfPPPSessions

# set each stream to send a burst of 200 packets
setATMBurst $iHub $iSlot $iPort $firstStream $numberOfPPPSessions $burstSize
setATMBurst $iHub2 $iSlot2 $iPort2 $firstStream $numberOfPPPSessions $burstSize

puts "\nConnecting $numberOfPPPSessions PPP sessions"
getStreamState $iHub $iSlot $iPort $numberOfPPPSessions
getStreamState $iHub2 $iSlot2 $iPort2 $numberOfPPPSessions

# create a group with the two cards and start transmitting
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

# With PPP you must clear the counters immediately before
# transmitting to clear the PPP negotiation frames
LIBCMD HGClearPort
LIBCMD HGStart

# display message and wait one second.  You will need to allow more
# time or use another technique if you are sending more packets.
puts "\nTransmitting...."
after 1000

LIBCMD HGStop

# display the frame counts for the two cards with a pause between
showATMCount $iHub $iSlot $iPort $numberOfPPPSessions
waitForInput
showATMCount $iHub2 $iSlot2 $iPort2 $numberOfPPPSessions

# free structure
unset Frame

# Unlink from chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
