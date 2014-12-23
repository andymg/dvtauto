###############################################################################################
# Collision.tcl                                                                               #
#                                                                                             #
#  - Program demonstrates how to set up collision generation on SX-74XX and SX-72XX           #
#    FastCards.                                                                               #
#                                                                                             #
#    Note: This script works on the following card only:                                      #
#          - SX-72XX / SX-74XX                                                                #
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
set iSlot2 1
set iPort2 0

set BURST_SIZE 200
set COLLISIONS 100

#######################################################################################
# LIBCMD:  Error Handler                                                              #
# - Outputs function name, arguments, and return value when function return code < 0. #
#######################################################################################

proc LIBCMD {args} {
	             set iResponse [uplevel $args]
	             if {$iResponse < 0} {
		     puts "$args :  $iResponse"
	           }
	             return $iResponse
}

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

############################################################################################
# Setup collision structure                                                                #
# - Note: the only elements that have meaning for a FastCard are Count                     #
#   (which is how many packets to collide with) and mode.                                  #
# - The COLLISION_LONG variable will turn collisions ON and COLLISION_OFF will turn it off.#
# - The CollisionStructure structure has elements that set the duration and the bit count  #
#   where the collisions will start.                                                       #
# - These do not apply to FastCards (ET1000 only).                                         #
# - The HTCollision command is sent to the receiving card which generates the collisions   #
#   against the packets sent by the transmitting card                                      #
############################################################################################

struct_new CollStruct CollisionStructure

   set CollStruct(Count) $COLLISIONS
   set CollStruct(Mode) $COLLISION_LONG

LIBCMD HTCollision CollStruct $iHub2 $iSlot2 $iPort2  

#Unset the structure 
unset CollStruct

# Set Group
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

# Cards must be in half duplex or else no collisions
LIBCMD HGDuplexMode $HALFDUPLEX_MODE

# Clear Counters
LIBCMD HGClearPort

#set burst mode and size and send one burst from card 1
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

after 1000
##############################################################################################################
# Counter data                                                                                               #
# - With the Burst size set to 200 and the number of collisions set to 100, the counters will show 200       #
#   packets sent and received and 100 collisions.                                                            #
# - Note that the SmartCard will trigger a collision on the first 100 packets transmitted.                   #
# - The transmitting card will "wait out" any number of collisions and then transmit                         #
#   the full burst.                                                                                          #
# - There is no point where a SmartCard will give up on the transmission (since it is a test equipment and   #
#   not an end station).                                                                                     #
##############################################################################################################

struct_new cs HTCountStructure*2

LIBCMD HGGetCounters cs

after 1000
puts "------------------------------------------------------------"
puts "			Test Results"
puts "------------------------------------------------------------"
puts "    	        Card [expr $iSlot + 1]			Card [expr $iSlot2 +1]"
puts "------------------------------------------------------------"
puts "Tx Packets 	$cs(0.TmtPkt)		|	$cs(1.TmtPkt)"
puts "Rx Packets 	$cs(0.RcvPkt)		|	$cs(1.RcvPkt)"
puts "Collisions	$cs(0.Collision)		|	$cs(1.Collision)"
puts "------------------------------------------------------------"

#Unset the structure
unset cs

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"

