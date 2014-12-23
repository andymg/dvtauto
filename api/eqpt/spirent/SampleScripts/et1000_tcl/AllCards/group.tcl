###############################################################################
# Group.tcl                                                                   #
#                                                                             #
#This program:                                                                #
#- Sets a group of cards:                                                     #
#  - Clears group settings.                                                   #
#  - Adds the cards to the group.                                             #
#  - Resets the cards in the group to the defaults.                           #
#  - Transmits some data.                                                     #
#                                                                             #
# NOTE: This script works on the following cards:                             #
#       - 10 Mbps                                                             #
#       - SX-72XX/74XX                                                        #
#       - L3-67XX                                                             #
#       - ML-7710                                                             #
#       - ML-5710                                                             #
#       - LAN-6100                                                            #
#       - LAN-6101A                                                           #
#       - GX-1405(B)                                                          #
#       - GX-1420 A/B                                                         #
#       - LAN-6200A                                                           #
#       - LAN-6201A/B                                                         #
#       - LAN-3300A/3301A/3302A                                               #
#       - LAN-3310A/3311A                                                     #
#       - LAN-3306A                                                           #
#       - LAN-332xA                                                           #
#       - LAN-3710A                                                           #
#       - XLW-372xA                                                           #
#       - POS-6500/6502                                                       #
#       - POS-3505As/3504As                                                   #
#       - TokenRing                                                           #
#       - WAN                                                                 #
#                                                                             #
###############################################################################

if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
         set libPath "../../../../include/et1000.tcl"
}


# if "Et1000.tcl is not loaded, try to source it at the default path
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

#Set the defaults for Hub, Slot and Port
set iHub 0
set iPort 0

set iSlot 0
set iSlot2 1

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub $iSlot2

###########################################################
# Transmit data:                                           #
# - HGClearGroup zeros out group setting.                  #
# - HG AddtoGroup adds cards to group.                    #
# - HTResetPort resets cards in group to defaults.         #
###########################################################

LIBCMD HGClearGroup
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub $iSlot2 $iPort
LIBCMD HGResetPort $RESET_FULL

#Transmitting packets
puts "Sending Packets..."
LIBCMD HGStart

#Pause for 1 sec
after 10000

#Stop transmitting packets
LIBCMD HGStop
puts "Done!"

#UnLink the chassis
LIBCMD NSUnLink
