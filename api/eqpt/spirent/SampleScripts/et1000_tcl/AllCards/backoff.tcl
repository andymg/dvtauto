
############################################################################################### 
# Backoff.tcl                                                                                 # 
#                                                                                             #
# This program sets a group of cards and sets the backoff truncation exponent.                #
#                                                                                             #
# - Default for the backoff truncation exponent for the group is set to 10.                   #
#   - Setting backoff to a more aggressive(lower number) can result in a much greater packet  #
#     loss rate.                                                                              #
#     - For example, setting the backoff to 1, can result in packet losses as great as 70% in #
#       devices that would otherwise not loose any, if the backoff was set to 10.             #
#                                                                                             #
# NOTE: This script works on the following scripts:                                           #
#       - 10 Mbps                                                                             #
#       - SX-72XX / 74XX                                                                      #
#       - L3-67XX                                                                             #
#       - ML-7710                                                                             #
#       - ML-5710                                                                             #
#       - LAN-6100                                                                            #
#       - LAN-6101A                                                                           #
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
     if { $retval < 0 } {
      puts "Unable to connect to $ipaddr. Please try again."
      exit
     }
}

#Set defaults for Hub, Slot and Port
set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 1
set iPort2 0

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

###########################################################
# Set a group of cards:                               
#
# - HClearGroup, zeros out group settings.
# - HG AddtoGroup, adds cards to group.
# - HTResetPort, resets cards in group to defaults.
###########################################################

LIBCMD HGClearGroup
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2
LIBCMD HGResetPort $RESET_FULL

# This sets the backoff truncation exponent for the group.
# The default value is set to 10.
LIBCMD HGCollisionBackoffAggressiveness 10

#Packets are generated and transmitted
puts "Sending Packets..."
LIBCMD HGStart

#Pause for 1 sec, so that the program transmits the packets
after 1000

#Stop transmitting packets
LIBCMD HGStop
puts "Done!"

#UnLink from the chassis
LIBCMD NSUnLink

