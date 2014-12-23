########################################################################
# L3_HIST_RAW_TAGS.TCL                                                 #
#                                                                      #
# - This program creates IP_Streams,                                   #
# _ Uses L3_DEFINE_IP_STREAM to set the stream on the card             #
# - Then uses L3_DEFINE_MULTI_IP_STREAM to create multiple streams     #
# - Sets the SourceMac to increment by 5                               #
# - Sets the SourceIP to increment by 3                                #
# - Displays the number of streams on the card                         #
# - Uses L3_HIST_RAW_TAGS to place tags on the card                    #
# - Adds the transmitting and the recieving card in a group using      #
#   HGSetGroup                                                         #
#   Then transmit a burst of packets                                   #
# - Gets the raw tag info using L3_HIST_RAW_TAGS_INFO                  #
# - And displays Tx time, RX time and latency from TX to RX in us      #      
#                                                                      #
# NOTE: If you need to pass data through a router you                  #
#       will need to set the card parameters.                          #
#                                                                      #
# NOTE: This script works on the following cards:                      #
#       - L3-67XX                                                      #
#       - ML-7710                                                      #
#       - ML-5710                                                      #
#       - LAN-6101A                                                    #
#       - LAN-3300A                                                    #
#       - LAN-3310                                                     #
#       - POS-6500A                                                    #
#       - POS-3305                                                     #
#                                                                      #
########################################################################


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

# Set Variables
set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

set BURST_SIZE 30
set NUM_STREAMS 10
set DATA_LENGTH 60

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

#Create a new structure
struct_new streamIP StreamIP

#Create new streams
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

#Set the streams on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#UnSet the structure
unset streamIP

#Create a new structure
struct_new incrementIP StreamIP

#Increment the streams source MAC address by 5
set incrementIP(SourceMAC.5.uc) [format %c 1]

#Increment the sources IP address by 3
set incrementIP(SourceIP.3.uc) [format %c 1]

#Set multiple streams of L3_DEFINE_IP_STREAM
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $NUM_STREAMS - 1] 0 incrementIP 0 $iHub $iSlot $iPort

#Unset the structure
unset incrementIP

########################################################################################
# Check for L3 streams.                                                                #
# - Test will not work if there are no streams transmitting.                           #
# - The DEFINED_STREAM_COUNT will return the total stream count (including the first,  #
#   hidden stream, so we have to adjust the count to show the count of transmitting    #
#   streams.                                                                           #
########################################################################################

#Create a new structure
struct_new StreamCount  ULong

#Get the number of streams on the card
LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort

#Put the number of streams on the card in TXStreams
set TXStreams $StreamCount(ul)

#If there are no streams on the card, exit out of the program
if {  $TXStreams < 1 } {
     puts "No L3 streams on card - Aborting Test!"
     exit
} else {
         #If there are streams on the card, output the number of streams you are testing with.
         puts "Testing with [expr $StreamCount(ul) - 1] streams"
}

#Unset the structure
unset StreamCount

# Set L3_HIST_RAW_TAGS (no related structure)
LIBCMD HTSetCommand $L3_HIST_RAW_TAGS 0 0 0 "" $iHub2 $iSlot2 $iPort2

# Add the transmitting - TX and the receiving RX card in a group        
# HGSetGroup "[expr $iSlot + 1] - [expr $iSlot2 + 1]"
HGSetGroup 1-2
HGStop

# Send a single burst of $BURST_SIZE packets. Card 1 is Tx 
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

#Pause for 1 second
after 1000

##############################################################
# - Create structure to hold the tag data and                #
# - Get the data from the Rx card, Card2.                    #
#   One structure per tag.                                   #
##############################################################

#Create a new structure
struct_new MyL3HistTagInfo Layer3HistTagInfo*$BURST_SIZE

#Get the raw tag info
LIBCMD HTGetStructure $L3_HIST_RAW_TAGS_INFO 0 $TXStreams 0 MyL3HistTagInfo 0 $iHub2 $iSlot2 $iPort2

#Display the transmitting and recieving time
for {set i 0} {$i < $BURST_SIZE} {incr i} {
	puts "Stream $MyL3HistTagInfo($i.ulStream)"
	puts "  TX time  $MyL3HistTagInfo($i.ulTransmitTime)"
	puts "  RX time  $MyL3HistTagInfo($i.ulReceiveTime)"
	puts "Latency TX to RX is [expr $MyL3HistTagInfo($i.ulReceiveTime) - $MyL3HistTagInfo($i.ulTransmitTime)] 1/10 uS"
	puts ""
}

#Unset the structure
unset MyL3HistTagInfo


#Unlink from the chassis
puts "Unlinking from the chassis now"
LIBCMD NSUnLink
puts "DONE!"
