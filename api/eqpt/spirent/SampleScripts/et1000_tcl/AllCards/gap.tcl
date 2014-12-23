########################################################################################### 
#GAP.TCL                                                                                  #
#                                                                                         #
# This program:                                                                           #
# -  Sends a burst of 5000 packets starting with a gap of 30uS                            #
# -  Transmits a burst equal to the BURST_SIZE variable.                                  #
# -  Keeps a running count of packets transmitted and received.                           #
# -  With each iteration, decreases the gap by 1 uS, stopping at the minimum gap.         #
# -  Script is set to 10 Mb/s half duplex. Can be set to 100 by changing the value        #
#    of SPEED and changing the settings for speed and plex in the intialization loop.     #
# -  HTSetSpeed command has been commented out to be later used with 10Mb/s cards.        #
# -  Burst size and packet size can be changed by changing BURST_SIZE and DATA_LENGTH     #
#    variables.                                                                           #
#                                                                                         #
# NOTE: This script works on the fiollowing scripts:                                      #
#       - SX-72xx / 74XX                                                                  #
#       - ML-77XX                                                                         #
#       - L3-67XX                                                                         #
#       - LAN-6100                                                                        #
#       - LAN-6101A                                                                       #
#       - GX-1420(B)                                                                      #
#       - LAN-3300A/3301A                                                                 #
#       - LAN-3306A                                                                       #
#       - LAN-332xA                                                                       #
#       - LAN-3710A                                                                       #
#       - XLW-372xA                                                                       #
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


# initialize variables

set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 1
set iPort2 0

set TEST_CARDS 2
set DATA_LENGTH 60
set BURST_SIZE 5000
set SPEED 10

#Declare a new structure
struct_new cs HTCountStructure

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

###########################################################################################
# Initialization loop                                                                     #
#                                                                                         #
# -  Uses a loop where both cards are initialized at once using the counter as the        #
#    Slot number.                                                                         #
# -  HTSetSpeed has been commented out for use with 10Mb/s cards.                         #
# -  Remove the # to use with 10/100 cards.                                               #
###########################################################################################

for { set i 0 } { $i < $TEST_CARDS } { incr i } {
        LIBCMD HTResetPort $RESET_FULL $iHub $i $iPort
        LIBCMD HTSetSpeed $SPEED_10MHZ $iHub $i $iPort
        LIBCMD HTDuplexMode $HALFDUPLEX_MODE $iHub $i $iPort
        LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $i $iPort
        LIBCMD HTDataLength $DATA_LENGTH $iHub $i $iPort
        LIBCMD HTBurstCount $BURST_SIZE $iHub $i $iPort
}

#############################################################################################
# Set gap loop                                                                              #         
#                                                                                           #
# -  The gap is decremented by 10 after every 5000 packets                                  #
#    (10 * 100 nS = 1 uS).                                                                  #
# -  A special if loop was added to make the last decrement from                            #
#    10uS to 9.6uS (minimum gap)                                                            #
# -  Counts from cards are cumulative.                                                      #
# -  Lost packets are indicated by difference between transmitted and received              #
#    packet count(assumption that the attached device generates packets, may not be valid.) #
#############################################################################################

for { set pktgap 300 } { $pktgap > 89 } { incr pktgap -10 } {
        if { $pktgap < 100 } {
	       set pktgap 96
        }
        LIBCMD HTGap $pktgap $iHub $iSlot $iPort
        LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
        puts "Transmitting $BURST_SIZE packets at $SPEED Mb/s with a [expr $pktgap * 0.1] uS gap"

        #Pause for 2 seconds
        after 2000

        #Get the total number of packets transmitted and print it
        LIBCMD HTGetCounters cs $iHub $iSlot $iPort
        puts "Total packets transmitted was $cs(TmtPkt)"
        LIBCMD HTGetCounters cs $iHub2 $iSlot2 $iPort2
        puts "Total packets received was $cs(RcvPkt)"
}

#Unset the structure 
unset cs

#UnLink the chassis
LIBCMD NSUnLink
