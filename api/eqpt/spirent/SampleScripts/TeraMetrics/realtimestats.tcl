##############################################################################
# nsstreamconfig.tcl                                                         #
#                                                                            #
# - This sample does the following:                                          #
#     - Configures 1 IPv4 streams using the new stream                       #
#       configuration commands on the transmitting port.                     #
#     - Sets up the real-time statistics tracking mode on the rx port.       #
#     - Sets up the jumbo (sequence + latency tracking) histogram test on    #
#       the rx port.                                                         #
#     - During transmission, the histogram results for the stream will be    #
#       retrieved multiple times and displayed at the end.                   #
#                                                                            #
# NOTE: This script is applicable for the following modules:                 #
#       - LAN-3300A/3301A/3302A                                              #
#       - LAN-3310A/3311A                                                    #
#       - LAN-3320A/3321A/3324A/3325A/3327A/3306A                            #
#       - XLW-3720A/3721A                                                    #
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
proc ConfigPortSettings {hub slot port} {
    set model ""
    set card_id [LIBCMD HTGetCardModel model $hub $slot $port]

    struct_new port_tx NSPortTransmit
    LIBCMD HTGetStructure $::NS_PORT_TRANSMIT_INFO 0 0 0 port_tx 0\
	    $hub $slot $port
    set port_tx(ucTransmitMode) $::CONTINUOUS_PACKET_MODE
    set port_tx(ucScheduleMode) $::SCHEDULE_MODE_FRAME_RATE
    LIBCMD HTSetStructure $::NS_PORT_TRANSMIT 0 0 0 port_tx 0\
	    $hub $slot $port
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

set STREAM_COUNT  1
set FRAME_LENGTH  100
# The frame rate may need to be decreased if more streams are defined
set FRAME_RATE    1000
set TEST_DURATION 5

# Structures used
struct_new hist      NSHistLatencyDistPerStream
struct_new hist_info NSHistComboPerStreamInfo*$STREAM_COUNT
struct_new test_info Layer3HistActiveTest
struct_new option    NSHistLatencyOption
struct_new id_info   NSStreamIDTableInfo

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
puts "Resetting the Tx and Rx ports..."
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $RESET_FULL $RxHub $RxSlot $RxPort

# Check to see that the link is up
CheckLink $RxHub $RxSlot $RxPort

# Configure the settings for each port.
puts "Configuring the port settings..."
ConfigPortSettings $TxHub $TxSlot $TxPort
ConfigPortSettings $RxHub $RxSlot $RxPort

# Create a stream configuration object.
puts "Creating a stream configuration object..."
set object_id [LIBCMD NSCreateStreamConfigObject]

# Create streams for the object.
puts "Creating $STREAM_COUNT streams for the object..."
CreateStreams $object_id $STREAM_COUNT

# Create a layer 2 header (Ethernet, PPP or ATM) for each stream.
CreateEthHeader $object_id $STREAM_COUNT

# Create an IPv4 header for each stream.
CreateIPv4Header $object_id 0 $STREAM_COUNT

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

# Set up the real-time statistics tracking mode on the rx port.  This is to
# allow for histogram results to be retrieved (using NS_HIST_COMBO_PER_STREAM_INFO) without stopping the test on port.
set option(uiOption) $NS_TRACK_STREAM_ID
LIBCMD HTSetStructure $NS_HIST_LATENCY_OPTION 0 0 0 option 0\
	$RxHub $RxSlot $RxPort

# Clear the histogram records and start the histogram test on the rx port.
LIBCMD HTSetCommand $NS_HIST_START 0 0 0 "" $RxHub $RxSlot $RxPort

# Create a port group.
puts "Creating a port group..."
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $TxHub $TxSlot $TxPort
LIBCMD HGAddtoGroup $RxHub $RxSlot $RxPort

# Issue a group start.
puts "Transmitting..."
LIBCMD HGStart

# Wait 2 seconds before retrieving results.
after 2000

# Retrieve the number of histogram records generated on the rx port.
LIBCMD HTGetStructure $L3_HIST_ACTIVE_TEST_INFO 0 0 0 test_info 0\
	$RxHub $RxSlot $RxPort
puts "Number of histogram records currently on port $RxHub $RxSlot $RxPort is $test_info(ulRecords)"

set id_info(ulRequestIndex) 0
set id_info(ulRequestCount) $test_info(ulRecords)
LIBCMD HTGetStructure $NS_STREAM_ID_TABLE_INFO 0 0 0 id_info 0\
	$RxHub $RxSlot $RxPort
    puts "Stream IDs being tracked on port $RxHub $RxSlot $RxPort ..."
for {set i 0} {$i < $id_info(ulRetrievedCount)} {incr i} { 
    puts -nonewline " [expr $id_info(ulStreamID.$i) & 0xFFFF]"
}
puts "\n"

# Retrieve the histogram results approximately once every second for a total
# duration of 5 seconds.  Note that in real-time statistics tracking mode, 
# the port will not keep track of the minimum latency (ulMinLatency), 
# maximum latency (ulMaxLatency), in sequence (u64InSequence) and out of 
# sequence (u64OutOfSequence) results.
for {set i 0} {$i < $TEST_DURATION} {incr i} {
    after 1000
    LIBCMD HTGetStructure $NS_HIST_COMBO_PER_STREAM_INFO 0 0 0 hist_info 0\
	    $RxHub $RxSlot $RxPort      

    for {set j 0} {$j < $test_info(ulRecords)} {incr j} {
	set total_lat($i) $hist_info($j.u64Total.low)
	set total_rx($i) $hist_info($j.u64TotalFrames.low)

	for {set k 0} {$k < 16} {incr k} {
	    set interval($i.$k) $hist_info($j.u64Frames.$k.low)
	}
    }
}

# Display the histogram results for the stream
puts "Displaying test results for the stream...\n"
puts -nonewline [format %25s "Sampling interval"]
for {set i 0} {$i < $TEST_DURATION} {incr i} {
    puts -nonewline "     [expr $i + 1] sec"
}
puts "\n"
puts -nonewline [format %25s "total latency (0.1 us)"]
for {set i 0} {$i < $TEST_DURATION} {incr i} { 
    puts -nonewline "     [format %5d $total_lat($i)]"
}
puts ""
puts -nonewline [format %25s "total rx frames"]
for {set i 0} {$i < $TEST_DURATION} {incr i} { 
    puts -nonewline "     [format %5d $total_rx($i)]"
}
puts ""
for {set i 0} {$i < 16} {incr i} {
    set low [expr $i * 0.1]
    set high [expr ($i+1) * 0.1]
    if {$i == 15} {
	puts -nonewline [format %25s "rx frames (> $low us)"]
    } else {
	puts -nonewline [format %25s "rx frames ($low - $high us)"]
    }
    for {set j 0} {$j < $TEST_DURATION} {incr j} { 
	puts -nonewline "     [format %5d $interval($j.$i)]"
    }
    puts ""
}
puts ""

# Issue a group stop.
puts "Stopping transmission..."
LIBCMD HGStop

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











