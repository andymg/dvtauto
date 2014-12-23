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

##########################################################################################
# ConvertCtoI:                                                                           #
# a procedure that returns the integer value of the given character.                     #
##########################################################################################
proc ConvertCtoI {cItem} {

	set iItem 0
	set cMin [format %c 0x00]
	set cMax [format %c 0xFF]

	if {$cItem == $cMin} {
		set iItem 0
	} elseif {$cItem == $cMax} {
		set iItem 255
	} else {
		scan $cItem %c iItem
	}

	return $iItem
}

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
set streamIP(ucActive) [format %c 1]
set streamIP(ucProtocolType) [format %c $STREAM_PROTOCOL_IP]
set streamIP(uiFrameLength) $DataLength
set streamIP(TimeToLive) [format %c 10]
set streamIP(Protocol) 4

set streamIP(DestinationMAC.0.uc) [format %c 1]
set streamIP(DestinationMAC.1.uc) [format %c 1]
set streamIP(DestinationMAC.2.uc) [format %c 1]
set streamIP(DestinationMAC.3.uc) [format %c 1]
set streamIP(DestinationMAC.4.uc) [format %c 1]
set streamIP(DestinationMAC.5.uc) [format %c 1]

set streamIP(SourceMAC.0.uc) [format %c 5]
set streamIP(SourceMAC.1.uc) [format %c 5]
set streamIP(SourceMAC.2.uc) [format %c 5]
set streamIP(SourceMAC.3.uc) [format %c 5]
set streamIP(SourceMAC.4.uc) [format %c 5]
set streamIP(SourceMAC.5.uc) [format %c 5]

set streamIP(DestinationIP.0.uc) [format %c 10]
set streamIP(DestinationIP.1.uc) [format %c 100]
set streamIP(DestinationIP.2.uc) [format %c 10]
set streamIP(DestinationIP.3.uc) [format %c 1]

set streamIP(SourceIP.0.uc) [format %c 10]
set streamIP(SourceIP.1.uc) [format %c 100]
set streamIP(SourceIP.2.uc) [format %c 20]
set streamIP(SourceIP.3.uc) [format %c 2]


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
set streamIP(DestinationMAC.5.uc) [format %c 1]

#Copy 9 more IP streams to the TX Card, based on the first stream, and delete stream structure.
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 9 0 streamIP 0 $TxHub $TxSlot $TxPort
unset streamIP


###########################################################################################
#Prepare transmition.                                                                     #
###########################################################################################

#Set burst count to 20, and transmit mode to SINGLE_BURST_MODE, on the Tx card.
LIBCMD HTBurstCount $BurstCount $TxHub $TxSlot $TxPort
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $TxHub $TxSlot $TxPort

#Prepare capture on the Rx card.
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $RxHub $RxSlot $RxPort
unset cap

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $RxHub $RxSlot $RxPort

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
    set CapData(ulFrameIndex)       [expr $i-1]
    set CapData(ulRequestedLength)  [expr $DataLength + 4]
    
    #Get captured data, starting at index 0.
    LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 CapData 0 $RxHub $RxSlot $RxPort

    #Display captured data: the length of a packet should be = DataLength + 4-byte CRC.
    for {set j 0} {$j < $CapData(ulRetrievedLength)} {incr j} {
	set iData 0
	if {[expr $j % 16] == 0} {
	    puts ""
	    puts -nonewline [format "%4i:   " $j]
	}
	set iData [ConvertCtoI $CapData(ucData.$j.uc)] ; 
	puts -nonewline [format " %02X" $iData]
	
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




