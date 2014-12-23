################################################################################### 
#L3Extension.tcl                                                                  #
#                                                                                 #
# Program tested against one POS-3500A and POS -3500B in a SmartBits 600          #
#                                                                                 #
# ASSUMES:                                                                        #
# - POS cards are connected back to back.                                         #
#                                                                                 #
# NOTE: This script works on the following cards:                                 #
#       - POS-6500/6502                                                           #
#       - POS-3505A/3504A                                                         #
#                                                                                 #
###################################################################################


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
set DATA_LENGTH 1000
set CARDS_IN_GROUP 2

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Add the cards to the group
HGSetGroup ""
HGAddtoGroup $iHub $iSlot $iPort
HGAddtoGroup $iHub2 $iSlot2 $iPort2

# Check both cards belong to group before testing.
puts "Checking group membership"
for { set i 0 } { $i < $CARDS_IN_GROUP } { incr i } {
      if { [HGIsHubSlotPortInGroup $iHub $i $iPort] < 1 } {
           puts "Card [expr $i + 1] is not in group"
      }
}


# Set Line Configuration Parameters
struct_new MyLineCfg POSCardLineConfig

   set MyLineCfg(ucCRC32Enabled) [format %c 0]
   set MyLineCfg(ucScramble) [format %c 1]

LIBCMD HTSetStructure $POS_CARD_LINE_CONFIG 0 0 0 MyLineCfg 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $POS_CARD_LINE_CONFIG 0 0 0 MyLineCfg 0 $iHub2 $iSlot2 $iPort2

#UnSet the structure
unset MyLineCfg

# Set Encapsulation 
struct_new MyEncap POSCardPortEncapsulation

   set MyEncap(ucEncapStyle) [format %c $PROTOCOL_ENCAP_TYPE_STD_PPP]

LIBCMD HTSetStructure $POS_CARD_PORT_ENCAP 0 0 0 MyEncap 0 $iHub $iSlot $iPort
LIBCMD HTSetStructure $POS_CARD_PORT_ENCAP 0 0 0 MyEncap 0 $iHub2 $iSlot2 $iPort2

#Unset the structure
unset MyEncap



# Define IP Stream - Same as Ml-7710
struct_new streamIP StreamIP

        set streamIP(ucActive) [format %c 1]
        set streamIP(ucProtocolType) [format %c $L3_STREAM_IP]
        set streamIP(uiFrameLength) $DATA_LENGTH
        set streamIP(ucTagField) [format %c 1]
        set streamIP(DestinationMAC.0.uc) [format %c 0]
        set streamIP(DestinationMAC.1.uc) [format %c 0]
        set streamIP(DestinationMAC.2.uc) [format %c 0]
        set streamIP(DestinationMAC.3.uc) [format %c 0]
        set streamIP(DestinationMAC.4.uc) [format %c 2]
        set streamIP(DestinationMAC.5.uc) [format %c 0]
        set streamIP(SourceMAC.0.uc) [format %c 0]
        set streamIP(SourceMAC.1.uc) [format %c 0]
        set streamIP(SourceMAC.2.uc) [format %c 0]
        set streamIP(SourceMAC.3.uc) [format %c 0]
        set streamIP(SourceMAC.4.uc) [format %c 1]
        set streamIP(SourceMAC.5.uc) [format %c 0]
        set streamIP(TypeOfService) [format %c 0]
        set streamIP(TimeToLive) [format %c 10]
        set streamIP(DestinationIP.0.uc) [format %c 10]
        set streamIP(DestinationIP.1.uc) [format %c 2]
        set streamIP(DestinationIP.2.uc) [format %c 1]
        set streamIP(DestinationIP.3.uc) [format %c 10]
        set streamIP(SourceIP.0.uc) [format %c 10]
        set streamIP(SourceIP.1.uc) [format %c 1]
        set streamIP(SourceIP.2.uc) [format %c 1]
        set streamIP(SourceIP.3.uc) [format %c 10]
        set streamIP(Netmask.0.uc) [format %c 255]
        set streamIP(Netmask.1.uc) [format %c 255]
        set streamIP(Netmask.2.uc) [format %c 255]
        set streamIP(Netmask.3.uc) [format %c 0]
        set streamIP(Gateway.0.uc) [format %c 10]
        set streamIP(Gateway.1.uc) [format %c 1]
        set streamIP(Gateway.2.uc) [format %c 1]
        set streamIP(Gateway.3.uc) [format %c 1]
        set streamIP(Protocol) [format %c 4]

#Set the stream on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

	
	# Flip source and destination for card 2
        set streamIP(DestinationMAC.4.uc) [format %c 1]
        set streamIP(SourceMAC.4.uc) [format %c 2]
        set streamIP(DestinationIP.1.uc) [format %c 1]
        set streamIP(SourceIP.1.uc) [format %c 2]
        set streamIP(Gateway.1.uc) [format %c 2]

#Set the stream on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub2 $iSlot2 $iPort2

#Unset the structure
unset streamIP

#######################################################################################################
# Define stream extension                                                                             #
# - Multiburst mode with Burst Count of 10,000 and an MBurstCount of 2 sends two 10,000 packet bursts #
#######################################################################################################

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
HGStart
after 2000
HGGetCounters cs

#Pause for 1 second
after 1000

#Get the counters
HGGetCounters cs

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

#Unset the structure
unset cs

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"


