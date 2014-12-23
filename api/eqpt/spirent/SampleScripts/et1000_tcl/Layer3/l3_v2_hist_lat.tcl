################################################################################################
# L3_V2_HIST_LAT.TCL                                                                           #
#                                                                                              #
# - This program sets up a series of streams (externally by sourcing ipstream.tcl)             #
# - Transmits a burst of packets                                                               #
# - Displays the distribution.                                                                 #
#                                                                                              #
# ASSUMES:                                                                                     #
# - L3 cards are in slots 1 and 2 and are hooked back to back.                                 #
# - Ipstream.tcl is local                                                                      #
#                                                                                              #
# NOTE: If you need to pass data through a router you will need to set the card                #
#       parameters with a program such as the L3Stack program.                                 #
#                                                                                              #
# NOTE: This script works on the following cards:                                              #
#       - L3-67XX                                                                              #
#       - ML-7710                                                                              #
#       - ML-5710                                                                              #
#       - LAN-6101A                                                                            #
#       - LAN-3300A / 3301A                                                                    #
#       - LAN-3310 / 3311A                                                                     #
#       - POS-3505A / 3504A                                                                    #
#       - POS-6500 / 6502                                                                      #
#                                                                                              #
################################################################################################


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


##########################################################
# Set Variables                                          #
# - iHub iSlot iPort is Tx; iHub2 iSlot2 iPort2 is Rx    #
# - NUM_INTERVALS is the number of latency time slots    #
# - BURST_SIZE is the number of packets that will be sent#
# - INTERVAL_SIZE is the range of each interval in mS    #
##########################################################

set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

set NUM_INTERVALS 10
set NUM_STREAMS 10
set BURST_SIZE 128
set INTERVAL_SIZE 1
set DATA_LENGTH 150

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

#Create streams
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

#Set the stream on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Unset the structure
unset streamIP

#Create a new structure
struct_new incrementIP StreamIP

#set the SourceMac and the SourceIP to increment 
set incrementIP(SourceMAC.5.uc) [format %c 1]
set incrementIP(SourceIP.3.uc) [format %c 1]

#Set up multiple streams on the card
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $NUM_STREAMS - 1] 0 incrementIP 0 $iHub $iSlot $iPort

#UnSet the structure
unset incrementIP

########################################################################################
# Check for L3 streams.                                                                #
# - Test will not work if there are no streams transmitting                            # 
# - The DEFINED_STREAM_COUNT will return the total stream count (including the first,  #
#   hidden stream, so we have to adjust the count to show the count of transmitting    #
#   streams.                                                                           #
########################################################################################

struct_new CountStream  ULong

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 CountStream 0 $iHub $iSlot $iPort

if {  $CountStream(ul) < 1 } {
     puts "No L3 streams on card - Aborting Test!"
     exit
} else {
         puts "Testing with [expr $CountStream(ul) - 1] streams"
}

#UnSet the structure
unset CountStream

##########################################################
# - Set L3_HIST_V2_LATENCY with 1 * 1ms or 1mS interval  #
# - Since we are transmitting from card 1 to card 2, the # 
#   latency test gets set on the Rx card, Card 2.        #
##########################################################

#Declare a new structure
struct_new MyL3HistLatency Layer3HistLatency

#Set the interval size
set MyL3HistLatency(ulInterval) $INTERVAL_SIZE

#Set up the latency on the card
LIBCMD HTSetCommand $L3_HIST_V2_LATENCY 0 0 0 MyL3HistLatency $iHub2 $iSlot2 $iPort2


# Send a single burst of $BURST_SIZE packets. Card 1 is Tx 
HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
HTBurstCount $BURST_SIZE $iHub $iSlot $iPort
HTRun $HTRUN $iHub $iSlot $iPort

#Pause for 1 sec
after 1000

# Create structure to hold the latency data and get the data from the Rx card, Card2.  
# One structure per bucket.        
struct_new MyLongLatencyInfo Layer3LongLatencyInfo*$NUM_INTERVALS

#Get the latency data
LIBCMD HTGetStructure $L3_HIST_V2_LATENCY_INFO 0 0 0 MyLongLatencyInfo 0 $iHub2 $iSlot2 $iPort2

# Print out the test results - first the header
puts ""
puts " TEST RESULTS - LATENCY DISTRIBUTION ($BURST_SIZE) FRAMES"
puts "======================================================="
puts " Latency Range	 Number of Frames    % of Total"
puts "======================================================="

# Calculate the ranges based on value of INTERVAL_SIZE
for {set i 0} {$i < $NUM_INTERVALS} {incr i} {
      set START_RANGE [format "%2d" [expr $INTERVAL_SIZE * $i]]
      set END_RANGE [format "%2d" [expr $START_RANGE + $INTERVAL_SIZE]]

# Print out the range in mS      
  puts -nonewline " $START_RANGE to $END_RANGE mS"
     ###############################################################################
     # If we have packets in the interval, print the number and the % of the whole #
     # format used to set output - BURST_SIZE * 0.1 to force a float               #
     ###############################################################################
     if {$MyLongLatencyInfo($i.ulFrames) > 0} {
         puts -nonewline "  ==>  [format "%3d" $MyLongLatencyInfo($i.ulFrames)] frames "
         puts "        [format "%3.2f" [expr ($MyLongLatencyInfo($i.ulFrames)/($BURST_SIZE * 1.0)) * 100]]%"
     ###############################################
     # No packets in this interval - print nothing #
     ###############################################
     } else {
         puts ""
     }
  puts "-------------------------------------------------------"
}

#Unset the structures
unset MyL3HistLatency
unset MyLongLatencyInfo

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
