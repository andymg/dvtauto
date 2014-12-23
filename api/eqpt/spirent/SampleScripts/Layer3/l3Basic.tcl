####################################################################################
#                                                                                  # 
# L3Basic.tcl                                                                      #
#                                                                                  #
# - This sample creates 10 IP streams (frame blue-prints), and sends out a single  #
#   burst of 20 IP frames. It will then display the packets captured on the        #
#   receiver.                                                                      #
# - This sample applies to SmartMetrics cards that handle stream generation,       #
#   including ML-7710 and LAN-6101A. It uses the first two Ethernet ports in a     #
#   chassis, connected back to back.                                               #
#                                                                                  #
# NOTE: This script works on the following cards:                                  #
#       - L3-67XX                                                                  #
#       - ML-7710                                                                  #
#       - ML-5710                                                                  #
#       - LAN-6101A                                                                #
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

#Define variables
set TxHub 0
set TxSlot 0
set TxPort 0
set RxHub 0
set RxSlot 1
set RxPort 0

set DataLength 60
set BurstCount 20

#Define Structures
struct_new StreamCount ULong
struct_new TxCounters HTCountStructure
struct_new RxCounters HTCountStructure

###########################################################################################
# Reserve cards                                                                           #
###########################################################################################

puts "Reserving Tx and Rx cards ..."
LIBCMD HTSlotReserve $TxHub $TxSlot
LIBCMD HTSlotReserve $RxHub $RxSlot

###########################################################################################
# Reset cards                                                                             #
###########################################################################################

puts "Resetting Tx and Rx cards ..."
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $RESET_FULL $RxHub $RxSlot $RxPort

###########################################################################################
# Clear Counters                                                                          #
###########################################################################################

puts "Clearing counters for Tx and Rx cards ..."
LIBCMD HTClearPort $TxHub $TxSlot $TxPort
LIBCMD HTClearPort $RxHub $RxSlot $RxPort

###########################################################################################
# Define One IP stream on Tx Card.                                                        #
###########################################################################################

puts "Defining one IP stream ..."

#Declare IP stream structure
struct_new streamIP StreamIP

#Define IP stream contents
set streamIP(ucActive) 1
set streamIP(ucProtocolType) $STREAM_PROTOCOL_IP
set streamIP(uiFrameLength) $DataLength
set streamIP(TimeToLive) 10
set streamIP(Protocol) 4

set streamIP(DestinationMAC) {1 1 1 1 1 1}
set streamIP(SourceMAC) {5 5 5 5 5 5}
set streamIP(DestinationIP) {10 100 10 1}
set streamIP(SourceIP) {10 100 20 2}

#Set Stream definition to the TX Card, starting at index 1, and delete streamIP structure.
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $TxHub $TxSlot $TxPort
unset streamIP


###########################################################################################
#Define 9 more streams on TX card, based on the first stream.                             #
#Also, increment the Destination MAC address in each additional stream by 1.              #
#Therefore,                                                                               #
#The first stream has a Destination MAC address of 1 1 1 1 1 1 (as defined above);        #
#The second stream has a Destination MAC address of 1 1 1 1 1 2;                          #
#The third stream has a Destination MAC address of 1 1 1 1 1 3, etc..                     #
###########################################################################################

puts "Defining 9 more IP Streams ..."

#Declare IP stream structure
struct_new streamIP StreamIP

#Define IP fields wish to increment, and the value to increment by.
set streamIP(DestinationMAC) {0 0 0 0 0 1}

#Copy 9 more IP streams to the TX Card, based on the first stream, and delete stream structure.
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 9 0 streamIP 0 $TxHub $TxSlot $TxPort
unset streamIP


###########################################################################################
#Prepare transmition.                                                                     #
###########################################################################################

#Set burst count to 20, and transmit mode to SINGLE_BURST_MODE, on the Tx card.
LIBCMD HTBurstCount $BurstCount $TxHub $TxSlot $TxPort
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $TxHub $TxSlot $TxPort

# Capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $RxHub $RxSlot $RxPort
unset cap

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $RxHub $RxSlot $RxPort
after 2000

###########################################################################################
#Transmit 20 packets to the Rx Card, and read counters after transmition.                 #
#Note: the current transmit mode is set to single burst of 20 packets. Therefore, we don't#
#      need to use "HTRun $HTSTOP $TxHub $TxSlot $TxPort" to stop the traffic.            #
###########################################################################################

puts "Tranmsitting 20 packets ..."
#Transmit, and stop transmit after 1 second.
LIBCMD HTRun $HTRUN $TxHub $TxSlot $TxPort

# Wait for one second to allow packets to transmit. 
LIBCMD NSDelay 1

#Wait for one second to allow counters to be updated.
LIBCMD NSDelay 1

# Stop capture
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $RxHub $RxSlot $RxPort

#Get Counters from both Tx Card and Rx Card.
puts "Reading counters ..."
LIBCMD HTGetCounters TxCounters $TxHub $TxSlot $TxPort
LIBCMD HTGetCounters RxCounters $RxHub $RxSlot $RxPort


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




