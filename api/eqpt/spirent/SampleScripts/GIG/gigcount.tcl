###################################################################################
# GIGCount.tcl                                                                    #
#                                                                                 #
# - Sets a group of Gigabit cards (slot 1 and 3).                                 #
#                                                                                 #
# - We create an array of counter structures to hold the group counter data,      #
#   then draw a simple report and fill in the counter data.                       #
#                                                                                 #
# NOTE: This script works on the following cards:                                 #
#       - GX-1405(B)                                                              #
#       - GX-1420(B)                                                              #
#       - LAN-6200A                                                               #
#       - LAN-6201A                                                               #
#       - LAN-3300A/3310A                                                         #
#                                                                                 #
###################################################################################

# If smartlib.tcl is not loaded, attempt to locate it at the default location.
# The actual location is different on different platforms. 
if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/smartlib.tcl"
} else {
         set libPath "../../../../include/smartlib.tcl"
}
# if "smartlib.tcl" is not loaded, try to source it from the default path
if { ! [info exists __SMARTLIB_TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
} else {   
               
         #Enter the location of the "smartlib.tcl" file or enter "Q" or "q" to quit
         while {1} {
         
                     puts "Could not find the file $libPath."
                     puts "Enter the path of smartlib.tcl, or q to exit." 
          
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


set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Reset the cards
#LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
#LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

# Create a group of two cards
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

#############################################
# Initialize transmit parameters            #
# single stream (no alternate) with no VFDs #
#############################################

LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 - 0 $iHub $iSlot $iPort \
	-ulGap 9600
LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 - 0 $iHub2 $iSlot2 $iPort2 \
	-ulGap 9600

# Reset Counters
LIBCMD HGClearPort

# Transmit for four seconds          
puts "Sending Packets..."
LIBCMD HGStart 

after 4000			
LIBCMD HGStop				
puts "Done!"

# Pause a second to stabilize counters
after 1000			
###############################################################################
# Counters                                                                    #
# - We create an array of two structures of type HTCountStructure             #
#   then call HGGetCounters to retireve data from cards.                      #
#   This is the same procedure used for all L2 cards.                         #
#                                                                             #
# - We add 1 to $iSlot and $iSlot2 to match the slot number on the chassis    #
#                                                                             #
# - Use format to align count data (10d allows 10 spaces decimal output).     #
###############################################################################

struct_new cs HTCountStructure*2

LIBCMD HGGetCounters cs

puts "------------------------------------------------------------"
puts "			Test Results"
puts "------------------------------------------------------------"
puts "    	            Card [expr $iSlot + 1]		Card [expr $iSlot2 +1]"
puts "------------------------------------------------------------"
puts "Tx Packets 	[format %10d "$cs(0.TmtPkt)"]	|  [format %10d "$cs(1.TmtPkt)"]"
puts "Rx Packets 	[format %10d "$cs(0.RcvPkt)"]	|  [format %10d "$cs(1.RcvPkt)"]"
puts "Collisions	[format %10d "$cs(0.Collision)"]	|  [format %10d "$cs(1.Collision)"]"
puts "Recvd Trigger	[format %10d "$cs(0.RcvTrig)"]	|  [format %10d "$cs(1.RcvTrig)"]"
puts "CRC Errors	[format %10d "$cs(0.CRC)"]	|  [format %10d "$cs(1.CRC)"]"
puts "------------------------------------------------------------"

#Unset the structure
unset cs

puts "UnLinking from the chassis.."
LIBCMD NSUnLink
puts "DONE!"
