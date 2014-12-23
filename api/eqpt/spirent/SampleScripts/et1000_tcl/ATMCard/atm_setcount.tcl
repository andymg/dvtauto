###############################################################################
# ATM_SetCount.tcl
#
# Back-to-back test, ensuring that the number of frames received equals the
# number of frames transmitted.
#
# The cards are first initialized by removing all streams.
#
# It then sets up a range of streams (NUM_STREAMS) and specifies the AAL5 payload,
# each bound to a stream. As the streams are being set up, the Cell Header as well
# as the Peak Cell Rate (GenPCR) is printed to screen.
#
# The connections are established and data is sent out unidirectionally from
# the card in slot1 to the card in slot2.
#
# The program uses ATM_STREAM_DETAIL to get the connection indices of the
# streams connected.  It then uses the indices to get the frame counts using
# ATM_VCC_INFO and displays the Connection index along with that connection's
# Frame count.
#
###############################################################################

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

# Tx card in slot 1....
set iHub 0
set iSlot 0
set iPort 0

# ....and Rx card in slot 3
set iHub2 0
set iSlot2 2
set iPort2 0

set iCount 1
set NUM_STREAMS 5
set FRAME_LENGTH 60
set DATA_LENGTH 24
set TX_SECONDS 3

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

#######################################################################
###### SET UP STREAMS #################################################
#######################################################################
#######################################################################

#################################################################
#
# ATMCardCapabilities structures hold the parameters that define 
# the max capabilities of a particular card type
#
# It is recommended programming practice to 
# check the capabilities of the card to get the 
# parameters dynamically
################################################################# 
struct_new CardCapabilities ATMCardCapabilities
LIBCMD HTGetStructure $ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $iHub\
                      $iSlot $iPort

################################################################
# ATMStreamControl is used to connect, disconnect,
# start and stop streams.
#
# You configure the ATMStreamControl structure with appropriate
# ucAction, then call ATM_STREAM_CONTROL
# iType1 to send the settings to the card.
#
# Note that it is not necessary to loop through
# all the values.
################################################################

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
# This sets up the stream parameters such as type encapsulation,
# rate class, PCR and cell header.  Equivalent to the values
# set on the top part of the Stream Setup window in 
# SmartWindows
#
# For clarity this example prints out the stream number
# the cell header and the PCR of each stream
#
# The peak cell rate for each stream is set
# by dividing the cards max cell rate by the number of streams
##########################################################
struct_new MyPVC ATMStream
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
    set MyPVC(uiIndex) $i
    set MyPVC(ucConnType) [ format %c $ATM_PVC ]
    set MyPVC(ucEncapType) [ format %c $STR_ENCAP_TYPE_NULL ]
    set MyPVC(ucGenRateClass) [ format %c $STR_RATE_CLASS_UBR ]
    set MyPVC(ulGenPCR) [expr $ATM_155_LINE_CELL_RATE / $NUM_STREAMS ]
    set MyPVC(ulCellHeader) [expr 0x00000200 + ($i << 4)]
    puts -nonewline "Creating stream $MyPVC(uiIndex) - Cell Header [format "%08X" $MyPVC(ulCellHeader)]"
    puts " - PCR $MyPVC(ulGenPCR) cells/sec"
	 HTSetStructure $ATM_STREAM 0 0 0 MyPVC 0 $iHub $iSlot $iPort
    HTSetStructure $ATM_STREAM 0 0 0 MyPVC 0 $iHub2 $iSlot2 $iPort2
}
unset MyPVC

after 1000

####################################################
#Define streams with $ATM_FRAME_DEF
#
# Sets the frame configuration values.  This
# is equivalent to the settings at the bottom of
# the Stream Setup window in SmartWindows
#
# Sets frame length, fill length, fill pattern,
# etc.
#
# The FRAME_LENGTH is the overall length of the packet
# The DATA_LENGTH is the number of bytes we will modify
# with our data.  In this case, we will insert protocol
# data in the first 24 bytes of the frame.
#
# The remainder of the frame will be filled with
# 3's, the value of uiFrameFillPAttern
####################################################
puts "Creating frame data"
struct_new PVCFrameDef ATMFrameDefinition 
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
    set PVCFrameDef(uiStreamIndex) $i
    set PVCFrameDef(uiFrameLength) $FRAME_LENGTH
    set PVCFrameDef(uiDataLength) $DATA_LENGTH
    #Set RFC 1483 bridged header type
    set PVCFrameDef(ucFrameData.0) [format %c 0xAA]
    set PVCFrameDef(ucFrameData.1) [format %c 0xAA]
    set PVCFrameDef(ucFrameData.2) [format %c 0x03]
    set PVCFrameDef(ucFrameData.3) [format %c 0x00]
    set PVCFrameDef(ucFrameData.4) [format %c 0x80]
    set PVCFrameDef(ucFrameData.5) [format %c 0x22]
	 set PVCFrameDef(ucFrameData.6) [format %c 0x00]
    set PVCFrameDef(ucFrameData.7) [format %c 0x07]
    set PVCFrameDef(ucFrameData.8) [format %c 0x00]
    set PVCFrameDef(ucFrameData.9) [format %c 0x00]
    # destination MAC - set to card number of card 2
    set PVCFrameDef(ucFrameData.10) [format %c 0x00]
    set PVCFrameDef(ucFrameData.11) [format %c 0x00]
    set PVCFrameDef(ucFrameData.12) [format %c 0x00]
    set PVCFrameDef(ucFrameData.13) [format %c 0x00]
    set PVCFrameDef(ucFrameData.14) [format %c 0x00]
	 set PVCFrameDef(ucFrameData.15) [format %c $iSlot2]
    # source MAC - set to Slot number of card 1
    set PVCFrameDef(ucFrameData.16) [format %c 0x00]
    set PVCFrameDef(ucFrameData.17) [format %c 0x00]
    set PVCFrameDef(ucFrameData.18) [format %c 0x00]
    set PVCFrameDef(ucFrameData.19) [format %c 0x00]
    set PVCFrameDef(ucFrameData.20) [format %c 0x00]
    set PVCFrameDef(ucFrameData.21) [format %c $iSlot]
    # Type 0800
    set PVCFrameDef(ucFrameData.22) [format %c 0x08]
    set PVCFrameDef(ucFrameData.23) [format %c 0x00]

    # Fill rest of frame with 33
    set PVCFrameDef(uiFrameFillPattern) 33
	 set PVCFrameDef(ulFrameFlags) 0
    HTSetStructure $ATM_FRAME_DEF 0 0 0 PVCFrameDef 0 $iHub $iSlot $iPort
    HTSetStructure $ATM_FRAME_DEF 0 0 0 PVCFrameDef 0 $iHub2 $iSlot2 $iPort2
}
unset PVCFrameDef

after 1000

######################################################
#Connect Streams
#
# Similar to other ATM_STREAM_CONTROL functions
# Change ucAction to whatever action is needed and 
# call HTSetStructure with $ATM_STREAM_CONTROL to send
# to card
######################################################
puts "Connecting $NUM_STREAMS Streams"
set ATM(ulStreamIndex) 0
set ATM(ulStreamCount) $NUM_STREAMS
set ATM(ucAction) [format %c $ATM_STR_ACTION_CONNECT]
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub2 $iSlot2 $iPort2

after 1000

########################################################
#Start Transmitting
#
# Another $ATM_STREAM_CONTROL function.
# Run and Stop functions can also be done with
# HTRun $HTRUN $iHub $iSlot $iPort and
# HTRun $HTSTOP $iHub $iSlot $iPort
# for backward compatibility
########################################################
set ATM(ucAction) [format %c $ATM_STR_ACTION_START]
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort

# PAUSE for TX_SECONDS delay (multiply times 1000 to convert mS to seconds
puts "Transmitting for $TX_SECONDS seconds"
after [expr $TX_SECONDS * 1000]

# STOP TRANSMITTING
puts "Stopping transmission"
set ATM(ucAction) [format %c $ATM_STR_ACTION_STOP]
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort

##################################################################
##################################################################
#########  GET STATS
##################################################################
##################################################################

struct_new vcc_info ATMVCCInfo
struct_new stream_info ATMStreamDetailedInfo

puts "------------------------------------------------------------"
puts "                Transmit Card Data                          "
puts "------------------------------------------------------------"

# Use ATM_STREAM_DETAIL to get the connection index and assign it to iCount
LIBCMD HTGetStructure $ATM_STREAM_DETAIL_INFO 0 $NUM_STREAMS 0 stream_info 0\
                      $iHub $iSlot $iPort

for {set j 0} {$j < $NUM_STREAMS} { incr j} {
    set StreamIndex $stream_info(status.$j.uiConnIndex)
    puts "Checking status on Tx Card (Connection Index $StreamIndex)"

    LIBCMD HTGetStructure $ATM_VCC_INFO $StreamIndex 1 0 vcc_info 0 $iHub\
								  $iSlot $iPort
	 puts "Stats for stream $j..."

	 # IMPORTANT NOTE::: The retrieval of the VCC status information will
	 # always be found on index 0, since we are retrieving it one at
	 # a time...
	 # Cell header is decimal by default - force to hex...
	 puts "Cell Header [format "%08X" $vcc_info(status.0.ulCellHeader)]"
	 puts "Tx Frame count ==> $vcc_info(status.0.ulTxFrame)"
	 puts ""
}
puts "Press ENTER key for the Receive Card stats....."
gets stdin response

##################################################################
# duplicate of procedure for the Tx card
# Here to save time we just display the stats of the first stream
##################################################################
LIBCMD HTGetStructure $ATM_STREAM_DETAIL_INFO 0 1 0 stream_info 0 $iHub2\
							 $iSlot2 $iPort2
set iCount $stream_info(status.0.uiConnIndex)
puts "Checking status on Rx Card (Connection Index $iCount)"

puts "------------------------------------------------------------"
puts "                Receive Card Data                           "
puts "------------------------------------------------------------"
LIBCMD HTGetStructure $ATM_VCC_INFO $iCount 1 0 vcc_info 0 $iHub2 $iSlot2\
                      $iPort2
puts "Cell Header [format "%08X" $vcc_info(status.0.ulCellHeader)]"
puts "Rx Frame count ==> $vcc_info(status.0.ulRxFrame)"

# free resources
unset vcc_info
unset stream_info
unset ATM
unset CardCapabilities

#UnLink from the chassis
LIBCMD NSUnLink