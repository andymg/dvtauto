#################################################################################
# 1stBasic.tcl                                                                  #
#                                                                               #
# - Sets up Traditional mode traffic packets on Ethernet cards.                 #
# - Works with the first two Ethernet ports in a chassis, connected             #
#   back to back.                                                               #
# Note:                                                                         #
# - LIBCMD is a smartLib error checking routine included in et1000.tcl.         #
#   It outputs function name, arguments, and return value when function         #
#   return code < 0. (A negative return value indicates an error condition.)    #
#                                                                               #
# NOTE: This script works on the following cards:                               #
#       - 10 Mbps                                                               #
#       - SX-72XX / 74XX                                                        #
#       - L3-67XX                                                               #
#       - ML-7710                                                               #
#       - ML-5710                                                               #
#       - GX-1405(B)                                                            #
#       - GX-1420(B)                                                            #
#       - LAN-6100                                                              #
#       - LAN-6101A                                                             #
#       - LAN-6200A                                                             #
#       - LAN-6201 A/B                                                          #
#       - LAN-3300A/3301A                                                       #
#       - LAN-3310A/3311A                                                       #
#       - LAN-3306A                                                             #
#       - LAN-332xA                                                             #
#       - LAN-3710A                                                             #
#       - XLW-372xA                                                             #
#       - TokenRing                                                             #
#                                                                               #
#################################################################################



# If used with an SMB-2000, uses cards in the first two slots,
# Hub Slot Port 0,0,0 and 0,1,0.
# If used with an SMB-6000, use first two ports in the first card.


set iHub 0
set iSlot 1
set iPort 0

set iHub2 0
set iSlot2 2
set iPort2 0

#Set up the transmit parameters
#Interpacket gap is in units of microseconds (set by HTGapAndScale parameter.)
set gap 100
set burstSize 100000
set dataLength 60



#################################################################################
# - Checks that correct version of SmartLib Tcl interface is loaded.            #
# - If it is not loaded, attempt to load it.                                    #
#                                                                               #
#################################################################################

# If et1000.tcl is not loaded, attempt to locate it at the default location.
# The actual location is different on different platforms. 
if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
         set libPath "../../../../include/et1000.tcl"
}

# if "et1000.tcl" is not loaded, try to source it from the default path
if { ! [info exists __ET1000.TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
} else {   
               
         #Enter the location of the "et1000.tcl" file or enter "Q" or "q" to quit
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


#################################################################################
# - If chassis is not currently linked, prompt for IP address and then link.    #
#                                                                               #
#################################################################################

  
if {[ETGetLinkStatus] < 0} {
     puts "SmartBits not linked - Enter chassis IP address"
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]
     if { $retval < 0 } {
      puts "Unable to connect to $ipaddr. Please try again."
      exit
     }
}

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Reset the cards to the default values
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2


################################################################
# Set up IP packet contents                                    #
# - Broadcast packet will start                                #
#	FF FF FF FF FF FF FF 00 00 AA 00 00 20 08 00 45        #
#	00 00 2E 00 00 00 00 00 40 04 31 97 and so on          #
################################################################

# Catch will unset structure if it already exists
catch {unset filldata}

# Anything not explicitly set, will be set to zero
struct_new filldata Int*$dataLength

	       # set Destination MAC for broadcast FF FF FF FF FF FF
	       for {set i 0} {$i < 6} {incr i} {
                     set filldata($i.i) 0xFF
               }

	       # set Source MAC to 00 00 AA 00 00 20
	       set filldata(6.i) 0x00
               set filldata(7.i) 0x00
	       set filldata(8.i) 0xAA
               set filldata(9.i) 0x00
	       set filldata(10.i) 0x00
               set filldata(11.i) 0x20

	       # Ethertype 0800
	       set filldata(12.i) 0x08
               set filldata(13.i) 0x00

	       # Set the rest of IP Header
	       set filldata(14.i) 0x45
               set filldata(15.i) 0x00
	       set filldata(16.i) 0x00
               set filldata(17.i) 0x2E
	       set filldata(18.i) 0x00
               set filldata(19.i) 0x00
	       set filldata(20.i) 0x00
               set filldata(21.i) 0x00

	       # TTL = 64
	       set filldata(22.i) 0x40

	       # IP in IP Type = 4
               set filldata(23.i) 0x04

	       # Checksum = 3197
	       set filldata(24.i) 0x31
               set filldata(25.i) 0x97

	       # Source IP 192.148.100.1
	       set filldata(26.i) 0xC0
               set filldata(27.i) 0x94
	       set filldata(28.i) 0x64
               set filldata(29.i) 0x01

	       # Destination IP 192.158.100.1
	       set filldata(30.i) 0xC0
               set filldata(31.i) 0x9E
	       set filldata(32.i) 0x60
               set filldata(33.i) 0x01

puts "Sending fill data pattern to the card"
LIBCMD HTFillPattern $dataLength filldata $iHub $iSlot $iPort

# Free resources
unset filldata

#############################################################
# Set transmission paramters                                #
#                                                           #
# - Sends a single burst of BURST_SIZE packets              #
# - Interpacket gap is $GAP milliseconds long               #
#############################################################

puts "Setting transmission parameters"
LIBCMD HTDataLength $dataLength $iHub $iSlot $iPort
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $burstSize $iHub $iSlot $iPort
LIBCMD HTGapAndScale $gap $MICRO_SCALE $iHub $iSlot $iPort


# Set up for test, Clear existing group, if any
LIBCMD HGSetGroup ""

# Add cards to new group
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

# Create structure for counter data, catch error and unset if it already exists
catch {unset cs}
struct_new cs HTCountStructure*2

# Clear all counters with HGClearPort
LIBCMD HGClearPort

# Start Tx Card 1
# Will transmit in mode set by HTTransmitMode above (single burst)
puts "Transmitting..."
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

# Allow three seconds for counters to update, then get the counters
after 3000
LIBCMD HGGetCounters cs

# Wait until transmission stops (as long as transmit rate is NOT zero, we wait)
while { $cs(0.TmtPktRate) !=0 } {
        HGGetCounters cs
        after 5000
}

puts "Getting counter data"


# Display test results for both cards      


puts "------------------------------------------------------------"
puts "			Test Results"
puts "------------------------------------------------------------"
puts "    	        Card [expr $iSlot + 1]			Card [expr $iSlot2 +1]"
puts "------------------------------------------------------------"
puts "Tx Packets 	$cs(0.TmtPkt)		|	$cs(1.TmtPkt)"
puts "Rx Packets 	$cs(0.RcvPkt)		|	$cs(1.RcvPkt)"
puts "Collisions	$cs(0.Collision)		|	$cs(1.Collision)"
puts "Recvd Trigger	$cs(0.RcvTrig)		|	$cs(1.RcvTrig)"
puts "CRC Errors	$cs(0.CRC)		|  	$cs(1.CRC)"
puts "------------------------------------------------------------"
puts "Oversize 	$cs(0.Oversize) 		| 	$cs(1.Oversize)"
puts "Undersize	$cs(0.Undersize) 		| 	$cs(1.Undersize)"
puts "------------------------------------------------------------"

#Free Resources
unset cs

#UnLinks from the chassis 
puts "UnLinking from the chassis now"
LIBCMD NSUnLink
puts "DONE!"











