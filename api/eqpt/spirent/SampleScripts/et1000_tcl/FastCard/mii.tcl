################################################################################################
# MII.TCL                                                                                      #
#                                                                                              #
# - Demonstrates the use of the HTReadMII and HTWriteMII commands to enable Autonegotiation    #
#   and to display the contents of the MII registers and to force an Autonegotiation.          # 
# - This program will change the value of the advertisement register (4) to                    #
#   10BaseT and after the restart autonegotiation will set cards in 10BaseT mode               #
#                                                                                              #
# NOTE: This script works on the following cards:                                              #
#       - SX-72XX / SX-74XX                                                                    #
#       - L3-67XX                                                                              #
#       - ML-7710                                                                              #
#       - ML-5710                                                                              #
#       - LAN-6100                                                                             #
#       - LAN-6101A                                                                            #
#       - LAN-3300A                                                                            #
#       - LAN-3301A                                                                            #
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

#Set the default variables
set iHub  0
set iSlot  7
set iPort 0

set iHub2  0
set iSlot2  7
set iPort2 1

set MAX_MII_REGISTERS 6
set MAX_CARDS 2
set Address ""
set Register ""
set Contents "" 

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

# Reset both cards - Should reset to 100BaseTX Full Duplex
puts "Resetting cards - will default to 100 Mb/s full duplex"

LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

# pause for 2 seconds for user to see cards at 100Mb/s full duplex
puts "Waiting 2 seconds..."
after 2000


# Locate MII address of first device If you do this later in the program it may reset register values to defaults
LIBCMD HTFindMIIAddress Address Register $iHub $iSlot $iPort
puts "Found Device at MII Address $Address"
puts ""

###########################################################################################################
# - Enable Autonegotiation OR contents of Control Register with 0x1000 to enable Autonegotiation on both  #
#   cards in pair.                                                                                        #
# - Variable MII_CTRL_AUTONEGOTIATE is defined as 0x1000 in ET1000.TCL                                    #
# - Forces to 100Mb mode (bit "2") and autonegotiate (bit "1") by writing 0x3000                          #
# - The command should work just as well OR'ing the register contents with 0x1000.                        #
# - It seems to need a few seconds (after 2000) to allow the mode to set to read the                      #
#   LinkPartner register.                                                                                 #
###########################################################################################################

puts "Enabling Autonegotitation"
puts ""


set Register 0
set Contents 0x3000
LIBCMD HTWriteMII $Address $Register $Contents $iHub $iSlot $iPort
LIBCMD HTWriteMII $Address $Register $Contents $iHub2 $iSlot2 $iPort2

#Pause for 2 seconds
after 2000

#######################################################################################################
# - Display content of MII Registers                                                                  #
# - Find address, locates the address                                                                 #
# - puts -nonewline "[format "%-14s" Control] will set up a 14 space column for the register name.    #
# - The switch statement changes the name displayed to correspond to the MII register name.           #
# - [format %04x $Contents] is necessary to force a hex display (the default value                    #
#   returned is decimal.                                                                              #
# - The leading 04 sets the display to four places and inserts leading zeroes.                        #
#######################################################################################################

puts "***********************************************"
puts "Reading MII Registers for card [expr $iSlot + 1]"
puts "***********************************************"

puts ""


for {set Register 0} {$Register < $MAX_MII_REGISTERS} {incr Register} {
      LIBCMD HTReadMII $Address $Register Contents $iHub $iSlot $iPort

      puts -nonewline "Register $Register "

	switch $Register {

                0 {puts -nonewline "[format "%-14s" Control] " }
                1 {puts -nonewline "[format "%-14s" Status] "}
                2 {puts -nonewline "[format "%-14s" "PHY Identifier"] "}
                3 {puts -nonewline "[format "%-14s" "PHY Identifier"] "}
                4 {puts -nonewline "[format "%-14s" Advertisement] "}
                5 {puts -nonewline "[format "%-14s" "Link Partner"] "}
                6 {puts -nonewline "[format "%-14s" Expansion] " }

                default {puts -nonewline "[format "%-14s" Unknown] "}
         }
puts "->	:  [format %04x $Contents]"
}
puts ""
puts "***********************************************"
puts ""


###########################################################################
# - Change Advertisement Register to 10 BaseT Half Duplex only.           #
# - The advertisement bit places are as follows in binary                 #
# 		XXXX XX12 345X XXXX                                       #
#   where X is a don't care (for speed an plex) and                       #
# - 1 is 100BaseT4; 2 is 100BaseTx Full; 3 is 100BaseTX Half              #
#   4 is 10BaseT Full and 5 is 10BaseT Half                               #
# - Cards will reset to highest common setting.                           #
#   So settting the Advertisement register to 0021 means the              #
#   target card will only advertise 10BaseT Half capability, forcing      #
#   the link partner to accept 10BaseT Half when Restart Autonegotiation  #
#   is forced.                                                            #
###########################################################################

puts "Setting Advertisement Register to 0x0021 to set to 10Mb half duplex"

set Register 4
set Contents 0x0021

LIBCMD HTWriteMII $Address $Register $Contents $iHub $iSlot $iPort

##################################################################################
# - Restart Autonegotiation.                                                     #
# - Set register to zero (Control) and get current contents then bitwise OR the  #
#   current value with MII_CTRL_RESTARTAUTONEGOTIATE (defined as 0x0200)         #
#   then write result back to register 0.  This will force an AutoNegotiation.   #
# - The cards in your chassis will renegotiate to 10BaseT Half Duplex.           #
##################################################################################

puts "Restarting autonegotiation for 10Mb/s mode"
puts ""
set Register 0
#HTReadMII $Address $Register Contents $iHub $iSlot $iPort
#set Contents [expr $Contents | 0x0200]
set Contents 0x3300
LIBCMD HTWriteMII $Address $Register $Contents $iHub $iSlot $iPort

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"


