####################################################################################
#                                                                                  # 
# ATMTMBasic.tcl                                                                   #
#                                                                                  #
# - This sample applies to ATM 3451/3453 cards. It uses the first slot in a        #
#   chassis, connected back to back.                                               #
# - This sample creates 4 VCs, 12 IP streams with OC3 speed port. Each VC is bound #
#   with 3 IP streams, and sends out a single burst of 3 IP frames. It will then   #
#   display the packets captured on the receiver.                                  #                                                                    #
#                                                                                  #
# NOTE: This script works on the following cards:                                  #
#       - ATM-3451/3453  with SmartLib 3.50, TM 3.60.42/TM 4.00                    #
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
set TxSlot 1
set TxPort 0
set RxHub 0
set RxSlot 1
set RxPort 1

set DataLength       64

set VCCount          4
set StreamCountPerVC 3
set StreamCountTotal [expr $StreamCountPerVC * $VCCount]

set BurstCountPerVC  $StreamCountPerVC
set PacketCount      [expr $VCCount * $BurstCountPerVC ]

set atmFlag          $AT_CLP_OFF

###########################################################################################
# Reserve cards                                                                           #
# TxSlot and RxSlot are the same in this script so that only reserve TxSlot               #
###########################################################################################

puts "Reserving Tx and Rx cards ..."
LIBCMD HTSlotReserve $TxHub $TxSlot 

###########################################################################################
# Reset cards                                                                             #
###########################################################################################

puts "Resetting Tx and Rx cards ..."
LIBCMD HTResetPort $RESET_FULL $RxHub $RxSlot $RxPort
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort
after 2000

###########################################################################################
# Config ATM ports.                                                                       #
#                                                                                         #
# Note for the ucTxClockSource                                                            #
#     Time synchronization is an important part of SONET/SDH. Either a NE(Network Element,#
#     Switch or end station) would use timeoff the line(fiber, AT_LOOP_TIMED_CLOCK) or    #
#     AT_INTERNAL_CLOCK to transmit a SONET frame.                                        #
#     Only restriction is BOTH end points of the fiber cannot have LOOP TIMING. Both can  #
#     be internal... and the BEST timing is when one of the end points is using its       #
#     internal clock and the other using the same clock off the fiber.                    #
#     Therefore for this back-to-back test, ucTxClockSource is setting differently on the #
#     TX and RX port in this script                                                       #
#                                                                                         #
###########################################################################################

puts "Configuring ATM ports ..."

#Declare ATM port structure
struct_new AtPort ATPortConfig

#Define ATM port contents and config TX/RX port, and delete ATM port structure
set AtPort(ucInterfaceSpeed)            $AT_SPEED_OC3
set AtPort(ucFramingMode)               $AT_SONET_FRAMING
set AtPort(ucTxClockSource)             $AT_INTERNAL_CLOCK
set AtPort(ucCellScramblingMode)        $AT_CELL_SCRAMBLING_PAYLOAD
set AtPort(ucHecCosetEnable)            1
set AtPort(ucLoopbackMode)              $AT_LOOPBACK_DISABLED
set AtPort(ucIdleCellHeaderGFC)         0
set AtPort(ucIdleCellHeaderPTI)         $AT_USRDATA_NOT_CONGESTED
set AtPort(ucIdleCellHeaderCLP)         0
set AtPort(ucIdleCellPayloadByte)       0x6A
set AtPort(ucPathSignalLabel)           $AT_PATH_SIGNAL_LABEL_ATM
set AtPort(ucHecErrorHandlingMode)      $AT_HEC_ERROR_HANDLING_CORRECT
set AtPort(ucSONETCountMode)            $AT_ERROR_COUNT_INDIVIDUAL
set AtPort(ulVCInterleaveDepth)         $AT_VC_INTERLEAVE_ALL
set AtPort(ulMaxRxCutThroughBufferSize) $AT_VC_INTERLEAVE_ALL  
set AtPort(ulErrorInjection)            0
set AtPort(ulFlags)                     $AT_PORT_DEFAULT_FLAGS
LIBCMD HTSetStructure $AT_PORT_CONFIG 0 0 0 AtPort 0 $TxHub $TxSlot $TxPort

set AtPort(ucTxClockSource)             $AT_LOOP_TIMED_CLOCK
LIBCMD HTSetStructure $AT_PORT_CONFIG 0 0 0 AtPort 0 $RxHub $RxSlot $RxPort
unset AtPort


###########################################################################################
# Config ATM VCs.                                                        #
###########################################################################################

puts "Configuring ATM VCs ..."

#Declare ATM VC structure
struct_new AtVC ATVC

#Define ATM VC contents and config VCs on TX/RX port, and delete ATM VC structure
#
#For OC3 speed port, the PCR is 353207. Considering multiple VCs are configured on the port,
#we evenly distribute the PCR between the multiple VCs.
#So that we have "set AtVC(ulPCR) [expr 353207/$VCCount]" below
#It is not necessary to always set the PCR of the VC as [expr 353207/$VCCount] as long as
#the summation of the PCRs of all the VC is equal or smaller than 353207 on the OC3 port.  
set AtVC(ucTxEnable)        1
set AtVC(ucRxEnable)        1
set AtVC(ucConnType)        $STR_CONN_TYPE_PVC
set AtVC(uiVPI)             0
set AtVC(uiVCI)             32
set AtVC(ucGFC)             0
set AtVC(ucPTI)             $AT_USRDATA_NOT_CONGESTED
set AtVC(ucAALType)         $AT_AAL5
set AtVC(ucEncapType)       $AT_ENCAP_TYPE_LLC_IPV4
set AtVC(ucCaptureEnable)   1
set AtVC(ucRateClass)       $AT_RATE_CLASS_UBR
set AtVC(ulPCR)             [expr 353207/$VCCount]
set AtVC(ulRxCutThroughBufferSize)	$AT_VC_RX_CT_BUFFER_SIZE	
set AtVC(ulTxMode)          $SINGLE_BURST_MODE
set AtVC(ulBurstCount)      $BurstCountPerVC
set AtVC(ulMburstCount)     0
set AtVC(ulBurstGap)        0
set AtVC(ucCLIPInARPEnable) 0
set AtVC(ucCLIPUnSolicitedInARPReplyEnable)   0
LIBCMD HTSetStructure $AT_VC_CREATE 0 $VCCount 0 AtVC 0 $TxHub $TxSlot $TxPort
LIBCMD HTSetStructure $AT_VC_CREATE 0 $VCCount 0 AtVC 0 $RxHub $RxSlot $RxPort
unset AtVC

###########################################################################################
# Define One IP stream on Tx Card.                                                        #
###########################################################################################

puts "Defining one IP stream ..."

#Declare IP stream structure
struct_new streamIP StreamIP

#Define IP stream contents
set streamIP(ucActive)       1
set streamIP(ucProtocolType) $STREAM_PROTOCOL_IP
set streamIP(uiFrameLength)  $DataLength
set streamIP(TimeToLive)     10
set streamIP(Protocol)       4

set streamIP(DestinationIP) {10 100 10 1}
set streamIP(SourceIP)      {10 100 20 2}

#Set Stream definition to the TX Card, starting at index 1, and delete streamIP structure.
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $TxHub $TxSlot $TxPort
unset streamIP

###########################################################################################
#Define [$StreamCountTotal - 1] more streams on TX card, based on the first stream.                             #
#Also, increment the Destination MAC address in each additional stream by 1.              #
#Therefore,                                                                               #
#The first stream has a Destination IP address of 10 100 10 1 (as defined above);        #
#The second stream has a Destination IP address of 10 100 10 2;                          #
#The third stream has a Destination IP address of 10 100 10 3, etc..                     #
###########################################################################################

puts "Defining [expr $StreamCountTotal - 1] more IP Streams ..."

#Declare IP stream structure
struct_new streamIP StreamIP

#Define IP fields wish to increment, and the value to increment by.
set streamIP(DestinationIP) {0 0 0 1}

#Copy additional more IP streams to the TX Card, based on the first stream, and delete stream structure.
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $StreamCountTotal - 1] 0 streamIP 0 $TxHub $TxSlot $TxPort
unset streamIP

###########################################################################################
# Use stream extension to set frame rate for the first stream on Tx Card.                                                        #
###########################################################################################

puts "Setup stream frame rate with stream extension ..."

#Declare IP stream structure
struct_new ext L3StreamExtension

# Calculate frame rate based on the PCR (353207) of the configured port speed OC3
#
# All the VCs have PCR of [expr 353207 / $VCCount], as configured above. This calculation is
# based on this VC PCR and evenly distributed it to the streams which are bound to the VC -
# and use its equivalent frame rate as the frame rate of the streams
# NOTE:
# It is not necessary to always set the stream frame rate as as this equivalent VC PCR frame rate
# as long as the summation of the frame rate of all the streams bound on the VC is equal or smaller
# than the allocated VC PCR.
#  
set CellsPerFrame [expr floor(($DataLength + 5) / 48) + 1 ]
set PCRPerVC [expr 353207 / $VCCount]
set PCRPerStream [expr $PCRPerVC / $StreamCountPerVC ]
set PFRPerStream [expr round( floor($PCRPerStream / $CellsPerFrame)) ]

#Define stream extension contents
set ext(ulFrameRate)       $PFRPerStream

#Set frame rate for stream of index 1
LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 ext 0 $TxHub $TxSlot $TxPort
unset ext

#################################################################################################
# Setup frame rate for the next [$StreamCountTotal - 1] more streams based on the first stream. #
# Since the ulFrameRate is delta value in the structure below, with zero value below, the same  #
# frame rate of the first stream is set for all the next [$StreamCountTotal - 1] more streams.  #
#                                                                                               #
# NOTE:                                                                                         #
#  The frame rate must be the same for all the streams if they are bound to one single VC       #  
#################################################################################################
#Declare Stream Extension
struct_new ext L3StreamExtension

#Define stream extension contents
set ext(ulFrameRate)       0

#Set frame rate based on the frame rate of stream of index 1
LIBCMD HTSetStructure $L3_DEFINE_MULTI_STREAM_EXTENSION 1 [expr $StreamCountTotal - 1] \
                      0 ext 0 $TxHub $TxSlot $TxPort
unset ext

###########################################################################################
#Stream binding -- binding streams to VCs, and set ATM flags (CLP on or off).             #
#                                                                                         #
#Streams 1  to 3  are bound to VC 0;                                                      #
#Streams 4  to 6  are bound to VC 1;                                                      #
#Streams 7  to 9  are bound to VC 2;                                                      #
#Streams 10 to 12 are bound to VC 3;                                                      #
###########################################################################################

puts "Binding Streams to VCs ..."
struct_new streambind L3StreamBinding*$StreamCountTotal
for {set i 0; set j 0} {$i < $StreamCountTotal } {incr i} {
   if { $i % $StreamCountPerVC == 0 && $i != 0 } {
      incr j
   }
   set streambind($i.ucBindMode)  $STREAM_BIND_VC
   set streambind($i.uiBindIndex) $j;	# This is the VC index, which is to be bound
   set streambind($i.uiATMFlags)  $atmFlag	
}
LIBCMD HTSetStructure $L3_DEFINE_STREAM_BINDING 0 0 0 streambind 0 $TxHub $TxSlot $TxPort
unset streambind

###########################################################################################
# Commit ATM configuration                                                                #
#     Commit is to commit all the stream configurations                                   #
# NOTE:                                                                                   #
#     NS_COMMIT_CONFIG is always required before run the test                             #
###########################################################################################

puts "Committing the configurations ..."
LIBCMD HTSetCommand $NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

###########################################################################################
# Capture setup & start                                                                   #
###########################################################################################

puts "Setting up capture ..."
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)  $CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength)  $CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents)  $CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $NS_CAPTURE_SETUP 0 0 0 cap 0 $RxHub $RxSlot $RxPort
unset cap

puts "Start capture"
LIBCMD HTSetCommand $NS_CAPTURE_START 0 0 0 0 $RxHub $RxSlot $RxPort

###########################################################################################
#Transmit PacketCount packets to the Rx Card, and read counters after transmition.        #
#Note: the current transmit mode is set to single burst of $PacketCount packets. Therefore#
#      we don't need to use "HTRun $HTSTOP $TxHub $TxSlot $TxPort" to stop the traffic.   #
###########################################################################################

puts "Tranmsitting $PacketCount packets ..."
LIBCMD HTRun $HTRUN $TxHub $TxSlot $TxPort

# Wait for one second to allow packets to transmit, and counters to be updated. 
LIBCMD NSDelay 2

###########################################################################################
#Stop capture                                                                             #
###########################################################################################
LIBCMD HTSetCommand $NS_CAPTURE_STOP 0 0 0 0 $RxHub $RxSlot $RxPort
#LIBCMD HTRun $HTSTOP $TxHub $TxSlot $TxPort
#after 2000
puts "Stop capture"

###########################################################################################
#Display Counters (HTGetCounters).                                                                        #
###########################################################################################

#Get Counters from both Tx Card and Rx Card.
puts "Reading counters ..."

struct_new TxCounters HTCountStructure
struct_new RxCounters HTCountStructure

LIBCMD HTGetCounters TxCounters $TxHub $TxSlot $TxPort
LIBCMD HTGetCounters RxCounters $RxHub $RxSlot $RxPort

puts ""
puts "---------------------------------------------------------------"
puts "TX transmitted: $TxCounters(TmtPkt)                                          "
puts "RX    received: $RxCounters(RcvPkt)                                          "
puts "---------------------------------------------------------------"

unset TxCounters
unset RxCounters

###########################################################################################
#Display Counters (AT_PORT_COUNTER_INFO).                                                                        #
###########################################################################################

puts ""
puts "Reading port counters ..."
struct_new pc ATPortCounterInfo
LIBCMD HTGetStructure $AT_PORT_COUNTER_INFO 0 0 0 pc 0 $TxHub $TxSlot $TxPort
puts ""
puts "---------------------------------------------------------------"
puts "TX port: txFrames=$pc(u64TxAAL5Frames.low), rxFrames=$pc(u64RxAAL5Frames.low), \
   txCells=$pc(u64TxAssignedCells.low), rxCells=$pc(u64RxCells.low)" 
LIBCMD HTGetStructure $AT_PORT_COUNTER_INFO 0 0 0 pc 0 $RxHub $RxSlot $RxPort
puts "RX port: txFrames=$pc(u64TxAAL5Frames.low), rxFrames=$pc(u64RxAAL5Frames.low), \
   txCells=$pc(u64TxAssignedCells.low), rxCells=$pc(u64RxCells.low)"
puts "---------------------------------------------------------------"
unset pc

###########################################################################################
#Display Counters (AT_VC_COUNTER_INFO).                                                                        #
###########################################################################################

puts ""
puts "Reading VC counters ..."
struct_new vc ATVCCounterInfo
puts ""
puts "---------------------------------------------------------------"
for {set i 0} {$i < $VCCount} {incr i} { 
LIBCMD HTGetStructure $AT_VC_COUNTER_INFO $i 0 0 vc 0 $TxHub $TxSlot $TxPort
puts "TX VC $i: txCells=$vc(u64TxCells.low), txFrames=$vc(u64TxAAL5Frames.low), \
   rxCells=$vc(u64RxCells), rxFrames=$vc(u64RxAAL5Frames)"
LIBCMD HTGetStructure $AT_VC_COUNTER_INFO $i 0 0 vc 0 $RxHub $RxSlot $RxPort
puts "RX VC $i: txCells=$vc(u64TxCells.low), txFrames=$vc(u64TxAAL5Frames.low), \
   rxCells=$vc(u64RxCells), rxFrames=$vc(u64RxAAL5Frames)"
}
puts "---------------------------------------------------------------"
unset vc

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
    
    #Get captured data, starting at index 0.
    LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO [expr $i-1] 0 0 CapData 0 $RxHub $RxSlot $RxPort

    #Display captured data: the length of a packet = DataLength + 4-byte CRC.
    for {set j 0} {$j < [expr $DataLength ]} {incr j} {
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
	puts "DONE."
    }
    unset CapData
}

# Release the slot
LIBCMD HTSlotRelease $TxHub $TxSlot
LIBCMD HTSlotRelease $RxHub $RxSlot

#Unlink Chassis
puts "UnLinking from the chassis now.."
LIBCMD ETUnLink




