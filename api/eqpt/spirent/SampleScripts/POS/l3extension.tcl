##################################################################
# L3Extension.tcl                                                #
#                                                                #
# Program tested against two POS-3500As in a SmartBits 600       #
#                                                                #
# NOTE: This script works on the following cards:                #
#       - POS-6500/6502                                          #
#       - POS-3505A/3504A                                        #
#                                                                #
##################################################################


if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/smartlib.tcl"
} else {
         set libPath "../../../../include/smartlib.tcl"
}

# if it is not loaded, try to source it at the default path
if { ! [info exists __SMARTLIB_TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
   } else {   
               
            # Enter the location of the "smartlib.tcl" file or enter "Q" or "q" to quit
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

LIBCMD NSEnableAutoDefaults

set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 1
set iPort2 0

set DATA_LENGTH 1000
set CARDS_IN_GROUP 2

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Set up group
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2

# Check both cards belong to group before testing.
puts "Checking group membership"
for { set i 0 } { $i < $CARDS_IN_GROUP } { incr i } {
      if { [HGIsHubSlotPortInGroup $iHub $i $iPort] < 1 } {
           puts "Card [expr $i + 1] is not in group"
      }
}

# Set Line Configuration Parameters
LIBCMD HTSetStructure $POS_CARD_LINE_CONFIG 0 0 0 - 0 $iHub $iSlot $iPort \
       -ucCRC32Enabled 0 -ucScramble 1
LIBCMD HTSetStructure $POS_CARD_LINE_CONFIG 0 0 0 - 0 $iHub2 $iSlot2 $iPort2 \
       -ucCRC32Enabled 0 -ucScramble 1

# Set Encapsulation 
LIBCMD HTSetStructure $POS_CARD_PORT_ENCAP 0 0 0 - 0 $iHub $iSlot $iPort \
       -ucEncapStyle $PROTOCOL_ENCAP_TYPE_STD_PPP
LIBCMD HTSetStructure $POS_CARD_PORT_ENCAP 0 0 0 - 0 $iHub2 $iSlot2 $iPort2 \
       -ucEncapStyle $PROTOCOL_ENCAP_TYPE_STD_PPP

############################################
# Define IP Stream                         #
#                                          #
# - Same as Ml-7710                        #
############################################

LIBCMD HTDefaultStructure $L3_DEFINE_IP_STREAM StreamIP 0 $iHub $iSlot $iPort
        # you can put these values into the smartlib.dft file
        # so you don't have to do it here.
        set StreamIP(uiFrameLength) $DATA_LENGTH
        set StreamIP(ucTagField) 1
        set StreamIP(DestinationMAC} {0 0 0 0 0 0}
        set StreamIP(SourceMAC) {0 0 0 0 1 0}
        set StreamIP(DestinationIP) {10 2 1 10}
        set StreamIP(TimeToLive) 10
        set StreamIP(SourceIP) {10 1 1 10}
        set StreamIP(Netmask) {255 255 255 0}
        set StreamIP(Gateway) {10 1 1 1}
	set StreamIP(Protocol) 4

LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 StreamIP 0 $iHub $iSlot $iPort

	#######################################
	# Flip source and destination for     #
	# card 2                              #
	#######################################

LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 StreamIP 0 $iHub2 $iSlot2 $iPort2 \
        -DestinationMAC {0 0 0 0 1 0} \
        -SourceMAC {0 0 0 0 2 0} \
        -DestinationIP {10 1 1 10} \
        -SourceIP {10 2 1 10} \
        -Gateway {10 2 1 1}

unset StreamIP

############################################################
# Define stream extension                                  #
# Multiburst mode with Burst Count of 10,000               #
# and an MBurstCount of 2 sends two 10,000 packet bursts   #
############################################################

struct_new extensionIP L3StreamExtension

       set extensionIP(ulFrameRate) 10000
       set extensionIP(ulTxMode) $L3_MULTIBURST_MODE
       set extensionIP(ulBurstCount) 10000
       set extensionIP(ulMBurstCount) 2
       set extensionIP(ulBGPatternIndex) 0
       set extensionIP(ulBurstGap) 0
       set extensionIP(uiInitialSeqNumber) 0

#Set extended stream parameters
LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 extensionIP 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 extensionIP 0 $iHub2 $iSlot2 $iPort2

#Unset the structure
unset extensionIP

# Clear counters with HGClearPort and create Counter Strucutres to hold count data

LIBCMD HGClearPort

struct_new cs HTCountStructure*2

# Start transmission with HGStart

LIBCMD HGStart
after 3000

LIBCMD HGGetCounters cs

after 1000

LIBCMD HGGetCounters cs

############################################
# Display test results for both cards      #
############################################

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

#Unset the structure
unset cs

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"


