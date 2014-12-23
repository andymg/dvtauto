####################################################################################
# L3PngCount.tcl                                                                   #
#                                                                                  #
# - Sets up the L3Stack on the 7710 card in slot 1.                                #
#                                                                                  #
# - Will ping address 192.168.99.13.                                               #
#                                                                                  #
# - The ML-7710 will arp for the MAC of the ping target.  If the                   #
#   ping target does not respond (another ML-7710 connected back-to-back           #                            
#   will NOT reply to the ARP normally) it will continue ARPing for the            #
#   MAC. This will blink the transmit light on the sending card                    #
#   but will not increment the ping counts.                                        #
#                                                                                  #
# - If you set the receiving card to respond to all ARPs (iGeneralIPResponse) = 1  #
#   then it will respond the the sending card's ARP and the sending card           #
#   will continue sending ICMP Pings.  Note that the MAC address in the ARP        #
#   response will NOT be the MAC of the stack or any configured streams, but will  #
#   be of the form 00 00 01 00 5A.                                                 # 
#                                                                                  #
# NOTE: This script works on the following cards:                                  #
#       - L3-67XX                                                                  #
#       - ML-7710                                                                  #
#       - ML-5710                                                                  #
#       - LAN-6101A                                                                #
#       - LAN-3300A/3301A                                                          #
#       - LAN-3310A/3311A                                                          #
#       - POS-6500/6502                                                            #
#       - POS-3505A/3504A                                                          #
#                                                                                  #       
####################################################################################


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

set NUM_STREAMS 10
set DATA_LENGTH 60

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

#Set the speed and the Duplex mode
LIBCMD HTSetSpeed $SPEED_10MHZ $iHub $iSlot $iPort
LIBCMD HTSetSpeed $SPEED_10MHZ $iHub2 $iSlot2 $iPort2
LIBCMD HTDuplexMode $HALFDUPLEX_MODE $iHub $iSlot $iPort
LIBCMD HTDuplexMode $HALFDUPLEX_MODE $iHub2 $iSlot2 $iPort2

#Transmit packets 
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount 100 $iHub $iSlot $iPort

#Clear Ports
LIBCMD HTClearPort $iHub $iSlot $iPort
LIBCMD HTClearPort $iHub2 $iSlot2 $iPort2

#Declare an IP Stream
struct_new streamIP StreamIP

set streamIP(ucActive) [format %c 1]
set streamIP(ucProtocolType) [format %c $L3_STREAM_IP]
set streamIP(uiFrameLength) $DATA_LENGTH
set streamIP(ucRandomLength) [format %c 1]
set streamIP(ucTagField) [format %c 1]
set streamIP(DestinationMAC.0.uc) [format %c 0]
set streamIP(DestinationMAC.1.uc) [format %c 0]
set streamIP(DestinationMAC.2.uc) [format %c 0]
set streamIP(DestinationMAC.3.uc) [format %c 0]
set streamIP(DestinationMAC.4.uc) [format %c 1]
set streamIP(DestinationMAC.5.uc) [format %c 0]
set streamIP(SourceMAC.0.uc) [format %c 0]
set streamIP(SourceMAC.1.uc) [format %c 0]
set streamIP(SourceMAC.2.uc) [format %c 0]
set streamIP(SourceMAC.3.uc) [format %c 0]
set streamIP(SourceMAC.4.uc) [format %c 0]
set streamIP(SourceMAC.5.uc) [format %c 1]
set streamIP(TimeToLive) [format %c 10]
set streamIP(DestinationIP.0.uc) [format %c 192]
set streamIP(DestinationIP.1.uc) [format %c 158]
set streamIP(DestinationIP.2.uc) [format %c 100]
set streamIP(DestinationIP.3.uc) [format %c 1]
set streamIP(SourceIP.0.uc) [format %c 192]
set streamIP(SourceIP.1.uc) [format %c 148]
set streamIP(SourceIP.2.uc) [format %c 100]
set streamIP(SourceIP.3.uc) [format %c 1]
set streamIP(Protocol) [format %c 4]

#Set the IP Stream on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Unset the structure
unset streamIP

#Set multiple streams on the card by incrementing SourceMAC and SourceIP
struct_new incrementIP StreamIP

set incrementIP(SourceMAC.5.uc) [format %c 1]
set incrementIP(SourceIP.3.uc) [format %c 1]

#Set multiple streams on the card
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $NUM_STREAMS - 1] 0 incrementIP 0 $iHub $iSlot $iPort
unset incrementIP

struct_new addr Layer3Address
####################################################
# Layer 3 Card MAC Address                         #
####################################################
set addr(szMACAddress.0.uc) [format %c 1]
set addr(szMACAddress.1.uc) [format %c 1]
set addr(szMACAddress.2.uc) [format %c 1]
set addr(szMACAddress.3.uc) [format %c 1]
set addr(szMACAddress.4.uc) [format %c 1]
set addr(szMACAddress.5.uc) [format %c 1]

#####################################################
#  Layer 3 Card IP Address                          #
#####################################################
set addr(IP.0.uc) [format %c 192]
set addr(IP.1.uc) [format %c 168]
set addr(IP.2.uc) [format %c 99]
set addr(IP.3.uc) [format %c 13]

set addr(iControl) 0x07  ;# enable all type of responses
LIBCMD HTLayer3SetAddress addr $iHub2 $iSlot2 $iPort2

# Setup the first card to send Pings

######################################################
# Layer 3 Card MAC Address                           #
######################################################
set addr(szMACAddress.0.uc) [format %c 0]
set addr(szMACAddress.1.uc) [format %c 0]
set addr(szMACAddress.2.uc) [format %c 0]
set addr(szMACAddress.3.uc) [format %c 0]
set addr(szMACAddress.4.uc) [format %c 1]
set addr(szMACAddress.5.uc) [format %c 1]

#######################################################
#  Layer 3 Card IP Address                            #
#######################################################
set addr(IP.0.uc) [format %c 192]
set addr(IP.1.uc) [format %c 168]
set addr(IP.2.uc) [format %c 99]
set addr(IP.3.uc) [format %c 3]

#######################################################
#   Layer 3 Card Netmask                              #
#######################################################
set addr(Netmask.0.uc) [format %c 255]
set addr(Netmask.1.uc) [format %c 255]
set addr(Netmask.2.uc) [format %c 255]
set addr(Netmask.3.uc) [format %c 0]

#######################################################
#  Layer 3 Card Gateway Address                       #
#######################################################
set addr(Gateway.0.uc) [format %c 192]
set addr(Gateway.1.uc) [format %c 168]
set addr(Gateway.2.uc) [format %c 99]
set addr(Gateway.3.uc) [format %c 1]

#######################################################
#  Layer 3 Card Ping Target                           #
#######################################################
set addr(PingTargetAddress.0.uc) [format %c 192]
set addr(PingTargetAddress.1.uc) [format %c 168]
set addr(PingTargetAddress.2.uc) [format %c 99]
set addr(PingTargetAddress.3.uc) [format %c 13]

#######################################################
# iControl is a bit field that enables and disables   #
# the various types.  Can be set all on with 0x7      #
# or all off with 0, or controlled individually by    #
# setting the correct bit values                      #
# FROM L3ITEMS.H                                      #
# /* defines for the iControl variable */             #
#	define L3_CTRL_ARP_RESPONSES		0x01  #
#	define L3_CTRL_PING_RESPONSES		0x02  #
#	define L3_CTRL_SNMP_OR_RIP_RESPONSES	0x04  #
#######################################################
#set addr(iControl) 0x7  ;# enable all types of responses
#set addr(iControl) 0x0  ;# disable all types of responses
set addr(iControl) 0x02  ;# enable pings only
set addr(iPingTime) 1   ;# ping the gateway every 1/10 second for 7710
set addr(iSNMPTime) 0   ;# make an snmp request every every 2/10 sec for 7710
set addr(iRIPTime) 0            ;# send a RIP frame every 3 seconds

LIBCMD HTLayer3SetAddress addr $iHub $iSlot $iPort
 
# Setup EnhancedCounterStructure and initialize
struct_new MyCount  EnhancedCounterStructure
 set MyCount(iMode) 0 
 set MyCount(ulMask1) [expr $SMB_STD_TXFRAMES + $SMB_STD_RXFRAMES]
 set MyCount(ulMask2) [expr $L3_TX_STACK + $L3_RX_STACK + $L3_PINGREP_SENT + $L3_PINGREQ_SENT + $L3_PINGREQ_RECV + $L3_ARP_REQ + $L3_ARP_REPLIES ]


# send a burst and wait two seconds
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort 

after 6000
set addr(iControl) 0x00  ;# disable all type of responses
LIBCMD HTLayer3SetAddress addr $iHub2 $iSlot2 $iPort2

set addr(iControl) 0x00  ;# disable all type of responses
LIBCMD HTLayer3SetAddress addr $iHub $iSlot $iPort
unset addr

after 1000 
puts "Retrieving Counter Data"

##################################################################################
# - Currently the integer conversions are only defined for ulMask1               #
# - The ISMB values for Tx and Rx frames are an example of the int conversions.  #
# - Conversions for Mask 2 - as in (ulData.x.ul) where x is:                     #
#   - L3 TX from Stack	  37                                                     #
#   - L3 Rx to Stack   	  38                                                     #
#   - L3 ARP Requests	  39                                                     #
#   - L3 ARP Replies	  41                                                     #
#   - Ping Requests Sent  43                                                     #
##################################################################################

LIBCMD HTGetEnhancedCounters MyCount $iHub $iSlot $iPort 
puts "*********************************************************"
puts " Test Results             Slot [expr $iSlot +1]    "
puts "*********************************************************"
puts "[format "%-24s" "Transmitted Frames"] [format %6d $MyCount(ulData.$ISMB_STD_TXFRAMES.ul)]"
puts "[format "%-24s" "Received Frames"] [format %6d $MyCount(ulData.$ISMB_STD_RXFRAMES.ul)]"
puts "[format "%-24s" "Tx Frames from Stack"] [format %6d $MyCount(ulData.37.ul)]"
puts "[format "%-24s" "Rx Frames to Stack"] [format %6d $MyCount(ulData.38.ul)]"
puts "[format "%-24s" "ARP Requests Sent"] [format %6d $MyCount(ulData.39.ul)]"
puts "[format "%-24s" "ARP Replies Sent"] [format %6d $MyCount(ulData.41.ul)]"
puts "[format "%-24s" "Ping Requests Sent"] [format %6d $MyCount(ulData.43.ul)]"
puts "*********************************************************"

LIBCMD HTGetEnhancedCounters MyCount $iHub2 $iSlot2 $iPort2 
puts "*********************************************************"
puts " Test Results             Slot [expr $iSlot2 +1]    "
puts "*********************************************************"
puts "[format "%-24s" "Transmitted Frames"] [format %6d $MyCount(ulData.$ISMB_STD_TXFRAMES.ul)]"
puts "[format "%-24s" "Received Frames"] [format %6d $MyCount(ulData.$ISMB_STD_RXFRAMES.ul)]"
puts "[format "%-24s" "Tx Frames from Stack"] [format %6d $MyCount(ulData.37.ul)]"
puts "[format "%-24s" "Rx Frames to Stack"] [format %6d $MyCount(ulData.38.ul)]"
puts "[format "%-24s" "ARP Requests Sent"] [format %6d $MyCount(ulData.39.ul)]"
puts "[format "%-24s" "ARP Replies Sent"] [format %6d $MyCount(ulData.41.ul)]"
puts "[format "%-24s" "Ping Requests Sent"] [format %6d $MyCount(ulData.43.ul)]"
puts "*********************************************************"

#Unset the structure
unset MyCount

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"



