##############################################################################
# nsstreamconfig.tcl                                                         #
#                                                                            #
# - This sample does the following:                                          #
#     - Configures 5 IPv4 and 5 IPv6 streams using the new stream            #
#       configuration commands on the transmitting port.                     #
#     - Sets up the jumbo (sequence + latency tracking) histogram test on    #
#       the receiving port.                                                  #
#     - After transmitting, the histogram results for each stream will be    #
#       retrieved and displayed.                                             #
#                                                                            #
# NOTE: This script is applicable for the following modules:                 #
#       - LAN-3300A/3301A/3302A                                              #
#       - LAN-3310A/3311A                                                    #
#       - LAN-3320A/3321A/3324A/3325A/3327A/3306A                            #
#       - POS-3504A/3505A                                                    #
#       - POS-3510A/3511A                                                    #
#       - POS-3518A/3519A                                                    #
#       - XLW-3720A/3721A                                                    #
#       - AT-3450A/3451A/3452A/3453A                                         #
#                                                                            #
##############################################################################
         
##############################################################################
# Source smartlib.tcl.                                                       #
##############################################################################

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
   } else  {
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

##############################################################################
# Utility procedures                                                         #
##############################################################################

# CheckLink - This proc checks the link LED status for a port.
proc CheckLink {hub slot port} {
    after 2000 
    puts "Checking the link led status for port $hub $slot $port..." 
    set TxLED [LIBCMD HTGetLEDs $hub $slot $port] 
    set Retry 0
    while {!($TxLED & $::HTLED_LINKED) && ($Retry < 10)} {
	after 2000 
	set TxLED [LIBCMD HTGetLEDs $hub $slot $port]
	incr Retry
    } 
    unset TxLED
    if {$Retry < 10} {
	return 0
    }           
}

# ConfigPortSettings - Configure settings on a port.
proc ConfigPortSettings {hub slot port tx_mode burst_size} {
    set model ""
    set card_id [LIBCMD HTGetCardModel model $hub $slot $port]

    # Port setup is different for the ATM, LAN and POS TeraMetrics modules.
    switch -- $card_id \
        $::CM_AT_3450A - \
	$::CM_AT_3451A - \
	$::CM_AT_3452A - \
	$::CM_AT_3453A {
            struct_new atm_cfg ATPortConfig
            set atm_cfg(ucInterfaceSpeed)	$::AT_SPEED_OC3
            set atm_cfg(ucFramingMode) 		$::AT_SONET_FRAMING
            set atm_cfg(ucTxClockSource)	$::AT_INTERNAL_CLOCK
            set atm_cfg(ucCellScramblingMode)	$::AT_CELL_SCRAMBLING_PAYLOAD
            set atm_cfg(ucHecCosetEnable)	1
            set atm_cfg(ucLoopbackMode)		$::AT_LOOPBACK_DISABLED
            set atm_cfg(ucIdleCellHeaderGFC)	0
            set atm_cfg(ucIdleCellHeaderPTI)	$::AT_USRDATA_NOT_CONGESTED
            set atm_cfg(ucIdleCellHeaderCLP)	0
            set atm_cfg(ucIdleCellPayloadByte)	0x6A
            set atm_cfg(ucPathSignalLabel)	$::AT_PATH_SIGNAL_LABEL_ATM
            set atm_cfg(ucHecErrorHandlingMode)	$::AT_HEC_ERROR_HANDLING_CORRECT
            set atm_cfg(ucSONETCountMode)	$::AT_ERROR_COUNT_INDIVIDUAL
            set atm_cfg(ulVCInterleaveDepth)	$::AT_VC_INTERLEAVE_ALL
            set atm_cfg(ulMaxRxCutThroughBufferSize)  12288000  
            set atm_cfg(ulErrorInjection)	0
            set atm_cfg(ulFlags)                $::AT_PORT_ALLOW_ALL_FRAME_SIZES
            LIBCMD HTSetStructure $::AT_PORT_CONFIG 0 0 0 atm_cfg 0\
		    $hub $slot $port
    
            # Create one VC for the port.  All streams will be bound to this
            # VC.
            struct_new atm_vc ATVC
            set atm_vc(ucTxEnable)		 1
            set atm_vc(ucRxEnable)		 1
            set atm_vc(ucConnType)		 $::STR_CONN_TYPE_PVC
            set atm_vc(uiVPI)			 1
            set atm_vc(uiVCI)			 32
            set atm_vc(ucGFC)			 0
            set atm_vc(ucPTI)			 0
            set atm_vc(ucAALType)		 $::AT_AAL5
            set atm_vc(ucEncapType)	         $::AT_ENCAP_TYPE_LLC_ROUTED
            set atm_vc(ucCaptureEnable)	         1
            set atm_vc(ucRateClass)		 $::AT_RATE_CLASS_UBR
            set atm_vc(ulPCR)                    353207
            set atm_vc(ulATCDVT)		 1
            set atm_vc(ulRxCutThroughBufferSize) $::AT_VC_RX_CT_BUFFER_SIZE
            set atm_vc(ulTxMode)		 $tx_mode
            set atm_vc(ulBurstCount)		 $burst_size
            set atm_vc(ulMburstCount)	         0
            set atm_vc(ulBurstGap)	 	 0
            LIBCMD HTSetStructure $::AT_VC_CREATE 0 1 0 atm_vc 0\
		    $hub $slot $port
        } \
	default {
            struct_new port_tx NSPortTransmit
            LIBCMD HTGetStructure $::NS_PORT_TRANSMIT_INFO 0 0 0 port_tx 0\
	        $hub $slot $port
            set port_tx(ucTransmitMode) $tx_mode
            set port_tx(ulBurstCount) $burst_size
            LIBCMD HTSetStructure $::NS_PORT_TRANSMIT 0 0 0 port_tx 0\
	        $hub $slot $port
        }
}

# CreateStreams - Create streams for a stream configuration object.
proc CreateStreams {object_id count} {
    struct_new str_config NSStreamConfig

    set str_config(iStreamConfigID) $object_id
    set str_config(ucOption)        $::NS_APPEND
    set str_config(uiInsertIndex)   0
    set str_config(uiCount)         $count
    LIBCMD NSCreateStream str_config
}

# Createl2Header - Create an layer 2 header (Ethernet, PPP or ATM) for each
# stream.
proc CreateL2Header {hub slot port object_id count} {
    set model ""
    set card_id [LIBCMD HTGetCardModel model $hub $slot $port]
    
    switch -- $card_id \
        $::CM_AT_3450A - \
        $::CM_AT_3451A - \
        $::CM_AT_3452A - \
        $::CM_AT_3453A { CreateATMHeader $object_id $count } \
	$::CM_POS_3504A - \
	$::CM_POS_3505A - \
	$::CM_POS_3510A - \
	$::CM_POS_3511A - \
	$::CM_POS_3518A - \
	$::CM_POS_3519A { CreatePPPHeader $object_id $count } \
	default { CreateEthHeader $object_id $count }
}

# CreateEthHeader - Create an Ethernet header for each stream.
proc CreateEthHeader {object_id count} {
    struct_new create NSCreateHeaderInfo
    struct_new hdr NSEthernetHeader*$count

    puts "Creating an Ethernet header for $count streams..."

    for {set i 0} {$i < $count} {incr i} {
	set hdr($i.ucSourceMAC)        {1 1 1 1 1 1}
	set hdr($i.ucSourceMAC.5)      [expr ($i+1) % 256]
	set hdr($i.ucDestinationMAC)   {2 2 2 2 2 2}
	set hdr($i.ucDestinationMAC.5) [expr ($i+1) % 256]
    }

    set create(iStreamConfigID) $object_id
    set create(uiStreamIndex)   0
    set create(ucOption)        $::NS_APPEND
    set create(uiInsertIndex)   0
    set create(uiCount)         $count
    set create(uiProtocolType)  $::NS_ETHERNET_HEADER
    LIBCMD NSCreateProtocolHeader create hdr 0
}

# CreatePPPHeader - Create a PPP header for each stream.
proc CreatePPPHeader {object_id count} {
    struct_new create NSCreateHeaderInfo
    struct_new hdr NSPPPHeader*$count

    puts "Creating a PPP header for $count streams..."

    set create(iStreamConfigID) $object_id
    set create(uiStreamIndex)   0
    set create(ucOption)        $::NS_APPEND
    set create(uiInsertIndex)   0
    set create(uiCount)         $count
    set create(uiProtocolType)  $::NS_PPP_HEADER
    LIBCMD NSCreateProtocolHeader create hdr 0
}

# CreateATMHeader - Create an ATM header for each stream.
proc CreateATMHeader {object_id count} {
    struct_new create NSCreateHeaderInfo
    struct_new hdr NSATMHeader*$count

    puts "Creating an ATM header for $count streams..."

    for {set i 0} {$i < $count} {incr i} {
	set hdr($i.uiVCIndex)       0
	set hdr($i.uiATMFlags)      $::AT_CLP_ON
    }

    set create(iStreamConfigID) $object_id
    set create(uiStreamIndex)   0
    set create(ucOption)        $::NS_APPEND
    set create(uiInsertIndex)   0
    set create(uiCount)         $count
    set create(uiProtocolType)  $::NS_ATM_HEADER
    LIBCMD NSCreateProtocolHeader create hdr 0
}

# CreateIPv4Header - Create an IPv4 header for each stream.
proc CreateIPv4Header {object_id stream_index count} {
    struct_new create NSCreateHeaderInfo
    struct_new hdr NSIPv4Header*$count

    puts "Creating an IPv4 header for $count streams..."

    for {set i 0} {$i < $count} {incr i} {
	set hdr($i.ucTypeOfService)         0
	set hdr($i.ucTimeToLive)            100
	set hdr($i.uiInitialSequenceNumber) 0
	set hdr($i.ucDestinationIP)         {10 100 10 0}
	set hdr($i.ucDestinationIP.3)       [expr ($i+1) % 256]
	set hdr($i.ucSourceIP)              {10 100 20 0}
	set hdr($i.ucSourceIP.3)            [expr ($i+1) % 256]
    }

    set create(iStreamConfigID) $object_id
    set create(uiStreamIndex)   $stream_index
    set create(ucOption)        $::NS_APPEND
    set create(uiInsertIndex)   0
    set create(uiCount)         $count
    set create(uiProtocolType)  $::NS_IPV4_HEADER
    LIBCMD NSCreateProtocolHeader create hdr 0
}

# CreateIPv6Header - Create an IPv6 header for each stream.
proc CreateIPv6Header {object_id stream_index count} {
    struct_new create NSCreateHeaderInfo
    struct_new hdr NSIPv6Header*$count

    puts "Creating an IPv6 header for $count streams..."

    for {set i 0} {$i < $count} {incr i} {
	set hdr($i.ucTrafficClass)     0
	set hdr($i.ucNextHeader)       0
	set hdr($i.ucHopLimit)         100
	set hdr($i.ulFlowLabel)        0
	set hdr($i.ucSourceIP)         {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 0}
	set hdr($i.ucSourceIP.15)      [expr $i % 256]
	set hdr($i.ucDestinationIP)    {16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 0}
	set hdr($i.ucDestinationIP.15) [expr $i % 256]
	set hdr($i.ucRouterIP)         {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16}
	set hdr($i.ucRouterIP.15)      [expr ($i + 2) % 256]
    }

    set create(iStreamConfigID) $object_id
    set create(uiStreamIndex)   $stream_index
    set create(ucOption)        $::NS_APPEND
    set create(uiInsertIndex)   0
    set create(uiCount)         $count
    set create(uiProtocolType)  $::NS_IPV6_HEADER
    LIBCMD NSCreateProtocolHeader create hdr 0
}

# UpdateTxConfig - Update the transmit settings for each stream.
proc UpdateTxConfig {object_id count length rate} {
    struct_new update NSUpdateTxConfigInfo
    struct_new tx_config NSTxConfig*$count

    set update(iStreamConfigID) $object_id
    set update(uiStreamIndex)   0
    set update(uiCount)         $count
    
    for {set i 0} {$i < $count} {incr i} {
	set tx_config($i.ucEnableStream)         1
	# The SmartBits signature field is required when running histogram
	# tests
	set tx_config($i.ucEnableSignatureField) 1
	set tx_config($i.ulFrameLength)          $length
	set tx_config($i.ulFrameRate)            $rate
    }
    LIBCMD NSUpdateTxConfig update tx_config 0
}

# Wait4RxDone - Wait for all frames have been received on a port.
proc Wait4RxDone {hub slot port} {

   struct_new count HTCountStructure

   after 1000
   LIBCMD HTGetCounters count $hub $slot $port

   while { ( $count(RcvByteRate) > 0 ) } {
       after 1000
       LIBCMD HTGetCounters count $hub $slot $port 
       
       #if RcvPktRate = 0, wait a second and check again just to make sure.
       if {$count(RcvByteRate) == 0 } {
	   after 1000
	   LIBCMD HTGetCounters count $hub $slot $port
	   if {$count(RcvByteRate) == 0} {
	       set RcvdCount $count(RcvByte)
	       return $RcvdCount
	   }
       }
   }
}


##############################################################################
# Main program                                                               #
##############################################################################

# Constants
set TxHub  0
set TxSlot 0
set TxPort 0
set RxHub  0
set RxSlot 1
set RxPort 0

set BURST_PER_STREAM 1000
set STREAM_COUNT 10
set BURST_SIZE [expr $STREAM_COUNT * $BURST_PER_STREAM]
set FRAME_LENGTH 100
# The frame rate will need to be decreased if more streams are defined
set FRAME_RATE   1000

# Structures used
struct_new hist      NSHistLatencyDistPerStream
struct_new hist_info NSHistComboPerStreamInfo*$STREAM_COUNT
struct_new test_info Layer3HistActiveTest

# If chassis is not currently linked prompt for IP and link  
if {[ETGetLinkStatus] < 0} {
   puts "SmartBits not linked - Enter chassis IP address"
   gets stdin ipaddr
   set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]  
   if {$retval < 0 } {
      puts "Unable to connect to $ipaddr. Please try again."
      exit
   } 
   LIBCMD HTSlotReserve $TxHub $TxSlot
   LIBCMD HTSlotReserve $RxHub $RxSlot
}

# Reset the ports to the default state
puts "Resetting Tx and Rx ports..."
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $RESET_FULL $RxHub $RxSlot $RxPort

# Check to see that the link is up
CheckLink $RxHub $RxSlot $RxPort

# Configure the settings for each port.
puts "Configuring the port settings..."
ConfigPortSettings $TxHub $TxSlot $TxPort $SINGLE_BURST_MODE $BURST_SIZE
ConfigPortSettings $RxHub $RxSlot $RxPort $SINGLE_BURST_MODE $BURST_SIZE

# Create a stream configuration object.
puts "Creating a stream configuration object..."
set object_id [LIBCMD NSCreateStreamConfigObject]

# Create streams for the object.
puts "Creating $STREAM_COUNT streams for the object..."
CreateStreams $object_id $STREAM_COUNT

# Create a layer 2 header (Ethernet, PPP or ATM) for each stream.
CreateL2Header $TxHub $TxSlot $TxPort $object_id $STREAM_COUNT

# Create an IPv4 header for the first 50% of the streams.
CreateIPv4Header $object_id 0 [expr $STREAM_COUNT / 2]

# Create an IPv6 header for the last 50% of the streams.
CreateIPv6Header $object_id [expr $STREAM_COUNT / 2] [expr $STREAM_COUNT / 2]

# Update the transmit setttings for each stream.
UpdateTxConfig $object_id $STREAM_COUNT $FRAME_LENGTH $FRAME_RATE

# Commit the stream configuration to the tx port.
puts "Committing the stream configuration to port $TxHub $TxSlot $TxPort..."
struct_new commit_info NSCommitStreamConfig
set commit_info(iStreamConfigID) $object_id
set commit_info(iHub)            $TxHub
set commit_info(iSlot)           $TxSlot
set commit_info(iPort)           $TxPort
LIBCMD NSCommitStreamConfigObject commit_info

# Set up the jumbo(latency and sequence tracking) histogram test on the rx
# port.
puts "Setting up the jumbo histogram test on port $RxHub $RxSlot $RxPort..."
for {set i 0} {$i < 16} {incr i} {
    set hist(ulInterval.$i) [expr $i + 1]
}    
LIBCMD HTSetCommand $NS_HIST_COMBO_PER_STREAM 0 0 0 hist\
	$RxHub $RxSlot $RxPort

# Clear the histogram records and start the histogram test on the rx port.
LIBCMD HTSetCommand $NS_HIST_START 0 0 0 "" $RxHub $RxSlot $RxPort

# The ATM TeraMetrics modules (AT-345x) requires the user to commit the
# configuration on the port before transmitting
set model ""
set card_id [LIBCMD HTGetCardModel model $TxHub $TxSlot $TxPort]
switch -- $card_id \
    $::CM_AT_3450A - \
    $::CM_AT_3451A - \
    $::CM_AT_3452A - \
    $::CM_AT_3453A {
        LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort
    }

# Create a port group.
puts "Creating a port group..."
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $TxHub $TxSlot $TxPort
LIBCMD HGAddtoGroup $RxHub $RxSlot $RxPort

# Issue a group start.
puts "Transmitting..."
LIBCMD HGStart

# Wait for transmission to complete.
Wait4RxDone $RxHub $RxSlot $RxPort

# Retrieve the number of histogram records generated on the rx port.
LIBCMD HTGetStructure $L3_HIST_ACTIVE_TEST_INFO 0 0 0 test_info 0\
	$RxHub $RxSlot $RxPort
puts "Number of histogram records generated on port $RxHub $RxSlot $RxPort is $test_info(ulRecords)"

# Retrieve and display the histogram record for each stream.
LIBCMD HTGetStructure $NS_HIST_COMBO_PER_STREAM_INFO 0 0 0 hist_info 0\
	$RxHub $RxSlot $RxPort      
puts ""
for {set i 0} {$i < $test_info(ulRecords)} {incr i} {
    puts "Displaying histogram results for stream [expr $i + 1]...\n"
    puts "stream id = $hist_info($i.ulStreamID)"
    puts "minimum latency (0.1 us) = $hist_info($i.ulMinLatency)"
    puts "maximum latency (0.1 us) = $hist_info($i.ulMaxLatency)"
    puts "total frames received = $hist_info($i.u64TotalFrames.low)"
    puts "in sequence frames received = $hist_info($i.u64InSequence.low)"
    puts "out of sequence frames received = $hist_info($i.u64OutOfSequence.low)"
    for {set j 0} {$j < 16} {incr j} {
	set low [expr $j * 0.1]
	set high [expr ($j+1) * 0.1]
	if {$j == 15} {
	    puts "frames rcvd in time interval > $low us = $hist_info($i.u64Frames.$j.low)"
	} else {
	    puts "frames rcvd in time interval $low - $high us  = $hist_info($i.u64Frames.$j.low)"
	}
    }
    puts ""

    puts "Continue displaying results(y/n)?"
    set choice ""
    gets stdin choice
    switch -- $choice {
	"n" -
	"N" -
	"no" -
	"NO" { break }
	default { continue }
    }
}

# Delete all streams in the stream configuration object.  This is optional
# since the following call to NSDeleteStreamConfigObject() will also delete
# the streams.
LIBCMD NSDeleteAllStreams $object_id

# Delete the stream configuration object.
puts "Deleting the stream configuration object..."
LIBCMD NSDeleteStreamConfigObject $object_id

# Release the cards.
puts "Releasing the cards..."
LIBCMD HTSlotRelease $TxHub $TxSlot
LIBCMD HTSlotRelease $RxHub $RxSlot

# Unlink from the chassis.
puts "Unlinking from the chassis..."
LIBCMD NSUnLink

puts "Done."
