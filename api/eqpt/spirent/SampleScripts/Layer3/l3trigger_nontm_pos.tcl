##################################################################################
# l3trigger_nontm_pos.tcl                                                        #
#                                                                                #
# Demonstrates the use of triggers on layer 3 cards.                             #
#                                                                                #
# Sets of 30 streams and then changes the pattern of the first two bytes.        #
# Sets a trigger to match one of the patterns.                                   #
# Sets up caounters to show Tx and Rx packets and received triggers then         #
# follows with a capture display of the first few packets.                       #
#                                                                                #
# Program can be modified to change the trigger length, pattern or offset        #
# and the capture paramters can be changed to capture all or on triggers         #
#                                                                                #
# NOTE: This script works on the following scripts:                              #
#       - POS-3500/3502                                                          #
#         The trigger counter in HGGetCounters not work for these two cards      #
#             so that the trigger counter is always zero - which is not correct  #
#         But trigger capture (CAPTURE_EVENTS_RX_TRIGGER in NS_CAPTURE_SETUP)    #
#             works for these two cards so that user can do trigger capture      #
#             with them                                                          #
#                                                                                #
################################################################################## 

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

set DATA_LENGTH 98
set SOURCE_STREAM 1
set NUM_STREAMS_ADDED 5
set BURST_PER_STREAM 5
set DISPLAY_COUNT 5

# RESERVE CARDS 
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# RESET CARDS 
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

#####################################################################
# show_packet                                                       #
# displays the contents of NUM_PACKETS formatted in readable form   #
#####################################################################

proc show_packet { NUM_PACKETS } {

global iHub2 iSlot2 iPort2 DATA_LENGTH NS_CAPTURE_DATA_INFO

struct_new capData NSCaptureDataInfo

for {set i 0} {$i < $NUM_PACKETS} {incr i} {
      set capData(ulFrameIndex)      $i
      set capData(ulRequestedLength)      [expr $DATA_LENGTH + 4]
      LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 capData 0 $iHub2 $iSlot2 $iPort2

      for {set j 0} {$j < $capData(ulRetrievedLength)} {incr j} {
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

#Unset the structure
unset capData

}


#####################################################
# Layer 3 setup                                     #
#####################################################
 
# create new base stream
#sending streams to card will set it in layer 3 mode
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $iHub $iSlot $iPort \
-ucActive        1 \
-ucProtocolType  $L3_STREAM_IP \
-uiFrameLength   $DATA_LENGTH \
-ucTagField      1 \
-TimeToLive      10 \
-SourceIP        {0x22 0x33 0x44 0x55} \
-DestinationIP   {0x00 0x99 0x88 0x77} \
-Netmask         {255 255 255 0} \
-Gateway         {192 148 100 1}

#create additional streams
# set value will be the increment against the value in the 
# base stream, that is the second and 4th byte of the Source IP
# will increment by 1 each time and the last (LSB) byte of the
# destination IP will increment by two for each new stream created.

struct_new ip StreamIP
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM $SOURCE_STREAM $NUM_STREAMS_ADDED 0 ip 0 $iHub $iSlot $iPort \
-SourceIP           {0 1 0 1} \
-DestinationIP      {0 0 0 2}
puts ""
puts ""
unset ip

#Set transmit parameters for the first stream
LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 - 0 $iHub $iSlot $iPort \
-ulFrameRate        100 \
-ulTxMode           $L3_SINGLE_BURST_MODE \
-ulBurstCount   $BURST_PER_STREAM \
-ulBurstGap      96 

#Set transmit parameters for other streams based on the first stream - base stream
# set value will be the increment against the value in the 
# base stream, that is the frame rate will increment by one
# for each new stream created.

struct_new ext L3StreamExtension
LIBCMD HTSetStructure $L3_DEFINE_MULTI_STREAM_EXTENSION $SOURCE_STREAM $NUM_STREAMS_ADDED 0 ext 0 $iHub $iSlot $iPort \
-ulFrameRate        0 \
-ulBurstCount       0 \
-ulBurstGap         0 
unset ext

puts ""
puts ""
after 1000


# set a group
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2
#LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
#LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort

#############################################################################
#Set trigger                                                                #
#                                                                           #
# - Setting offset to 16*8 bits and setting the Range to 2                  #
#   will trigger on the first two bytes (MSB) of the Source IP              #
#                                                                           #
# - Note that the LSB of the trigger is always Pattern.0, so this           #
#   combination will trigger whenever the first two bytes are 22 33.        #
# - Since we have five streams with an increment on the second byte         #
#   we will trigger on every 6th packet transmitted.                        #
#############################################################################

struct_new MyTrigger HTTriggerStructure

set MyTrigger(Offset) [expr 16*8]
set MyTrigger(Range) 2
set MyTrigger(Pattern.0) 0x33
set MyTrigger(Pattern.1) 0x22
LIBCMD HGTrigger $HTTRIGGER_1 $HTTRIGGER_ON MyTrigger
unset MyTrigger

# Capture set up
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
#set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
#...or only capture triggers
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_RX_TRIGGER

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
LIBCMD HGGetCounters cs
after 2000
puts "     *****************************************************"
puts "                          COUNTER DATA"
puts "     *****************************************************"
puts "     Card $iSlot Tx Pkts $cs(0.TmtPkt)"
puts "         			Card $iSlot2 Rx Pkts 	   $cs(1.RcvPkt)"
;#puts "	       			Card $iSlot2 Rx Triggers $cs(1.RcvTrig)"
puts "     *****************************************************" 
puts ""
puts ""
puts ""

# Get and display captured data
struct_new MyCaptureCount NSCaptureCountInfo
LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 MyCaptureCount 0 $iHub2 $iSlot2 $iPort2

set cap_count $MyCaptureCount(ulCount)
unset MyCaptureCount

if { $cap(ulCaptureEvents) == $::CAPTURE_EVENTS_ALL_FRAMES } {
   puts "capturing all the frames"
} elseif { $cap(ulCaptureEvents) == $::CAPTURE_EVENTS_RX_TRIGGER } {
   puts "capturing the trigger frames only"
} else {
   puts "other capture event chosen by user"
}

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

puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"
