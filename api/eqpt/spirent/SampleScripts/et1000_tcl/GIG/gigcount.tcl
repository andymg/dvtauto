#############################################################################################
# GigCount.tcl                                                                              #
#                                                                                           #
# - Sets a group of Gigabit cards (slot 1 and 3).                                           #
# - An array of counter structures is created, to hold the group counter data, then draw a  #
#   simple report and fill in the counter data.                                             #
#                                                                                           #
# NOTE: This script works on the following cards:                                           #
#       - GX-1405(B)                                                                        #
#       - GX-1420(B)                                                                        #
#       - LAN-6200                                                                          #
#       - LAN-6201                                                                          #
#       - LAN-3300A                                                                         #
#       - LAN-3310A                                                                         #
#       - LAN-3311A                                                                         #
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
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Reset the Ports
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

# Create a group of two cards
LIBCMD HGSetGroup ""

LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

# Initialize transmit parameters single stream (no alternate) with no VFDs
struct_new GT GIGTransmit

set GT(uiMainLength) 60
set GT(ucPreambleByteLength) [format %c 8]
set GT(ulGap) 9600
set GT(ucMainRandomBackground) [format %c 0]

set GT(ucMainCRCError) [format %c 0]
set GT(ucJabberCount) [format %c 0]
set GT(ucLoopback) [format %c 0]
set GT(ulBG1Frequency) 0
set GT(ulBG2Frequency) 0
set GT(uiLinkConfiguration) 32
set GT(ucVFD1Mode) [format %c $GIG_VFD_OFF]
set GT(ucVFD2Mode) [format %c $GIG_VFD_OFF]
set GT(ucVFD3Mode) [format %c $GIG_VFD3_OFF]
set GT(ucTransmitMode) [format %c $GIG_CONTINUOUS_MODE]
set GT(ucEchoMode) [format %c 0]
set GT(ucCountRcverrOrOvrsz) [format %c 0]
set GT(ucGapByBitTimesOrByRate) [format %c 0]
set GT(ucRandomLengthEnable) [format %c 0]

#Set the card
LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 GT 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 GT 0 $iHub2 $iSlot2 $iPort2

#Unset the structure
unset GT

# Reset Counters
LIBCMD HGClearPort

# Transmit for four seconds
puts "Sending Packets..."
LIBCMD HGStart 

#Pause for 4 seconds
after 4000

LIBCMD HGStop
puts "Done!"

# Pause a second to stabilize counters
after 1000

###############################################################################
# Counters                                                                    #
# - An array is created of two structures of type HTCountStructure            #
# - HGGetCounters is called to retireve data from cards.                      #
#   This is the same procedure used for all L2 cards.                         #
# - We add 1 to $iSlot and $iSlot2 to match the slot number on the chassis    #
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

#UnLink the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"