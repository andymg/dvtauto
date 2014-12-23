#######################################################################
# l3_sb.tcl                                                           #
#                                                                     #
# - Tranmits for three seconds then displays the number of            #
#   frames specified by NUM_VIEW_CAP_FRAMES, and it displays          #
#   DISPLAY_LINES per screen.                                         #
#                                                                     #
# NOTE: This script works on the following cards:                     #
#       - L3-67XX                                                     #
#       - ML-7710                                                     #
#       - ML-5710                                                     #
#       - LAN-6101A                                                   #
#                                                                     #
#######################################################################

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
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]  
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit
     }
}


set iHub        0
set iSlot       0
set iPort       0

set iHub2       0
set iSlot2      1
set iPort2      0 

set numFrames 5
set dataLength 128
###########################################################################################
# Reset cards                                                                             #
###########################################################################################
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

LIBCMD HTResetPort $::RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $::RESET_FULL $iHub2 $iSlot2 $iPort2	

###########################################################
# initialize streams                                      #
###########################################################

struct_new SB StreamSmartBits

set SB(ucActive)  1
set SB(ucProtocolType) $STREAM_PROTOCOL_SMARTBITS
set SB(ucRandomLength) 0
set SB(ucRandomData)   0
set SB(uiFrameLength)  $dataLength

# set protocol data to start 96 bits into packet (after source MAC)
set SB(uiVFD3Offset) 96

# protocol data 48 bytes long (max is 64 bytes)
set SB(uiVFD3Range) 48
set SB(ucVFD3Enable) $HVFD_ENABLED
set SB(ucTagField) 1

# Set Ethertype to 0800
set SB(ProtocolHeader.0) 0x08
set SB(ProtocolHeader.1) 0x00

# Set rest of VFD3 pattern as incrementing bytes
   for {set i 2} {$i < 48} {incr i } {
         set SB(ProtocolHeader.$i) $i
   }

LIBCMD HTSetStructure $L3_DEFINE_SMARTBITS_STREAM 0 0 0 SB 0 $iHub $iSlot $iPort

unset SB

###########################################################
# setup transmit                                          #
###########################################################

LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $numFrames $iHub $iSlot $iPort
LIBCMD HTDataLength $dataLength $iHub $iSlot $iPort

####################################################################
# Fill in background data                                          #
#                                                                  #
# - Since the stream protocol data starts at byte 13, we use the   #
#   background fill to create the MAC addresses.  The rest of the  #
#   packet is filled with 5A                                       #
####################################################################

struct_new filldata Int*$dataLength

# set destination MAC to broadcast
for {set i 0} {$i < 6} {incr i} {
      set filldata($i) 0xFF
}

# set source MAC to 00 00 00 AA BB 00
set filldata(6) 0x00
set filldata(7) 0x00
set filldata(8) 0x00
set filldata(9) 0xAA
set filldata(10) 0xBB
set filldata(11) 0x00

# fill remainder of packet with 5A
for {set i 12} {$i < $dataLength} {incr i} {
      set filldata($i) 0x5A
}

#Fill the pattern
LIBCMD HTFillPattern $dataLength filldata $iHub $iSlot $iPort

unset filldata

# Capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $iHub2 $iSlot2 $iPort2
unset cap

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $iHub2 $iSlot2 $iPort2
after 2000

# send data
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
after 2000
LIBCMD HTRun $HTSTOP $iHub $iSlot $iPort

# stop capture
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2

# get capture count
struct_new capCount NSCaptureCountInfo
struct_new capData NSCaptureDataInfo

LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 capCount 0 $iHub2 $iSlot2 $iPort2
puts "Capture count = $capCount(ulCount)"

# get capture data
for {set i 0} {$i < $capCount(ulCount)} {incr i} {

         puts ""
         puts "---------"
         puts "FRAME $i"
         puts "---------"
         set capData(ulFrameIndex)      $i
         LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 capData 0 $iHub2 $iSlot2 $iPort2
         for {set j 0} {$j < [expr $dataLength + 4]} {incr j} {
         set iData 0
                  if {[expr $j % 16] == 0} {
                        puts ""
                        puts -nonewline [format "%4i:   " $j]
                  }
                  puts -nonewline " "
                  puts -nonewline " [format "%02X" $capData(ucData.$j._ubyte_)]"                            
         }
         puts ""
         puts "\nPress RETURN key for more"
         gets stdin response

}


# free data structures
unset capCount
unset capData

puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"






