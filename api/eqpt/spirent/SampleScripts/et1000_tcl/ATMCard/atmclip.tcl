#ATMClip.tcl
# Classical PVC to PVC connections between two cards
# 
# Creates 2 (NUM_STREAMS) PVC streams starting at 0/32 (0/20 hex)
# and incrementing upward.
#
# ATM Clip server is not used for PVC connections
# ASSUMES:
# PVC connections through switch have been set up.
# AT-9155 ATM Cards are installed in slots 1 and 3.
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

#... and 3
set iHub2 0
set iSlot2 2
set iPort2 0

set NUM_STREAMS 2
set FRAME_LENGTH 60
set DATA_LENGTH 28

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
# This set up the stream parameters such as type encapsulation,
# rate class, PCR and cell header.  Equivalent to the values
# set on the top part of the Stream Setup window in 
# SmartWindows
#
# For clarity this example prints out the stream number
# the cell header and the PCR of each stream
# Remember, if you are sending the traffic through a device
# you will need to create VCCs with the corresponding VPI:VCI
#
# The peak cell rate for each stream is set
# by dividing the cards max cell rate by the number of steams
##########################################################
struct_new MyPVC ATMStream
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
set MyPVC(uiIndex) $i
set MyPVC(ucConnType) [ format %c $ATM_PVC ]
set MyPVC(ucEncapType) [ format %c $STR_ENCAP_TYPE_RFC1577 ]
set MyPVC(ucGenRateClass) [ format %c $STR_RATE_CLASS_UBR ]
set MyPVC(ulGenPCR) [expr $ATM_155_LINE_CELL_RATE / $NUM_STREAMS]
# Destination IP for card 1 is card 2's 10.1.1.20
set MyPVC(ucDestIpAddr.0.uc) [format %c 10]
set MyPVC(ucDestIpAddr.1.uc) [format %c 1]
set MyPVC(ucDestIpAddr.0.uc) [format %c 1]
set MyPVC(ucDestIpAddr.1.uc) [format %c 20]
set MyPVC(ulCellHeader) [expr 0x00000200 + ($i << 4)]
puts -nonewline "Creating stream $MyPVC(uiIndex) - Cell Header [format "%08X" $MyPVC(ulCellHeader)]"
puts " - PCR $MyPVC(ulGenPCR) cells/sec"
HTSetStructure $ATM_STREAM 0 0 0 MyPVC 0 $iHub $iSlot $iPort

# Destination IP for card 2 is card 1's 10.1.1.10
set MyPVC(ucDestIpAddr.1.uc) [format %c 10]
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
# 3's the value of uiFrameFillPAttern
####################################################
struct_new PVCFrameDef ATMFrameDefinition 
for {set i 0} {$i < $NUM_STREAMS} {incr i} {
set PVCFrameDef(uiStreamIndex) $i
set PVCFrameDef(uiFrameLength) $FRAME_LENGTH
set PVCFrameDef(uiDataLength) $DATA_LENGTH
#DSAP and SSAP
set PVCFrameDef(ucFrameData.0.uc) [format %c 0xAA]
set PVCFrameDef(ucFrameData.1.uc) [format %c 0xAA]
#Control and OUI
set PVCFrameDef(ucFrameData.2.uc) [format %c 0x03]
set PVCFrameDef(ucFrameData.3.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.4.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.5.uc) [format %c 0x00]
#IP Header Type
set PVCFrameDef(ucFrameData.6.uc) [format %c 0x08]
set PVCFrameDef(ucFrameData.7.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.8.uc) [format %c 0x45]
set PVCFrameDef(ucFrameData.9.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.10.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.11.uc) [format %c 0x34]
set PVCFrameDef(ucFrameData.12.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.13.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.14.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.15.uc) [format %c 0x00]
set PVCFrameDef(ucFrameData.16.uc) [format %c 0x40]
set PVCFrameDef(ucFrameData.17.uc) [format %c 0x04]
set PVCFrameDef(ucFrameData.18.uc) [format %c 0x64]
set PVCFrameDef(ucFrameData.19.uc) [format %c 0xA7]
#IP source is 10.1.1.20
set PVCFrameDef(ucFrameData.20.uc) [format %c 10]
set PVCFrameDef(ucFrameData.21.uc) [format %c 1]
set PVCFrameDef(ucFrameData.22.uc) [format %c 1]
set PVCFrameDef(ucFrameData.23.uc) [format %c 20]
#IP destination is 10.1.1.10
set PVCFrameDef(ucFrameData.24.uc) [format %c 10]
set PVCFrameDef(ucFrameData.25.uc) [format %c 1]
set PVCFrameDef(ucFrameData.26.uc) [format %c 1]
set PVCFrameDef(ucFrameData.27.uc) [format %c 10]
# Fill rest of frame with 00
set PVCFrameDef(uiFrameFillPattern) 00
set PVCFrameDef(ulFrameFlags) 0
HTSetStructure $ATM_FRAME_DEF 0 0 0 PVCFrameDef 0 $iHub $iSlot $iPort

# reverse source and destination IP LSB
set PVCFrameDef(ucFrameData.23.uc) [format %c 10]
set PVCFrameDef(ucFrameData.27.uc) [format %c 20]
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

########################################################
#Start Transmitting
#
# Another ATM_STREAM_CONTROL function
# Run and Stop functions can also be done with
# HTRun $HTRUN $iHub $iSlot $iPort
# and
# HTRun $HTSTOP $iHub $iSlot $iPort
# for backward compatibility
########################################################
set ATM(ucAction) [format %c $ATM_STR_ACTION_START]
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort

puts "Transmitting on $NUM_STREAMS streams - Press ENTER key to stop"
gets stdin response

########################################################
#stop
########################################################
set ATM(ucAction) [format %c $ATM_STR_ACTION_STOP]
LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $iHub $iSlot $iPort

###################################################

unset ATM
unset CardCapabilities

#UnLink from the chassis
LIBCMD NSUnLink