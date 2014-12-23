###########################################################################################
# l3min.tcl                                                                               #
#                                                                                         #
# - This program, transmits for three seconds, then displays the number of frames         #
#   specified by NUM_VIEW_CAP_FRAMES, and then displays "DISPLAY_LINES" per screen.       #
# - Demonstrates the use of:                                                              #
#   - L3_DEFINE_IP_STREAM                                                                 #
#   - L3_DEFINE_MULTI_IP_STREAM                                                           #
#   - L3_START_ARPS                                                                       #
#   - NS_CAPTURE_SETUP                                                                    #
#   - NS_CAPTURE_START                                                                    #
#   - NS_CAPTURE_STOP                                                                     #
#   - NS_CAPTURE_COUNT_INFO                                                               #
#   - NS_CAPTURE_DATA_INFO                                                                #
# - The layer 3 parameters on the card, as shown in L3stack.tcl, would have to be         #
#   set to correspond to the router ports before you could send data through a            #
#   layer 3 device.                                                                       #
#                                                                                         #
# NOTE: This script runs on the following cards:                                          #
#       - L3-67XX                                                                         #
#       - ML-7710                                                                         #
#       - ML-5710                                                                         #
#       - LAN-6101A                                                                       #
#       - LAN-3300A / 3301A                                                               #
#                                                                                         #
###########################################################################################


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

#Set the defaults values
set iHub        0
set iSlot       0
set iPort       0

set iHub2       0
set iSlot2      1
set iPort2      0 

set NUM_STREAMS 5
set NUM_FRAMES 33
set DATA_LENGTH 60
set NUM_VIEW_CAP_FRAMES 8
set DISPLAY_LINES 3

# Create the data structures
struct_new capCount NSCaptureCountInfo
struct_new capData NSCaptureDataInfo

# Reserve cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Reset cards
LIBCMD HTResetPort $::RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $::RESET_FULL $iHub2 $iSlot2 $iPort2	

# Create a structure and then create streams
struct_new streamIP StreamIP

set streamIP(ucActive) [format %c 1]
set streamIP(ucProtocolType) [format %c $L3_STREAM_IP]
set streamIP(uiFrameLength) $DATA_LENGTH
set streamIP(ucRandomLength) [format %c 1]
set streamIP(ucTagField) [format %c 1]
set streamIP(DestinationMAC.0.uc) [format %c 0]
set streamIP(DestinationMAC.1.uc) [format %c 0]
set streamIP(DestinationMAC.2.uc) [format %c 0]
set streamIP(DestinationMAC.3.uc) [format %c 0]
set streamIP(DestinationMAC.4.uc) [format %c 1]
set streamIP(DestinationMAC.5.uc) [format %c 0]
set streamIP(SourceMAC.0.uc) [format %c 0]
set streamIP(SourceMAC.1.uc) [format %c 0]
set streamIP(SourceMAC.2.uc) [format %c 0]
set streamIP(SourceMAC.3.uc) [format %c 0]
set streamIP(SourceMAC.4.uc) [format %c 0]
set streamIP(SourceMAC.5.uc) [format %c 1]
set streamIP(TimeToLive) [format %c 10]
set streamIP(DestinationIP.0.uc) [format %c 192]
set streamIP(DestinationIP.1.uc) [format %c 158]
set streamIP(DestinationIP.2.uc) [format %c 100]
set streamIP(DestinationIP.3.uc) [format %c 1]
set streamIP(SourceIP.0.uc) [format %c 192]
set streamIP(SourceIP.1.uc) [format %c 148]
set streamIP(SourceIP.2.uc) [format %c 100]
set streamIP(SourceIP.3.uc) [format %c 1]
set streamIP(Protocol) [format %c 4]

#Create the L3_DEFINE_IP_STREAM
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Unset the structure
unset streamIP

#Create a new structure for the StreamIP and set the stream
struct_new incrementIP StreamIP

set incrementIP(SourceMAC.5.uc) [format %c 1]
set incrementIP(SourceIP.3.uc) [format %c 1]

#Create the L#_DEFINE_MULIT_IP_STREAM 
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $NUM_STREAMS - 1] 0 incrementIP 0 $iHub $iSlot $iPort

#Unset the structure
unset incrementIP

# Begin ARP exchange on all defined streams
LIBCMD HTSetCommand $L3_START_ARPS 0 0 0 "" $iHub $iSlot $iPort
LIBCMD HTSetCommand $L3_START_ARPS 0 0 0 "" $iHub2 $iSlot2 $iPort2

# Transmit setup - sets to send a single burst of $NUM_FRAMES packets
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $NUM_FRAMES $iHub $iSlot $iPort
LIBCMD HTDataLength $DATA_LENGTH $iHub $iSlot $iPort

# Fill in background data with AA
struct_new filldata Int*$DATA_LENGTH

for {set i 0} {$i < $DATA_LENGTH} {incr i} {
      set filldata($i.i) 0xAA
}

#Fill in background data 
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

# Transmit data
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

#Pause for 2 seconds
after 2000

#Stop transmitting data
LIBCMD HTRun $HTSTOP $iHub $iSlot $iPort

# Stop capture
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2

# Get the count of captured frames
LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 capCount 0 $iHub2 $iSlot2 $iPort2
puts "Capture count = $capCount(ulCount)"

# Get the captured data
if {$capCount(ulCount) < $NUM_VIEW_CAP_FRAMES} {
     set iNumView $capCount(ulCount)
} else {
         set iNumView $NUM_VIEW_CAP_FRAMES
}

for {set i 0} {$i < $iNumView} {incr i} {

      puts ""
      puts "---------"
      puts "FRAME $i"
      puts "---------"
 
      #Get the captured frame
      set capData(ulFrameIndex)      $i
      set capData(ulRequestedLength)      [expr $DATA_LENGTH + 4]
      LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 capData 0 $iHub2 $iSlot2 $iPort2      
      #for {set j 0} {$j < [expr $DATA_LENGTH + 4]} {incr j} {}
      for {set j 0} {$j < $capData(ulRetrievedLength)} {incr j} {
	    if {[expr $j % 16] == 0} {
	         puts ""
		 puts -nonewline [format "%4i:   " $j]
	    }
		
            set iData [ConvertCtoI $capData(ucData.$j.uc)]
	    puts -nonewline [format " %02X" $iData]
	}

	puts "" 

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

#UnLink from the chassis
puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"




