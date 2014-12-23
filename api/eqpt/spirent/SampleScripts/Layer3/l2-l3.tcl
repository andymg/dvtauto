################################################################################################
# L2-L3.tcl                                                                                    #
#                                                                                              #
# - Demonstrates the process of switching from L2 to L3 on a 7710 card                         #
# - Creating any stream with NULL as the structure will switch to Layer 2 mode                 #
# - Creating L3 streams switches to L3 mode                                                    #
#                                                                                              #
# - A procedure show_packet is used to display the contents of the packets                     #
#   to show the mode is changing from L2 to L3                                                 #
#                                                                                              #
# - In L2 mode the packets with VFD data (in this example, the Destination MAC                 #
#   is set to all 2's) are transmitted.  In L3 mode, the streams on the card (in this          #
#   example, with the MAC address as all 3's.                                                  #
#                                                                                              #
# - In L2 mode the 2's packets are sent.  In L3 mode the 3's packets are sent                  #
#                                                                                              #
# - Switching modes will undo other transmission parameters such as Transmit mode              #
#   so they must be reset after mode switch.  This is why HTTransmitMode and HTBurstCount      #
#   are invoked before each HTRun command.                                                     #
#                                                                                              #
# NOTE: This script works on the following cards:                                              #
#       - L3-67XX                                                                              #
#       - ML-7710                                                                              #
#       - ML-5710                                                                              #
#       - LAN-6101A                                                                            #
#                                                                                              # 
################################################################################################ 

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


set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 1
set iPort2 0

set DATA_LENGTH 60
set BURST_SIZE 5

# RESERVE CARDS
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# RESET CARDS 
LIBCMD HTResetPort $::RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $::RESET_FULL $iHub2 $iSlot2 $iPort2	
after 1000

########################################################################
# Show_packet                                                          #
# - Displays the contents of NUM_PACKETS formatted in readable form    #
########################################################################
proc show_packet { NUM_PACKETS } {

global iHub2 iSlot2 iPort2 DATA_LENGTH NS_CAPTURE_DATA_INFO

after 2000
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2

struct_new capData NSCaptureDataInfo
for {set i 0} {$i < $NUM_PACKETS} {incr i} {
         set capData(ulFrameIndex)      $i
         LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 capData 0 $iHub2 $iSlot2 $iPort2
         for {set j 0} {$j < [expr $DATA_LENGTH + 4]} {incr j} {
         set iData 0
                  if {[expr $j % 16] == 0} {
                        puts ""
                        puts -nonewline [format "%4i:   " $j]
		   }
         puts -nonewline " "
         puts -nonewline " [format "%02X" $capData(ucData.$j._ubyte_)]" 
         }
         puts ""
	 if {$i < [expr $NUM_PACKETS - 1]} {
	 puts ""
	 puts "Press ENTER to display packet [expr $i + 2]"
	 gets stdin response
	 } else {
	 puts "End of captured data!"
	 }
 }
unset capData
}


# Reset_capture   start capture
proc reset_capture { } {

global iHub2 iSlot2 iPort2 NS_CAPTURE_SETUP NS_CAPTURE_START

# Capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $iHub2 $iSlot2 $iPort2
unset cap

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $iHub2 $iSlot2 $iPort2
}


########################################################################
# Layer 2 setup                                                        #
# - using NULL as structure reference will set card to layer 2 mode    #
# - We know it's an L2 frame because the Dest MAC is all 2's           #
########################################################################

LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 NULL 0 $iHub $iSlot $iPort
puts "      #####################################"
puts "      ##        LAYER 2 MODE             ##"
puts "      ##   Destination MAC is all 2's    ##"
puts "      #####################################"
reset_capture

# Set Layer 2 VFD on first six bytes
struct_new vfdstruct HTVFDStructure
set vfdstruct(Configuration) $HVFD_STATIC
set vfdstruct(Range) 6
set vfdstruct(Offset) 0

struct_new vfd1Data Int*6
	set vfd1Data(0.i) 0x22
	set vfd1Data(1.i) 0x22
	set vfd1Data(2.i) 0x22
	set vfd1Data(3.i) 0x22
	set vfd1Data(4.i) 0x22
	set vfd1Data(5.i) 0x22

set vfdstruct(Data) vfd1Data
set vfdstruct(DataCount) 10
LIBCMD HTVFD $HVFD_1 vfdstruct $iHub $iSlot $iPort
unset vfd1Data
unset vfdstruct

#send one burst
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
puts ""
puts "Layer 2 Packet Capture"
show_packet $BURST_SIZE

#####################################################
# Layer 3 setup                                     #
# Set up layer 3 stream with first 6 bytes all 3    #
#####################################################
puts "      #####################################"
puts "      ##        LAYER 3 MODE             ##"
puts "      ##   Destination MAC is all 3's    ##"
puts "      #####################################"
reset_capture



#sending streams to card will set it in layer 3 mode
puts ""

LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $iHub $iSlot $iPort \
-ucActive       1 \
-ucTagField     1 \
-uiFrameLength  $DATA_LENGTH \
-TimeToLive     10 \
-DestinationMAC {0x33 0x33 0x33 0x33 0x33 0x33} \
-SourceMAC      {0x00 0x00 0x00 0x00 0x00 0x01} \
-DestinationIP  {192 158 100 1} \
-SourceIP       {192 148 100 1} \
-Netmask        {255 255 255 0} \
-Gateway        {192 148 100 1}

puts "Creating layer 3 stream"

puts "done!"
after 1000


# send mode and send a burst
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
puts ""
puts "Layer 3 Packet Capture"
show_packet $BURST_SIZE

###################################
# Back to Layer 2                 #
###################################
puts "      #####################################"
puts "      ##      LAYER 2 MODE AGAIN         ##"
puts "      ##   Destination MAC is all 2's    ##"
puts "      #####################################"
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 NULL 0 $iHub $iSlot $iPort
puts "Back to Layer 2"

reset_capture

#send one burst
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
puts ""
puts "Layer 2 Packet Capture"
show_packet $BURST_SIZE

puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"
