######################################################################
######################################################################
# L3_SB.tcl                                                          #
#                                                                    #
# - Sets the SmartBits stream                                        #
# - Tranmits packets in SINGLE_BURST_MODE                            #
# - Fills in background data                                         #
# - Uses NS_CAPTURE_SETUP to set up capture                          #
# - Uses NS_CAPTURE_START to start capture                           #
# - Uses NS_CAPTURE_STOP to stop capture                             #
# - Uses NS_CAPTURE_COUNT_INFO to capture count info                 #
# - Uses NS_CAPTURE_DATA_INFO to capture data info                   #
# - Displays the number of frames specified by NUM_VIEW_CAP_FRAMES,  #
#   displaying "DISPLAY_LINES" per screen.                           # 
#                                                                    #
# NOTE: This script works on the following cards:                    #
#       - L3-67XX                                                    #
#       - ML-7710                                                    #
#       - ML-5710                                                    #
#       - LAN-6101A                                                  #
#                                                                    #
######################################################################


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

#Set the default variables
set iHub        0
set iSlot       0
set iPort       0

set iHub2       0
set iSlot2      1
set iPort2      0 

set NUM_FRAMES 12
set DATA_LENGTH 60
set NUM_VIEW_CAP_FRAMES 8
set DISPLAY_LINES 3

# Reserve cards 
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Reset cards 
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

# Create data structures
struct_new capCount NSCaptureCountInfo
struct_new capData NSCaptureDataInfo

# Create SmartBits stream
struct_new SB StreamSmartBits

set SB(ucActive)  [format %c 1]
set SB(ucProtocolType) [format %c $STREAM_PROTOCOL_SMARTBITS]
set SB(ucRandomLength) [format %c 0]
set SB(ucRandomData) [format %c 0]
set SB(uiFrameLength) $DATA_LENGTH

set SB(uiVFD3Offset) 96
set SB(uiVFD3Range) 48
set SB(ucVFD3Enable) $HVFD_ENABLED

set SB(ucTagField) [format %c 1]
# Set Ethertype to 0800
set SB(ProtocolHeader.0.uc) [format %c 0x08]
set SB(ProtocolHeader.1.uc) [format %c 0x00]

# Set rest of VFD3 pattern as incrementing bytes
for {set i 2} {$i < $DATA_LENGTH} {incr i } {
      set SB(ProtocolHeader.$i.uc) [format %c $i]
}

#Set the L3_DEFINE_SMARTBITS_STREAM
LIBCMD HTSetStructure $L3_DEFINE_SMARTBITS_STREAM 0 0 0 SB 0 $iHub $iSlot $iPort

#Unset the structure
unset SB

# setup transmit
#LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTTransmitMode $CONTINUOUS_PACKET_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $NUM_FRAMES $iHub $iSlot $iPort
LIBCMD HTDataLength $DATA_LENGTH $iHub $iSlot $iPort

##################################################################
# fill in background data                                        #
# - Anything not overwritten by stream data will have background #
##################################################################

struct_new filldata Int*$DATA_LENGTH

for {set i 0} {$i < $DATA_LENGTH} {incr i} {
      set filldata($i.i) 0xAA
}

#Set the pattern on the card
LIBCMD HTFillPattern $DATA_LENGTH filldata $iHub $iSlot $iPort


# Capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $iHub2 $iSlot2 $iPort2
unset cap

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $iHub2 $iSlot2 $iPort2

#Pause for 2 seconds
after 2000

# Send data for two seconds
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

#Pause for 2 seconds
after 2000

#Start transmitting 
LIBCMD HTRun $HTSTOP $iHub $iSlot $iPort

# Get the count of captured frames
LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 capCount 0 $iHub2 $iSlot2 $iPort2

puts "Capture count = $capCount(ulCount)"

# Get the captured data
if {$capCount(ulCount) < $NUM_VIEW_CAP_FRAMES} {
     set iNumView $capCount(ulCount)
} else {
         set iNumView $NUM_VIEW_CAP_FRAMES
}

#Get the packet data info and display it 
for {set i 0} {$i < $iNumView} {incr i} {

      puts ""
      puts "---------"
      puts "FRAME $i"
      puts "---------"
      set capData(ulFrameIndex)      $i
      set capData(ulRequestedLength)      [expr $DATA_LENGTH + 4]
      LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 capData 0 $iHub2 $iSlot2 $iPort2
      for {set j 0} {$j < $capData(ulRetrievedLength)} {incr j} {

            #set iData 0, print 0..16..32..
            if {[expr $j % 16] == 0} {
                 puts ""
                 puts -nonewline [format "%4i:   " $j]
            }
 
            #Convert from character to integer
            set MYByte [ConvertCtoI $capData(ucData.$j.uc)]
            puts -nonewline " [format %02X $MYByte] "       
       }

       puts ""

       #Display the the frames
       if {[expr $i % $DISPLAY_LINES] == 0 } {
            puts ""
            puts "Press RETURN key for more"
            gets stdin response
       }

}


# free data structures
unset capCount
unset capData
unset filldata

#UnLinking the chassis.
puts "UnLinking the chassis now..."
ETUnLink
puts ""
puts "DONE!"






