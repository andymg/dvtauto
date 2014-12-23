####################################################################################
#                                                                                  # 
# L3_IPv6.tcl                                                                      #
#                                                                                  #
# - This sample creates 10 IPv6 streams and sends out a single                     #
#   burst of 20 IP frames. It will then display the packets captured on the        #
#   receiver.                                                                      #
# - This sample applies to LAN6101 and all TeraMetrics cards.                      #
#   It uses the first two ports in a chassis                                       #
#   chassis, connected back to back.                                               #
#   (Tested with POS-3505, LAN-3310, LAN-3101)                                                                               #
#                                                                                  #
#                                                                                  #
#                                                                                  #
####################################################################################

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

set TxHub        0
set TxSlot       0
set TxPort       0

set RxHub       0
set RxSlot      1
set RxPort      0

set DataLength 100
set BurstCount 20

#Define Structures
struct_new StreamCount ULong
struct_new TxCounters HTCountStructure
struct_new RxCounters HTCountStructure

###########################################################################################
# Reset cards                                                                             #
###########################################################################################
LIBCMD HTSlotReserve $TxHub $TxSlot
LIBCMD HTSlotReserve $RxHub $RxSlot

LIBCMD HTResetPort $::RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $::RESET_FULL $RxHub $RxSlot $RxPort	

###########################################################################################
# Clear Counters                                                                          #
###########################################################################################
LIBCMD HTClearPort $TxHub $TxSlot $TxPort
LIBCMD HTClearPort $RxHub $RxSlot $RxPort

###########################################################################################
# Define IPv6 Stream on Tx Card 	                				  #
###########################################################################################
puts "Defining one IPv6 stream ..."

#Declare IP stream structure
struct_new streamIPv6 StreamIPv6

#Define IPv6 stream contents
set streamIPv6(ucActive) 1
set streamIPv6(ucProtocolType) $STREAM_PROTOCOL_IPV6
set streamIPv6(uiFrameLength) $DataLength
set streamIPv6(ucTagField) 1

set streamIPv6(DestinationMAC) {1 1 1 1 1 1}
set streamIPv6(SourceMAC) {6 6 6 6 6 6}
set streamIPv6(DestinationIP) {0 0 0 0 0 0 0 0 0 0 0 0 192 168 100 10}
set streamIPv6(SourceIP) {0 0 0 0 0 0 0 0 0 0 0 0 10 100 10 10}
set streamIPv6(RouterIP) {0 0 0 0 0 0 0 0 0 0 0 0 192 168 100 1}

###########################################################################################
# Some IPv6 Next Header Options,0 = hop by hop, 60 = destination options, 43 = routing,   #
# 44 = fragment ,50 = ESP Ecapsulating Security Payload ,51 = authentication              #
###########################################################################################
set streamIPv6(ucNextHeader) 60

# Similar to TOS in IPv4 8 bits (experimental)
set streamIPv6(ucTrafficClass) 0

# Similar to IPv4 Time To Live (TTL) 
set streamIPv6(ucHopLimit) 64

# Flow Labels, Traffic Class and Dfferentiated Services
set streamIPv6(ulFlowLabel) 0

# Zero calculates correct Payload Length value
set streamIPv6(ucPayloadLengthError) 0  

#Set Stream definition to the TX Card, starting at index 1, and delete streamIP structure.
LIBCMD HTSetStructure $L3_DEFINE_IPV6_STREAM 0 0 0 streamIPv6 0 $TxHub $TxSlot $TxPort
unset streamIPv6


###########################################################################################
#Define 9 more streams on TX card, based on the first stream.                             #
#Also, increment the Destination MAC address in each additional stream by 1.              #
#Therefore,                                                                               #
#The first stream has a Destination MAC address of 1 1 1 1 1 1 (as defined above);        #
#The second stream has a Destination MAC address of 1 1 1 1 1 2;                          #
#The third stream has a Destination MAC address of 1 1 1 1 1 3, etc..                     #
###########################################################################################

puts "Defining 9 more IPv6 Streams ..."

#Declare IPv6 stream structure
struct_new streamIPv6 StreamIPv6

#Define IP fields wish to increment, and the value to increment by.
set streamIPv6(DestinationMAC) {0 0 0 0 0 1}

#Copy 9 more IP streams to the TX Card, based on the first stream, and delete stream structure.
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IPV6_STREAM 1 9 0 streamIPv6 0 $TxHub $TxSlot $TxPort
unset streamIPv6

###########################################################################################
#Prepare transmition.                                                                     #
###########################################################################################

#Set burst count to 20, and transmit mode to SINGLE_BURST_MODE, on the Tx card.
LIBCMD HTBurstCount $BurstCount $TxHub $TxSlot $TxPort
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $TxHub $TxSlot $TxPort

###########################################################################################
# Prepare capture on the Rx card.	                				  #
###########################################################################################
struct_new CapSetup NSCaptureSetup
set CapSetup(ulCaptureMode) $::CAPTURE_MODE_FILTER_ON_EVENTS
set CapSetup(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 CapSetup 0 $RxHub $RxSlot $RxPort
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $RxHub $RxSlot $RxPort 
unset CapSetup

#Transmit 20 packets to the Rx Card, and read counters after transmition.                
puts "Transmitting 20 packets ..."
#Transmit, and stop transmit after 1 second.
LIBCMD HTRun $HTRUN $TxHub $TxSlot $TxPort

# Wait for one second to allow packets to transmit. 
LIBCMD NSDelay 1


#Get Counters from both Tx Card and Rx Card.
puts "Reading counters ..."
LIBCMD HTGetCounters TxCounters $TxHub $TxSlot $TxPort
LIBCMD HTGetCounters RxCounters $RxHub $RxSlot $RxPort

#Stop Capture
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $RxHub $RxSlot $RxPort 
###########################################################################################
#Display Counters.                                                                        #
###########################################################################################

puts ""
puts "---------------------------------------------------------------"
puts "TX transmitted: $TxCounters(TmtPkt)                                          "
puts "RX    received: $RxCounters(RcvPkt)                                          "
puts "---------------------------------------------------------------"

###########################################################################################
#Display Packets captured by Rx card.                                                     #
###########################################################################################

#Get number of packets captured by Rx card.
struct_new CapCount NSCaptureCountInfo
LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $RxHub $RxSlot $RxPort
set PacketCount $CapCount(ulCount)
unset CapCount

#Display packets.

puts ""
for {set i 1} {$i <= $PacketCount} {incr i} {
    puts "Displaying packet number $i of $PacketCount: "
    puts "---------------------------------------------------------------"
    
    #Define a structure to store captured data
    struct_new CapData NSCaptureDataInfo
    set CapData(ulFrameIndex)      [expr $i-1]
    
    #Get captured data, starting at index 0.
    LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 CapData 0 $RxHub $RxSlot $RxPort

    #Display captured data: the length of a packet = DataLength + 4-byte CRC.
    for {set j 0} {$j < [expr $DataLength + 4]} {incr j} {
	if {[expr $j % 16] == 0} {
	    puts ""
	    puts -nonewline [format "%4i:   " $j]
	}
	puts -nonewline [format " %02X" $CapData(ucData.$j._ubyte_)]
    }
    puts ""
    puts "---------------------------------------------------------------"
    puts ""
    if {$i < [expr $PacketCount]} {
	puts "Press ENTER to display next packet, or q to Stop."
	gets stdin response
	if {$response == "q" || $response == "Q"} {
	    unset CapData
	    exit
	}
    } else {
	puts "END."
    }
    unset CapData
}


#Unlink Chassis
LIBCMD ETUnLink

