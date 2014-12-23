# ATMCount.tcl
# Simple PVC to PVC connection between two cards.  
# Demonstrates the various per port and per stream ATM counters.
# 
# Creates NUM_STREAMS PVC streams starting at 0/32 (0/20 hex)
# and incrementing upward.
#
# Program will work with two cards connected back to
# back without a DUT.
###################################################

######################################################
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

######################################################

#cards in slots 1...
set iHub 0
set iSlot 0
set iPort 0

#... and 2
set iHub2 0
set iSlot2 2
set iPort2 0

set NUM_STREAMS 5
set FRAME_LENGTH 120
set DATA_LENGTH 24

#############################################
# ATMCardCapabilities structures hold the parameters that define 
# the max capabilities of a particular card type
#
# It is recommended programming practice to 
# check the capabilities of the card to get the 
# parameters dynamically
############################################# 
catch {unset CardCapabilities}
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
catch {unset ATM}
struct_new ATM ATMStreamControl

#Disconnect all streams
set ATM(ucAction) $ATM_STR_ACTION_DISCONNECT
set ATM(ulStreamIndex) 0
set ATM(ulStreamCount) $CardCapabilities(uiMaxStream)
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub2 $iSlot2 $iPort2

#Reset All Streams
set ATM(ucAction) $ATM_STR_ACTION_RESET
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
catch {unset MyPVC}
struct_new MyPVC ATMStream
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
set MyPVC(uiIndex) $i
set MyPVC(ucConnType) $ATM_PVC
set MyPVC(ucEncapType) $STR_ENCAP_TYPE_NULL
set MyPVC(ucGenRateClass) $STR_RATE_CLASS_UBR
set MyPVC(ulGenPCR) [expr $ATM_155_LINE_CELL_RATE / [expr $NUM_STREAMS] ]
set MyPVC(ulCellHeader) [expr 0x00000200 + ($i << 4)]
puts -nonewline "Creating stream $MyPVC(uiIndex) - Cell Header [format "%08X" $MyPVC(ulCellHeader)]"
puts " - PCR $MyPVC(ulGenPCR) cells/sec"
HTSetStructure $ATM_STREAM 0 0 0 MyPVC 0 $iHub $iSlot $iPort
HTSetStructure $ATM_STREAM 0 0 0 MyPVC 0 $iHub2 $iSlot2 $iPort2
}

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
catch {unset PVCFrameDef}
struct_new PVCFrameDef ATMFrameDefinition 
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
set PVCFrameDef(uiStreamIndex) $i
set PVCFrameDef(uiFrameLength) $FRAME_LENGTH
set PVCFrameDef(uiDataLength) $DATA_LENGTH
#Set RFC 1483 bridged header type
set PVCFrameDef(ucFrameData.0) 0xAA
set PVCFrameDef(ucFrameData.1) 0xAA
set PVCFrameDef(ucFrameData.2) 0x03
set PVCFrameDef(ucFrameData.3) 0x00
set PVCFrameDef(ucFrameData.4) 0x80
set PVCFrameDef(ucFrameData.5) 0xC2
set PVCFrameDef(ucFrameData.6) 0x00
set PVCFrameDef(ucFrameData.7) 0x07
set PVCFrameDef(ucFrameData.8) 0x00
set PVCFrameDef(ucFrameData.9) 0x00
# destination MAC - set to card number of card 2
set PVCFrameDef(ucFrameData.10) 0x00
set PVCFrameDef(ucFrameData.11) 0x00
set PVCFrameDef(ucFrameData.12) 0x00
set PVCFrameDef(ucFrameData.13) 0x00
set PVCFrameDef(ucFrameData.14) 0x01
set PVCFrameDef(ucFrameData.15) $iSlot2
# source MAC - set to Slot number of card 1
set PVCFrameDef(ucFrameData.16) 0x00
set PVCFrameDef(ucFrameData.17) 0x00
set PVCFrameDef(ucFrameData.18) 0x00
set PVCFrameDef(ucFrameData.19) 0x00
set PVCFrameDef(ucFrameData.20) 0x01
set PVCFrameDef(ucFrameData.21) $iSlot
# Type 0800
set PVCFrameDef(ucFrameData.22) 0x08
set PVCFrameDef(ucFrameData.23) 0x00

# Fill rest of frame with AA 55
set PVCFrameDef(uiFrameFillPattern) 0xAA55
set PVCFrameDef(ulFrameFlags) 0
puts "Sending Frame Data for stream $i"
HTSetStructure $ATM_FRAME_DEF 0 0 0 PVCFrameDef 0 $iHub $iSlot $iPort

# reverse for second card
set PVCFrameDef(ucFrameData.15) $iSlot
set PVCFrameDef(ucFrameData.21) $iSlot2
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
set ATM(ucAction) $ATM_STR_ACTION_CONNECT
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub2 $iSlot2 $iPort2

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
# ATM_AAL5_INFO shows the per card AAL5 level frame and cell counts. These
# are the total counts for the card.  The 3.07 library adds counts 
# for per card AAL5 CRC32 errors and length errors.
# ATM_STREAM_EXT_VCC_INFO displays the frame counts on a per stream
# basis, as did ATM_STREAM_VCC_INFO.  The ATM_STREAM_EXT_VCC_INFO function also  
# has new count elements, CRC32 per stream and RxTriggers per stream
# compared to ATM_STREAM_VCC_INFO
########################################################
# Get ATM Layer Data
# per card ATM Cell Counts
########################################################
catch {unset ATMInfo}
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

########################################################
# Get per card AAL5 Frame and Cell Counts
# Not all fields are functional on all ATM cards
########################################################
catch {unset AAL5Info}
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

########################################################
# Get per stream data
# ATM_STREAM_EXT_VCC_INFO allows retrieval of stream data
# using the stream index.  
# Has same counts as ATM_STREAM_VCC_INFO plus also has
# per stream triggers and CRC32 Error information.
# Requires Programming Library 3.07
# or later release
########################################################
catch {unset ExtVCCInfo1}
struct_new ExtVCCInfo1 ATMExtVCCInfo
catch {unset ExtVCCInfo2}
struct_new ExtVCCInfo2 ATMExtVCCInfo
puts "Retrieving per stream data from card [expr $iSlot + 1]"
LIBCMD HTGetStructure $ATM_STREAM_EXT_VCC_INFO 0 $NUM_STREAMS 0 ExtVCCInfo1 0 $iHub $iSlot $iPort
puts "Retrieving per stream data from card [expr $iSlot2 + 1]"
LIBCMD HTGetStructure $ATM_STREAM_EXT_VCC_INFO 0 $NUM_STREAMS 0 ExtVCCInfo2 0 $iHub2 $iSlot2 $iPort2

for {set i 0} {$i < $NUM_STREAMS} {incr i} {
   puts  "\n\n==> Stream $i - Cell Header [format %08X $ExtVCCInfo1(status.$i.ulCellHeader)] to [format %08X $ExtVCCInfo2(status.$i.ulCellHeader)]"
   puts  ""
   puts  "                   Card [expr $iSlot + 1]	     Card [expr $iSlot2 + 1]"
   puts  "   -------------------------------------------"
   puts  "   | Tx Frames |   $ExtVCCInfo1(status.$i.ulTxFrame)	 |   $ExtVCCInfo2(status.$i.ulTxFrame)  "
   puts  "   | Rx Frames |   $ExtVCCInfo1(status.$i.ulRxFrame)	 |   $ExtVCCInfo2(status.$i.ulRxFrame)  "
   puts  "   | Rx Trigs  |   $ExtVCCInfo1(status.$i.ulRxTriggerCt)	 	 |   $ExtVCCInfo2(status.$i.ulRxTriggerCt)  "
   puts  "   | RxCRC32Err|   $ExtVCCInfo1(status.$i.ulRxCRC32Err)	 	 |   $ExtVCCInfo2(status.$i.ulRxCRC32Err)"
   puts  "   -------------------------------------------"
   puts "\nPress ENTER to continue"
   gets stdin response
}

# Unlink from chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"

