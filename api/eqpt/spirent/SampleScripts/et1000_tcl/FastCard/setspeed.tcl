#############################################################################################
# SETSPEED.TCL                                                                              #
#                                                                                           #
# - Sets speed an duplex.                                                                   #
#                                                                                           #
# - It uses HT commands to set two cards in slot one and two to 10Mb Half Duplex directly   #
# - Next it creates a group of two cards and sets the same parameters with groutp commands  #
#                                                                                           #
# NOTE: This script works on the following cards:                                           #
#       - SX-72XX / 74XX                                                                    #
#       - L3-67XX                                                                           #
#       - ML-7710                                                                           #
#       - ML-5710                                                                           #
#       - LAN-6100                                                                          #
#       - LAN-6101A                                                                         #
#       - LAN-3300A / 3301A / 3302A                                                         #
#       - LAN-3310A / 3311A                                                                 #
#                                                                                           #
#############################################################################################


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
set iHub 0
set iSlot 7
set iPort 0

set iHub2 0
set iSlot2 7
set iPort2 1


set DATA_LENGTH1 60
set DATA_LENGTH2 128
set TEST_CARDS 2

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Create a group of two cards and set speed and plex with group commands
# Reset both cards at once. Transmit from Card 1 to Card 2 10Mb 1/2 Duplex
puts "Creating group and setting cards to 10Mb/s Half Duplex"

LIBCMD HGClearGroup
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub $iSlot2 $iPort


LIBCMD HGResetPort $RESET_FULL
LIBCMD HGSetSpeed $SPEED_10MHZ
LIBCMD HGDuplexMode $HALFDUPLEX_MODE
LIBCMD HGTransmitMode $CONTINUOUS_PACKET_MODE
LIBCMD HGDataLength $DATA_LENGTH1

# Transmitting
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

#Pause for 3 seconds
after 3000
LIBCMD HTRun $HTSTOP $iHub $iSlot $iPort

puts "Switching to 100Mb/s Full Duplex"

# Set speed and plex with group commands
# Transmit from both cards at 100 Mb Full Duplex
LIBCMD HGResetPort $RESET_FULL
LIBCMD HGSetSpeed $SPEED_100MHZ
LIBCMD HGDuplexMode $FULLDUPLEX_MODE
LIBCMD HGTransmitMode $CONTINUOUS_PACKET_MODE
LIBCMD HGDataLength $DATA_LENGTH2
LIBCMD HGStart
after 3000
LIBCMD HGStop


# Unset group
LIBCMD HGClearGroup

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
