######################################################################################################
# ETHCardInfo.tcl                                                                                    #
#                                                                                                    #
# - Demonstrates use of ETH_CARD_INFO message function                                               #
#                                                                                                    #
# - Allows use of legacy Ethernet card functions with HTGetStructure Message Function.               #
#                                                                                                    #
# PLEASE NOTE: The ETH functions are only valid with 10Mb, 10/100Mb and 10 or 10/100 Layer 3 cards.  #
# The properties for all cards are presented for completeness only.  Running against non-ethernet    #
# cards will return a non-positive (error code) from this function                                   #
#                                                                                                    #
# NOTE: This script works with the following cards:                                                  #
#       - 10MB                                                                                       #
#       - SX-72XX / 74XX                                                                             #
#       - L3-67XX                                                                                    #
#       - ML-7710                                                                                    #
#       - ML-5710                                                                                    #
#       - LAN-6101A                                                                                  #
#       - LAN-6100                                                                                   #
#                                                                                                    #
# - Port Properties Values AND'd or OR'd with:                                                       #
# - CA_SIGNALRATE_10MB 0x00000001                                                                    #
# - CA_SIGNALRATE_100MB 0x00000002                                                                   #
# - CA_DUPLEX_FULL 0x00000004                                                                        #
# - CA_DUPLEX_HALF 0x00000008                                                                        #
# - CA_CONNECT_MII 0x00000010                                                                        #
# - CA_CONNECT_TP 0x00000020                                                                         #
# - CA_CONNECT_BNC 0x00000040                                                                        #
# - CA_CONNECT_AUI 0x00000080                                                                        #
# - CA_CAN_ROUTE 0x00000100                                                                          #
# - CA_VFDRESETCOUNT 0x00000200                                                                      #
# - CA_SIGNALRATE_4MB 0x00000400                                                                     #
# - CA_SIGNALRATE_16MB 0x00000800                                                                    #
# - CA_CAN_COLLIDE 0x00001000                                                                        #
# - CA_SIGNALRATE_25MB 0x00002000                                                                    #
# - CA_SIGNALRATE_155MB 0x00004000                                                                   #
# - CA_BUILT_IN_ADDRESS 0x00008000                                                                   #
# - CA_HAS_DEBUG_MONITOR 0x00010000                                                                  #
# - CA_SIGNALRATE_1000MB 0x00020000                                                                  #
# - CA_CONNECT_FIBER 0x00040000                                                                      #
# - CA_CAN_CAPTURE 0x00080000                                                                        #
# - CA_ATM_SIGNALING 0x00100000                                                                      #
# - CA_CONNECT_V35 0x00200000                                                                        #
# - CA_SIGNALRATE_8MB 0x00400000                                                                     #
# - CA_SIGNALRATE_622MB 0x00800000                                                                   #
# - CA_SIGNALRATE_45MB 0x01000000                                                                    #
# - CA_SIGNALRATE_34MB 0x02000000                                                                    #
# - CA_SIGNALRATE_1_544MB 0x04000000                                                                 #
# - CA_SIGNALRATE_2_048MB 0x08000000                                                                 #
# - CA_HASVFDREPEATCOUNT 0x10000000                                                                  #
#                                                                                                    #
######################################################################################################

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
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

set MAX_CHARS_IN_STRING 7
set MAX_HW_CHARS 6

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# create structure to hold card information and execute HTGetStructure $ETH_CARD_INFO 
# to pull the data from the card            
struct_new MyCardInfo ETHCardInfo

#Set on the card
LIBCMD HTGetStructure $ETH_CARD_INFO 0 0 0 MyCardInfo 0 $iHub $iSlot $iPort

########################################
# Display a simple header on screen    #
########################################

puts "#######################################################"
puts "               CARD INFORMATION     "
puts "#######################################################"
puts ""
puts -nonewline "  Slot [expr $iSlot +1] ==>  "

################################################
# Unset values will return {} We check for     #
# this value in the first position (indicating #
# a situation where no value was returned from #
# the card. We set the value to a character (@)#
# unlikely to be used on a future product so   #
# it will fall through to the correct message  #
# on the switch that follows.                  #
# If first char is not {} we print out the     #
# characters that spell out the model name     #
################################################

if { $MyCardInfo(szCardModel.0) == "{}" } {
      puts -nonewline " no model information from"
      set MyCardInfo(cPortID) "@"
} else {
         for {set i 0} {$i < $MAX_CHARS_IN_STRING} {incr i} {
               puts -nonewline "$MyCardInfo(szCardModel.$i)"
         }
}

###################################################
# print out the card type based on the value of   #
# MyCardInfo(cPortID)                             #
# Finish the display string with  puts " card"    #
#                                                 #
# The value for all cards is included even though #
# the ETH functions are only for Ethernet cards   #
###################################################

switch $MyCardInfo(cPortID) {

   A {puts -nonewline " - 10Mb Ethernet"}
   F {puts -nonewline " - 10/100Mb Fast Ethernet"}
   T {puts -nonewline " - 4/16Mb TokenRing"}
   V {puts -nonewline " - VG/AnyLan"}
   3 {puts -nonewline " - Layer 3 10Mb Ethernet"}
   G {puts -nonewline " - Gigabit Ethernet"}
   S {puts -nonewline " - ATM Signaling"}
   N {puts -nonewline " non-existant"}
   @ { }

   default {puts -nonewline "unknown"}
}

puts " card"
puts ""

##########################################################
# ulPortProperties is a long that flips bits to indicate #
# the availability of various card functions.  A bitwise #
# AND "&" can be used to indicate the presence of        #
# functions of interest.  For example you might check for#
# capture capabilities before starting a capture.        #
##########################################################

puts "   ====CARD CAPABILITIES===="
set PortProps $MyCardInfo(ulPortProperties)

#######################################################
# First check to see if it's a 10 or 10/100 ENet card #
# (MyCardInfo(cPortID) equal to one of the values for #
# a 10/100 card, then check Speed and Plex            #
#######################################################

if {($MyCardInfo(cPortID)  == "A") || ($MyCardInfo(cPortID) == "F")\
    || ($MyCardInfo(cPortID) == "3")} {
     if [expr $PortProps & $CA_SIGNALRATE_100MB] {
          puts "     10 Mb or 100Mb Fast Ethernet"
     } elseif [expr $PortProps & $CA_SIGNALRATE_10MB] {
                puts "     10 Mb Ethernet"
     } else { puts "No Ethernet Speed Capability Reported"
     }
     if [expr $PortProps & $CA_DUPLEX_FULL] {
          puts "     Full or Half Duplex"
     } elseif [expr $PortProps & $CA_DUPLEX_HALF] {
                puts "     Half Duplex Only"
     } else { puts "No Ethernet Duplex Capability Reported"
     }

   ############################
   # Check for interface type #
   ############################

   if [expr $PortProps & $CA_CONNECT_TP] {
        puts "     Twisted Pair Interface"
   } elseif [expr $PortProps & $CA_CONNECT_BNC] {
       puts "     BNC Coax Interface"
   } elseif [expr $PortProps & $CA_CONNECT_AUI] {
       puts "     AUI Thicknet Ethernet Interface"
   } else {
       puts "No Interface Capability Reported"
   }

   #####################################
   # Check for collision capture debug #
   # and layer 3 capabilities          #
   #####################################

   if [expr $PortProps & $CA_CAN_COLLIDE] {
       puts "     Collision Capable"
   }

   if [expr $PortProps & $CA_CAN_CAPTURE] {
       puts "     Capture Capable"
   }

   if [expr $PortProps & $CA_HAS_DEBUG_MONITOR] {
       puts "     Debug Monitor"
   }
 
   if [expr $PortProps & $CA_CAN_ROUTE] {
       puts "     Routing (Layer 3) Capable"
   }
} else {
         puts "Not a 10/100 Ethernet Card"
}
puts ""
puts "     Card Type $MyCardInfo(uiPortType)"

##################################################
# Only microprocessor based cards with their own #
# firmware will return a numeric value.  All     #
# others will return 000000                      #
##################################################
puts -nonewline "     Hardware ID "

for {set i 0} {$i < $MAX_HW_CHARS} {incr i} {
      puts -nonewline $MyCardInfo(ulHWVersions.$i)
}

puts ""

#Unset the structure
unset MyCardInfo

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
