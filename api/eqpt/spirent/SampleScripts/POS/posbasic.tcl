#################################################################
# posbasic.tcl                                                  #
#                                                               #
# Program tested against two POS-3500As in a SmartBits 600      #
#                                                               #
# Sets up multiple IP streams                                   #
# ASSUMES:                                                      #
# POS cards connected back to back                              #
#                                                               #
# NOTE: This script works on the following cards:               #
#       - POS-6500/6502                                         #
#                                                               #
#################################################################


if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/smartlib.tcl"
} else {
         set libPath "../../../../include/smartlib.tcl"
}

# if it is not loaded, try to source it at the default path
if { ! [info exists __SMARTLIB_TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
   } else {   
               
            # Enter the location of the "smartlib.tcl" file or enter "Q" or "q" to quit
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
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]  
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit
     }
}



set iHub 0
set iSlot 0
set iPort 0
set iHub2 0
set iSlot2 1
set iPort2 0
set dataLength 120
set totalStreams 5
set frameRate 5000
set packetsInBurst 10000
set numberOfBursts 2

################### LIBCMD ####################################
# LIBCMD error handler (from misc.tcl)
###############################################################
proc LIBCMD {args} {
	set iResponse [uplevel $args]
	if {$iResponse < 0} {
	   puts "$args :  $iResponse"
	}
}
#################### END LIBCMD ###############################

#####################################################################
# reset_capture   start capture
#####################################################################
proc reset_capture { H S P } {

;#global L3_CAPTURE_OFF_TYPE L3_CAPTURE_ALL_TYPE
global NS_CAPTURE_SETUP NS_CAPTURE_START

#LIBCMD HTSetCommand $L3_CAPTURE_OFF_TYPE 0 0 0 "" $H $S $P
#LIBCMD HTSetCommand $L3_CAPTURE_ALL_TYPE 0 0 0 "" $H $S $P
# Capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $H $S $P
after 2000

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $H $S $P

}
#####################################################################

#####################################################################
# show_packet 
# displays the contents of num_packets formatted in readable form
#####################################################################
proc show_packet { H S P num_packets } {

# Stop capture
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $H $S $P

struct_new CapCount NSCaptureCountInfo
LIBCMD HTGetStructure $::NS_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $H $S $P
puts " CapCount(ulCount) $CapCount(ulCount)"
   if {$CapCount(ulCount) < 1} {
       puts "No packets captured on card [expr $S + 1]"
   } else {
      if {$CapCount(ulCount) < $num_packets} {
      set num_packets $CapCount(ulCount)
      }
    struct_new CapData NSCaptureDataInfo
    for {set i 0} {$i < $num_packets} {incr i} {
         set capData(ulFrameIndex)      $i
         set capData(ulRequestedLength)      2048
         LIBCMD HTGetStructure $::NS_CAPTURE_DATA_INFO 0 0 0 CapData 0 $H $S $P
#         for {set j 0} {$j < $CapData(uiLength)} {incr j} {}
         for {set j 0} {$j < $CapData(ulRetrievedLength)} {incr j} {
         set iData 0
                  if {[expr $j % 16] == 0} {
                        puts ""
                        puts -nonewline [format "%4i:   " $j]
                  }
                  puts -nonewline " "
                  puts -nonewline [format "%02X" $CapData(ucData.$j._ubyte_)]                     
         }
         puts ""
	 if {$i < [expr $num_packets - 1]} {
	 puts ""
	 puts "Press ENTER to display packet [expr $i + 2]"
	 gets stdin response
	 } else {
	 puts "End of captured data!"
	 }
    }
 }
}
#####################################################################

###########################  MAIN  ##################################

# Explicitly reserve cards 
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Reset cards 
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2
after 2000

###################
# Set up group
###################
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

############################################
# Set Line Configuration Parameters
############################################
catch {unset MyLineCfg}
struct_new MyLineCfg POSCardLineConfig
   set MyLineCfg(ucCRC32Enabled) 0
   set MyLineCfg(ucScramble) 1
LIBCMD HTSetStructure $POS_CARD_LINE_CONFIG 0 0 0 MyLineCfg 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $POS_CARD_LINE_CONFIG 0 0 0 MyLineCfg 0 $iHub2 $iSlot2 $iPort2
############################################

############################################
# Set Encapsulation 
############################################
catch {unset MyEncap}
struct_new MyEncap POSCardPortEncapsulation
   set MyEncap(ucEncapStyle) $PROTOCOL_ENCAP_TYPE_STD_PPP
LIBCMD HTSetStructure $POS_CARD_PORT_ENCAP 0 0 0 MyEncap 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $POS_CARD_PORT_ENCAP 0 0 0 MyEncap 0 $iHub2 $iSlot2 $iPort2
############################################

############################################
# Define IP Stream
#
# Same as Ml-7710
############################################
catch {unset streamIP}
struct_new streamIP StreamIP

        set streamIP(ucActive) 1
        set streamIP(ucProtocolType) $L3_STREAM_IP
        set streamIP(uiFrameLength) $dataLength
        set streamIP(ucTagField) 1
        set streamIP(DestinationMAC.0) 0
        set streamIP(DestinationMAC.1) 0
        set streamIP(DestinationMAC.2) 0
        set streamIP(DestinationMAC.3) 0
        set streamIP(DestinationMAC.4) 2
        set streamIP(DestinationMAC.5) 0
        set streamIP(SourceMAC.0) 0
        set streamIP(SourceMAC.1) 0
        set streamIP(SourceMAC.2) 0
        set streamIP(SourceMAC.3) 0
        set streamIP(SourceMAC.4) 1
        set streamIP(SourceMAC.5) 0
        set streamIP(TypeOfService) 0
        set streamIP(TimeToLive) 10
        set streamIP(DestinationIP.0) 10
        set streamIP(DestinationIP.1) 2
        set streamIP(DestinationIP.2) 1
        set streamIP(DestinationIP.3) 10
        set streamIP(SourceIP.0) 10
        set streamIP(SourceIP.1) 1
        set streamIP(SourceIP.2) 1
        set streamIP(SourceIP.3) 10
        set streamIP(Netmask.0) 255
        set streamIP(Netmask.1) 255
        set streamIP(Netmask.2) 255
        set streamIP(Netmask.3) 0
        set streamIP(Gateway.0) 10
        set streamIP(Gateway.1) 1
        set streamIP(Gateway.2) 1
        set streamIP(Gateway.3) 1
        set streamIP(Protocol) 4
# DEFINE_IP creates a single stream according to the values above
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

	##############################
	# Flip source and destination for
	# card 2
	##############################
        set streamIP(DestinationMAC.4) 1
        set streamIP(SourceMAC.4) 2
        set streamIP(DestinationIP.1) 1
        set streamIP(SourceIP.1) 2
        set streamIP(Gateway.1) 2
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub2 $iSlot2 $iPort2


# define totalStreams - 1 (4) additional streams (total of 5)
catch {unset multiIP}
struct_new multiIP StreamIP
	set multiIP(DestinationMAC.4) 1
        set multiIP(SourceMAC.4) 1
        set multiIP(DestinationIP.1) 1
        set multiIP(SourceIP.1) 1
# DEFINE_MULTI creates additional streams with the values specified in multiIP incremented by the
# value specified in each new stream
# 1 is the stream to use as a pattern (totalStreams - 1) is the number of new streams to create
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $totalStreams - 1] 0 multiIP 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $totalStreams - 1] 0 multiIP 0 $iHub2 $iSlot2 $iPort2
###########################################
# Define stream extension
# Multiburst mode with Burst Count of 10,000
# and an MBurstCount of 2 sends two 10,000 packet bursts
###########################################
catch {unset extensionIP}
struct_new extensionIP L3StreamExtension
       set extensionIP(ulFrameRate) $frameRate
       set extensionIP(ulTxMode) $L3_MULTIBURST_MODE
       set extensionIP(ulBurstCount) $packetsInBurst
       set extensionIP(ulMBurstCount) $numberOfBursts
       set extensionIP(ulBGPatternIndex) 0
       set extensionIP(ulBurstGap) 0
       set extensionIP(uiInitialSeqNumber) 0
LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 extensionIP 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 extensionIP 0 $iHub2 $iSlot2 $iPort2

catch {unset multiextIP}
struct_new multiextIP L3StreamExtension
LIBCMD HTSetStructure $L3_DEFINE_MULTI_STREAM_EXTENSION 1 [expr $totalStreams - 1] 0 multiextIP 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $L3_DEFINE_MULTI_STREAM_EXTENSION 1 [expr $totalStreams - 1] 0 multiextIP 0 $iHub2 $iSlot2 $iPort2

###########################################

###########################################
# Clear counters with HGClearPort and
# create Counter Strucutres to hold count data
###########################################
LIBCMD HGClearPort
catch {unset cs}
struct_new cs HTCountStructure*2

###########################################
# Reset capture on both cards
###########################################
reset_capture $iHub $iSlot $iPort
reset_capture $iHub2 $iSlot2 $iPort2

#####################################################
# Start transmission with HGStart
#
# Stream is configured to send a burst, so to ensure 
# the burst is complete we wait until the transmission rate
# goes to zero, then allow 1 additional second before making final read
#####################################################

# Start and wait until rate goes to zero
#############################
LIBCMD HGStart
after 1000
LIBCMD HGGetCounters cs


while { $cs(0.TmtPktRate) !=0 } {
  after 100
  LIBCMD HGGetCounters cs
} 


after 1000

LIBCMD HGGetCounters cs

############################################
# Display test results for both cards
############################################
puts "------------------------------------------------------------"
puts "			Test Results"
puts "------------------------------------------------------------"
puts "    	        Card [expr $iSlot + 1]			Card [expr $iSlot2 +1]"
puts "------------------------------------------------------------"
puts "Tx Packets 	$cs(0.TmtPkt)		|	$cs(1.TmtPkt)"
puts "Rx Packets 	$cs(0.RcvPkt)		|	$cs(1.RcvPkt)"
puts "Collisions	$cs(0.Collision)		|	$cs(1.Collision)"
puts "Recvd Trigger	$cs(0.RcvTrig)		|	$cs(1.RcvTrig)"
puts "CRC Errors	$cs(0.CRC)		|  	$cs(1.CRC)"
puts "------------------------------------------------------------"
puts "Oversize 	$cs(0.Oversize) 		| 	$cs(1.Oversize)"
puts "Undersize	$cs(0.Undersize) 		| 	$cs(1.Undersize)"
puts "------------------------------------------------------------"

puts "Press ENTER for 1st card capture data"
gets stdin userInput
show_packet $iHub $iSlot $iPort 5

puts "Press ENTER for 2nd card capture data"
gets stdin userInput
show_packet $iHub2 $iSlot2 $iPort2 5

