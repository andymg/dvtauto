###############################################################################################
# GapPerCent.tcl                                                                              #
#                                                                                             #
# This program:                                                                               #
# - Calculates the % utilization and sets the Tx parameters at that rate.                     #
# - Everything is calculated in bit times, since NS HTGap command takes bit                   #
#   times as an argument (allowing the same setting for 10 or 100 MHZ)                        #
#                                                                                             #
# NOTE:  This sample code will not work with ATM and WAN cards                                #
#        This script works on the following cards:                                            #
#        - SX-72XX / 74XX                                                                     #
#        - L3-67XX                                                                            #
#        - ML-7710                                                                            #
#        - LAN-6100                                                                           #
#        - LAN-6101A                                                                          #
#        - GX-1420 A/B                                                                        #
#        - LAN-3300A/3301A/3302A                                                              #
#        - LAN-3306A                                                                          #
#        - LAN-332xA                                                                          #
#        - LAN-3710A                                                                          #
#        - XLW-372xA                                                                          #
#        - TokenRing                                                                          #
#                                                                                             #
###############################################################################################


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
         
                        puts "Could not find the file '$libPath'."
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

#Set the constants
set PREAMBLE_LENGTH 64
set CRC_LENGTH 32
set 10MEG 10000000
set 100MEG 100000000
set MIN_GAP 96

set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 1
set iPort2 0

set LOOP_COUNT 10

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Prompt for input - NO INPUT CHECKING - unreasonable input values will give 
# unreasonable output results

puts "This program will set the transmission rate as % utilization"
puts "Please enter data length of packets (from 60 to 1514)"
gets stdin DATA_LENGTH
 
puts "Please enter percent utilization as a fraction of 1.0"
puts "For example, for 50% utilization enter 0.5"
gets stdin PER_CENT_UTIL

# set Packet Length
LIBCMD HTDataLength $DATA_LENGTH $iHub $iSlot $iPort

# We will do most calculations in bit times since this is speed independent
# Bits per packet is preamble of 64 bits plus CRC of 32 bits plus Bytes per packet * 8
  set PACKET_BITS [expr ($PREAMBLE_LENGTH + $CRC_LENGTH) + ($DATA_LENGTH * 8)]

# Add minimum gap (96 bit times) to get the total
  set PACKET_PLUS_MIN_GAP [expr $PACKET_BITS + $MIN_GAP]

#############################################################################################
# - Set speed on the card and calculate WIRE_RATE  - the rate with a minimum 96             #
#   bit time interpacket gap.                                                               #
# - Both 10 and 100Meg are shown.                                                           #
# - Uncomment the one you want.                                                             #
#############################################################################################

LIBCMD HTSetSpeed $SPEED_10MHZ $iHub $iSlot $iPort
LIBCMD HTSetSpeed $SPEED_10MHZ $iHub2 $iSlot2 $iPort2
set WIRE_RATE [expr $10MEG / $PACKET_PLUS_MIN_GAP]

##############################################################################################
# - REMOVE THE COMMENTED AREA BELOW, IF YOU WISH TO USE 100 MEG                              #
############################################################################################## 
# For 100 Meg
#LIBCMD HTSetSpeed $SPEED_100MHZ $iHub $iSlot $iPort
#LIBCMD HTSetSpeed $SPEED_100MHZ $iHub2 $iSlot2 $iPort2
#set WIRE_RATE [expr $100MEG / $PACKET_PLUS_MIN_GAP]


# Add four bytes for the 32 CRC bits and print the wire rate value at
# the selected packet size
puts "Wire rate for [expr $DATA_LENGTH + 4] byte long packets is $WIRE_RATE"

# Calculate the number at PER_CENT_UTIL
set TEST_PACKETS [expr $PER_CENT_UTIL * $WIRE_RATE]
puts "Test will run at [expr $PER_CENT_UTIL * 100] percent ($TEST_PACKETS packets per second)"

###############################################################################################
# Calculate the total bit times for all packets with NO gap.                                  #
# - This allows the total gap time to be extracted and divided below                          #
# - Both 10 Meg and 100Meg are shown uncomment the one you want or add an if etc...           #
#                                                                                             #
###############################################################################################

#For 10Meg
set TOTAL_GAP  [expr $10MEG - ($PACKET_BITS * $TEST_PACKETS)]

#For 100Meg
#set TOTAL_GAP  [expr $100MEG - ($PACKET_BITS * $TEST_PACKETS)]

# Gap per packet is the total gap divided by the packets at the specified utilization rate
set GAP_PER_PACKET [expr $TOTAL_GAP / $TEST_PACKETS]

# Set corresponding gap (gap is in bit times) on Tx card
LIBCMD HTGap $GAP_PER_PACKET $iHub $iSlot $iPort

# Clear Counters
LIBCMD HTClearPort $iHub $iSlot $iPort

struct_new cs HTCountStructure

# start transmission
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
 
#############################################################################################
# - The loop gets the counter data every second for as long as the loop is running and      #
#   prints out the transmission rate in packets per second.                                 #
#   ---------------------------------------------------------------------------------
# - Note that the inital read is usually not accurate, since the counter data is only       #
#   updated every second.                                                                   #
#   ---------------------------------------------------------------------------------       #
#############################################################################################

#Wait for 1 second
after 1000

   for {set i 0} {$i < $LOOP_COUNT} {incr i} {
         LIBCMD HTGetCounters cs $iHub $iSlot $iPort          
         puts "The number of frames transmitted by card [expr $iSlot + 1] is $cs(TmtPktRate)per second"
         after 1000
   }   
               
LIBCMD HTRun $HTSTOP $iHub $iSlot $iPort

#Free resources
unset cs

#UnLink from the chassis
puts "Unlinking from the chassis"
LIBCMD NSUnLink
puts ""
puts "DONE!"
