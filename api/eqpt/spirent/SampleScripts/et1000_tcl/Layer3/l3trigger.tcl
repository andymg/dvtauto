################################################################################
# L3Trigger.tcl                                                                #
#                                                                              #
# - Demonstrates the use of triggers on layer 3 cards.                         #
#                                                                              #
# - Sets of 25 streams and then changes the pattern of the first two bytes.    #  
# - Sets a trigger to match one of the patterns.                               #
# - Sets up caounters to show Tx and Rx packets and received triggers then     #
# - follows with a capture display of the first few packets.                   #
#                                                                              #
# - Program can be modified to change the trigger length, pattern or offset    #
#   and the capture paramters can be changed to capture all or on triggers     #
#                                                                              #
# NOTE: This script works on the following cards:                              #                            
#       - L3-67XX                                                              #
#       - ML-7710                                                              #
#       - ML-5710                                                              #
#       - LAN-6101A                                                            #
#       - LAN-3300A/3301A                                                      #
#       - LAN-3310A/3311A                                                      #
#                                                                              #
################################################################################ 

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

# Declare the default variables
set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 1
set iPort2 0

set DATA_LENGTH 98
set SOURCE_STREAM 1
set NUM_STREAMS 5
set BURST_SIZE 25
set DISPLAY_COUNT 5

# RESERVE CARDS 
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# RESET CARDS 
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

#Pause for 1 sec
after 1000

#####################################################################
# Show_packet                                                       #
# - Displays the contents of NUM_PACKETS formatted in readable form #
#####################################################################

proc show_packet { NUM_PACKETS } {

global iHub2 iSlot2 iPort2 DATA_LENGTH NS_CAPTURE_DATA_INFO

struct_new capData NSCaptureDataInfo

for {set i 0} {$i < $NUM_PACKETS} {incr i} {

      set capData(ulFrameIndex)       $i
      set capData(ulRequestedLength)  [expr $DATA_LENGTH + 4]
      LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 capData 0 $iHub2 $iSlot2 $iPort2

      for {set j 0} {$j < $capData(ulRetrievedLength)} {incr j} {
            set iData 0
            if {[expr $j % 16] == 0} {
                 puts ""
                        puts -nonewline [format "%4i:   " $j]
            }
            if {$capData(ucData.$j.uc) == 0} {
                 set iData 0
            } else {
                      scan $capData(ucData.$j.uc) %c iData
                   }
                     puts -nonewline " "
                     puts -nonewline [format "%02X" $iData]
                                   
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

#Unset the structure
unset capData

}



#################
# Layer 3 setup #                    
#################

#Create new base stream
struct_new streamIP StreamIP

        set streamIP(ucActive) [format %c 1]
        set streamIP(ucProtocolType) [format %c $L3_STREAM_IP]
        set streamIP(uiFrameLength) $DATA_LENGTH
        set streamIP(ucTagField) [format %c 1]
        set streamIP(DestinationMAC.0.uc) [format %c 0x22]
        set streamIP(DestinationMAC.1.uc) [format %c 0x33]
        set streamIP(DestinationMAC.2.uc) [format %c 0x44]
        set streamIP(DestinationMAC.3.uc) [format %c 0x55]
        set streamIP(DestinationMAC.4.uc) [format %c 0x66]
        set streamIP(DestinationMAC.5.uc) [format %c 0x77]
	set streamIP(SourceMAC.0.uc) [format %c 0x00]
        set streamIP(SourceMAC.1.uc) [format %c 0x99]
        set streamIP(SourceMAC.2.uc) [format %c 0x88]
        set streamIP(SourceMAC.3.uc) [format %c 0x77]
        set streamIP(SourceMAC.4.uc) [format %c 0x66]
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
        set streamIP(Netmask.0.uc) [format %c 255]
        set streamIP(Netmask.1.uc) [format %c 255]
        set streamIP(Netmask.2.uc) [format %c 255]
        set streamIP(Netmask.3.uc) [format %c 0]
        set streamIP(Gateway.0.uc) [format %c 192]
        set streamIP(Gateway.1.uc) [format %c 148]
        set streamIP(Gateway.2.uc) [format %c 100]
        set streamIP(Gateway.3.uc) [format %c 1]

#Sending streams to card will set it in layer 3 mode
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Unset the structure
unset streamIP

####################################################################################################
# Create additional streams                                                                        #
# - Set value will be the increment against the value in the base stream, i.e                      #
#   - The second and last byte of the Destination MAC will increment by 1 each time                #
#     and the last (LSB) byte of the source MAC will increment by two for each new stream created. #
####################################################################################################

struct_new incrementIP StreamIP

	set incrementIP(DestinationMAC.1.uc) [format %c 1]
        set incrementIP(DestinationMAC.5.uc) [format %c 1]
        set incrementIP(SourceMAC.5.uc) [format %c 2]

#Set up multiple streams on the card
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM $SOURCE_STREAM $NUM_STREAMS 0 incrementIP 0 $iHub $iSlot $iPort

#Unset the structure
unset incrementIP

puts ""
puts ""

#Pause for 1 second
after 1000

# Set a group
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub $iSlot2 $iPort
after 1000

#Transmit packets
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort

##########################################################################################################
#Set trigger                                                                                             #
# - Setting offset to 0 bits and setting the Range to 2 will trigger on the first two bytes (MSB)        #
#   of the Destination MAC.                                                                              #
# - Note that the LSB of the trigger is always Pattern.0, so this combination will trigger whenever      #
#   the first two bytes are 22 33.                                                                       #
# - Since we have five streams with an increment on the second byte we will trigger on every             #
#   5th packet transmitted.                                                                              #
##########################################################################################################

struct_new MyTrigger HTTriggerStructure

set MyTrigger(Offset) 0
set MyTrigger(Range) 2
set MyTrigger(Pattern.0) 0x33
set MyTrigger(Pattern.1) 0x22

#Trigger On
LIBCMD HGTrigger $HTTRIGGER_1 $HTTRIGGER_ON MyTrigger

#Unset the structure
unset MyTrigger

# Capture setup
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
##################################################################################
# - The ulCaptureEvents will set capture to capture all packets or just the ones #
#   that match our trigger.                                                      #
# - If use CAPTURE_EVENTS_RX_TRIGGER, only the frames that match our trigger     #
#   will be captured                                                             #
# - If use CAPTURE_EVENTS_ALL_FRAMES, all frames will be captured all;           #
# - To capture all the frames, comment out the CAPTURE_EVENTS_ALL_FRAMES line    #
#   and remove the comment from the capture CAPTURE_EVENTS_RX_TRIGGER line.      #
##################################################################################
#Capture all packets...
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
#...or only capture triggers
#set cap(ulCaptureEvents) $::CAPTURE_EVENTS_RX_TRIGGER

LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $iHub2 $iSlot2 $iPort2
after 2000

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $iHub2 $iSlot2 $iPort2

# Send a burst from card 1
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

after 2000
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2

# Get and display counter data
struct_new cs HTCountStructure*2

after 1000
HGGetCounters cs
after 2000
puts "     *****************************************************"
puts "                          COUNTER DATA"
puts "     *****************************************************"
puts "     Card $iSlot Tx Pkts $cs(0.TmtPkt)"
puts "         			Card $iSlot2 Rx Pkts 	   $cs(1.RcvPkt)"
puts "	       			Card $iSlot2 Rx Triggers $cs(1.RcvTrig)"
puts "     *****************************************************" 
puts ""
puts ""
puts ""


# Get and display captured data
struct_new MyCaptureCount NSCaptureCountInfo
LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 MyCaptureCount 0 $iHub2 $iSlot2 $iPort2

#Get the count
set cap_count $MyCaptureCount(ulCount)

#Unset the structure
unset MyCaptureCount

if {$cap_count > 0} {
     puts "Captured $cap_count frames"
     puts "Press ENTER key to display the first $DISPLAY_COUNT frames"

     gets stdin response
     puts ""
     puts "Layer 3 Packet Capture"

     if { $cap_count < $DISPLAY_COUNT } {
         set  DISPLAY_COUNT $cap_count
     }

     show_packet $DISPLAY_COUNT

} else {
         puts "                  **************************"
         puts "	              No frames captured"
         puts "                  **************************"
}

#Unset the structure
unset cs

#UnLink from the chassis
puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"
