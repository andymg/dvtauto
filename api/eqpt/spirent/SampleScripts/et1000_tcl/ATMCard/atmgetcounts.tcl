# ATMGetCounts.tcl
# Simple PVC to PVC connection between two cards.  Uses newer
# ATM_STREAM_VCC_INFO command to get per stream data without 
# needing to get the connection index first.  Requires ATM
# firmware 2.x and programming library release 3.06 an higher.
# 
# Creates NUM_STREAMS PVC streams starting at 0/32 (0/20 hex)
# and incrementing upward.
#
# Program will work with two cards connected back to
# back without a DUT.
#
###################################################

#########################################
if  {$tcl_platform(platform) == "windows"} {
   set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
   set libPath "../../../../include/et1000.tcl"
}
# if it is not loaded, try to source it at the default path
if { ! [info exists __ET1000_TCL__] } {
   if {[file exists $libPath]} {
      source $libPath
   } else {   
               
      # Enter the location of the "et1000.tcl" file or enter "Q" or "q" to quit
      while {1} {
         
          puts "Could not find the file $libPath."
          puts "Enter the path of et1000.tcl, or q to exit." 
          
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


#cards in slots 1...
set iHub 0
set iSlot 0
set iPort 0

#... and 2
set iHub2 0
set iSlot2 2
set iPort2 0

set NUM_STREAMS 4
set FRAME_LENGTH 120
set DATA_LENGTH 24

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

#############################################
# ATMCardCapabilities structures hold the parameters that define 
# the max capabilities of a particular card type
#
# It is recommended programming practice to 
# check the capabilities of the card to get the 
# parameters dynamically
#############################################
struct_new CardCapabilities ATMCardCapabilities
LIBCMD HTGetStructure $ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $iHub $iSlot $iPort

#############################################
# ATMStreamControl is used to connect, disconnect
# start and stop streams.
#
# You configure the ATMStreamControl structure with appropriate
# ucAction, then call ATM_STREAM_CONTROL
# iType1 to send the settings to the card.
#
# Note that it is not necessary to loop through
# all the values.
#############################################

struct_new ATM ATMStreamControl

#Disconnect all streams
set ATM(ucAction) [format %c $ATM_STR_ACTION_DISCONNECT]
set ATM(ulStreamIndex) 0
set ATM(ulStreamCount) $CardCapabilities(uiMaxStream)
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub2 $iSlot2 $iPort2

#Reset All Streams
set ATM(ucAction) [format %c $ATM_STR_ACTION_RESET]
set ATM(ulStreamIndex) 0
set ATM(ulStreamCount) $CardCapabilities(uiMaxStream)
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub2 $iSlot2 $iPort2

##########################################################
#Create New Streams with $ATM_STREAM
#
# This set up the stream parameters such as type encapsulation
# rate class PCR and cell header.  Equivalent to the values
# set on the top part of the Stream Setup window in 
# SmartWindows
#
# For clarity this example prints out the stream number
# the cell header and the PCR of each stream
#
# The peak cell rate for each stream is made different
# by dividing the cards max cell rate by the number of streams
# minus the loop number.  This will give different PCR for each
# stream
##########################################################
struct_new MyPVC ATMStream
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
set MyPVC(uiIndex) $i
set MyPVC(ucConnType) [ format %c $ATM_PVC ]
set MyPVC(ucEncapType) [ format %c $STR_ENCAP_TYPE_NULL ]
set MyPVC(ucGenRateClass) [ format %c $STR_RATE_CLASS_UBR ]
set MyPVC(ulGenPCR) [expr $ATM_155_LINE_CELL_RATE / [expr $NUM_STREAMS + $i] ]
set MyPVC(ulCellHeader) [expr 0x00000200 + ($i << 4)]
puts -nonewline "Creating stream $MyPVC(uiIndex) - Cell Header [format "%08X" $MyPVC(ulCellHeader)]"
puts " - PCR $MyPVC(ulGenPCR) cells/sec"
HTSetStructure $ATM_STREAM 0 0 0 MyPVC 0 $iHub $iSlot $iPort
HTSetStructure $ATM_STREAM 0 0 0 MyPVC 0 $iHub2 $iSlot2 $iPort2
}
unset MyPVC

####################################################
#Define streams with $ATM_FRAME_DEF
#
# Sets the frame configuration values.  This
# is equivalent to the settings at the bottom of
# the Stream Setup window in SmartWindows
#
# Sets frame length, fill length, fill pattern
# etc.
#
# The FRAME_LENGTH is the overall length of the packet
# The DATA_LENGTH is the number of bytes we will modify
# with our data.  In this case, we will insert protocol
# data in the first 24 bytes of the frame.
#
# The remainder of the frame will be filled with
# AA 55. the value of uiFrameFillPAttern
####################################################
struct_new PVCFrameDef ATMFrameDefinition 
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
set PVCFrameDef(uiStreamIndex) $i
set PVCFrameDef(uiFrameLength) $FRAME_LENGTH
set PVCFrameDef(uiDataLength) $DATA_LENGTH
#Set RFC 1483 bridged header type
set PVCFrameDef(ucFrameData.0.uc) [format %c 0xAA]
set PVCFrameDef(ucFrameData.1.uc) [format %c 0xAA]
set PVCFrameDef(ucFrameData.2.uc) [format %c 0x03]
set PVCFrameDef(ucFrameData.3.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.4.uc) [format %c 0x80]
set PVCFrameDef(ucFrameData.5.uc) [format %c 0xC2]
set PVCFrameDef(ucFrameData.6.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.7.uc) [format %c 0x07]
set PVCFrameDef(ucFrameData.8.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.9.uc) [format %c 0x00]
# destination MAC - set to card number of card 2
set PVCFrameDef(ucFrameData.10.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.11.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.12.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.13.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.14.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.15.uc) [format %c $iSlot2]
# source MAC - set to Slot number of card 1
set PVCFrameDef(ucFrameData.16.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.17.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.18.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.19.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.20.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.21.uc) [format %c $iSlot]
# Type 0800
set PVCFrameDef(ucFrameData.22.uc) [format %c 0x08]
set PVCFrameDef(ucFrameData.23.uc) [format %c 0x00]

# Fill rest of frame with AA 55
set PVCFrameDef(uiFrameFillPattern) 0xAA55
set PVCFrameDef(ulFrameFlags) 0
puts "Sending Frame Data for stream $i"
HTSetStructure $ATM_FRAME_DEF 0 0 0 PVCFrameDef 0 $iHub $iSlot $iPort
HTSetStructure $ATM_FRAME_DEF 0 0 0 PVCFrameDef 0 $iHub2 $iSlot2 $iPort2
}
unset PVCFrameDef

######################################################
#Connect Streams
#
# Similar to other ATM_STREAM_CONTROL functions
# Change ucAction to whatever action is needed and 
# call HTSetSTructure with $ATM_STREAM_CONTROL to send to card
######################################################
set ATM(ulStreamIndex) 0
set ATM(ulStreamCount) $NUM_STREAMS
set ATM(ucAction) [format %c $ATM_STR_ACTION_CONNECT]
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub2 $iSlot2 $iPort2

unset ATM
unset CardCapabilities


########################################################
# Set a group and clear counters
# ATM Cards use the same group commands as Ethernet cards
########################################################
HGSetGroup ""

HGAddtoGroup $iHub $iSlot $iPort
HGAddtoGroup $iHub $iSlot2 $iPort
HGClearPort


########################################################
#Start Transmitting
# The ATM Cards can also be started and stopped by using
# the ATM_STREAM_CONTROL function setting the ucAction to
# ATM_STR_ACTION_START or ATM_STR_ACTION_STOP.  
# Setting a group and using the group functions allows 
# more simultaneous control of starts and stops, making
# frame counts more equal between cards.
#########################################################
HGStart

puts "Transmitting on $NUM_STREAMS streams - Press ENTER key to stop"
gets stdin response

########################################################
#stop
########################################################
HGStop


#########################################################
#########################################################
# ATM COUNTERS
# Demonstrates the three counters on the ATM Family cards
# ATM_LAYER_INFO shows the ATM Layer cell counts and HEC errors
# ATM_AAL5_INFO shows the AAL5 level frame and cell counts. These
# are the total counts for the card.  The 3.07 library adds counts 
# for AAL5 CRC32 errors and length errors.
# ATM_STREAM_VCC_INFO displays the frame counts on a per stream
# basis.  The ATM_STREAM_VCC_INFO function is new in 3.07.  The
# ATM_VCC_INFO function used previously, accessed the data by
# the connection index not the stream number requiring an extra
# step.
########################################################
# Get ATM Layer Data
# per card ATM Cell Counts
########################################################
struct_new ATMInfo ATMLayerInfo
LIBCMD HTGetStructure $ATM_LAYER_INFO 0 0 0 ATMInfo 0 $iHub $iSlot $iPort
puts ""
puts "**** ATM Layer Counts for card [expr $iSlot + 1] ****"
puts "Total Tx Cells $ATMInfo(ullTxCell.low)"
puts "Total Rx Cells $ATMInfo(ullRxCell.low)"
puts "Total Rx Corrected HEC Errors $ATMInfo(ullRxHecCorrErrors.low)"
puts "Total Rx Uncorrected HEC Errors $ATMInfo(ullRxHecUncorrErrors.low)"
puts "\nPress ENTER for AAL5 counts"
gets stdin response
unset ATMInfo
########################################################
# Get per card AAL5 Frame and Cell Counts
########################################################
struct_new AAL5Info ATMAAL5LayerInfo
LIBCMD HTGetStructure $ATM_AAL5_INFO 0 0 0 AAL5Info 0 $iHub $iSlot $iPort
puts ""
puts "**** AAL5 Counts for card [expr $iSlot + 1] ****"
puts "Timestamp $AAL5Info(ulTimeStamp)"
puts "Tx Cells 	-	$AAL5Info(ulTxCell)" 
puts "Tx Frames	- 	$AAL5Info(ulTxFrame)" 
puts "Rx Cells 	-	$AAL5Info(ulRxCell)" 
puts "Rx Frames 	-	$AAL5Info(ulRxFrame)" 
# Error counts only on ATM 2 cards (9155-C and 9622)
puts "Received CRC32 Errors  $AAL5Info(ulRxCRC32Errors)" 
puts "Received Length Errors $AAL5Info(ulRxLengthErrors)" 
puts "\nPress ENTER for per stream counts"
gets stdin response
unset AAL5Info
########################################################
# Get per stream data
# ATM_STREAM_VCC_INFO allows retrieval of stream data
# using the stream index.  Requires Programming Library 3.07
# or later release
########################################################
struct_new VCCInfo1 ATMVCCInfo
struct_new VCCInfo2 ATMVCCInfo
puts "Retrieving per stream data from card [expr $iSlot + 1]"
LIBCMD HTGetStructure $ATM_STREAM_VCC_INFO 0 $NUM_STREAMS 0 VCCInfo1 0 $iHub $iSlot $iPort
puts "Retrieving per stream data from card [expr $iSlot2 + 1]"
LIBCMD HTGetStructure $ATM_STREAM_VCC_INFO 0 $NUM_STREAMS 0 VCCInfo2 0 $iHub2 $iSlot2 $iPort2

for {set i 0} {$i < $NUM_STREAMS} {incr i} {
   puts  "\n\n==> Stream $i - Cell Header [format %08X $VCCInfo1(status.$i.ulCellHeader)] to [format %08X $VCCInfo2(status.$i.ulCellHeader)]"
   puts  ""
   puts  "                   Card [expr $iSlot + 1]	     Card [expr $iSlot2 + 1]"
   puts  "   -------------------------------------------"
   puts  "   | Tx Frames |   $VCCInfo1(status.$i.ulTxFrame)	 |   $VCCInfo2(status.$i.ulTxFrame)   |"
   puts  "   | Rx Frames |   $VCCInfo1(status.$i.ulRxFrame)	 |   $VCCInfo2(status.$i.ulRxFrame)   |"
   puts  "   -------------------------------------------"
   puts "\nPress ENTER to continue"
	gets stdin response
}
unset VCCInfo1
unset VCCInfo2

#UnLink from the chassis
LIBCMD NSUnLink
