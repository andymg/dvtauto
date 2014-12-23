###########################################################################################
# oam.tcl                                                                        	  #
#                                                                                         #
# This script sets up with OAM header packet normal type (OAM_PACKET_TYPE_NORMAL_OAM)	  #	
# and crc disable.                                                                        #
#                                                                                         #
# - Basic start, transmit, capture, display capture frames, without checking oam header   #
#											  #
# NOTE: This script currently only applies to the LAN-3710 cards                          #
#                                                                                         #
###########################################################################################


#############################################################################
# This proc checks the link LED .                               	    #
# CheckLink waits for 2 seconds or more, until the link is established.     #
# For other cards, CheckLink does not add any delay.                        #
#############################################################################
proc CheckLink {Hub Slot Port} {
    set Model ""
    set card_id [LIBCMD HTGetCardModel Model $Hub $Slot $Port]

    switch $card_id \
        $::CM_LAN_6301A { after 2000 } \
	$::CM_GX_1420B {
	    puts "Checking link status ..."
	    struct_new x Long
	    struct_new ExCardInfo ETHExtendedCardInfo

	    #a 2-second wait is necessary for GX-1420B
		after 2000

	    LIBCMD HTGetEnhancedStatus x $Hub $Slot $Port
	    while {![expr $x(l)&$::GIG_STATUS_LINK]} {
		LIBCMD HTGetStructure $::ETH_EXTENDED_CARD_INFO 0 0 0 ExCardInfo 0 $Hub $Slot $Port
		after 100
		LIBCMD HTGetEnhancedStatus x $Hub $Slot $Port
	    }
	    unset x
	    unset ExCardInfo
	} \
	default {
	    # Skip
	}
}


##############################################################################
# If smartlib.tcl is not loaded, attempt to locate it at the default location.
# The actual location is different on different platforms. 
##############################################################################
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

##############################################################################
# If chassis is not currently linked prompt for IP and link  
##############################################################################
if {[ETGetLinkStatus] < 0} {
     puts "SmartBits not linked - Enter chassis IP address"
     gets stdin ipaddr
     set retval [NSSocketLink $ipaddr 16385 0]  
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit
     }
}

##############################################################################
# Set the default variables
##############################################################################
set iHub 	0
set iSlot 	1
set iPort 	0

set iHub2 	0
set iSlot2 	1
set iPort2 	0

set UNIQUE_OAM_PATTERNS 	128
set OAM_PATTERN_SIZE    	6
set BURST_SIZE          	$UNIQUE_OAM_PATTERNS

# reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2
puts "\nReserve iHub $iHub, iSlot $iSlot"
puts "\nReserve iHub2 $iHub2, iSlot2 $iSlot2\n"

# Reset cards
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2
puts "\nReset iHub $iHub, iSlot $iSlot $iPort"
puts "\nReset iHub2 $iHub2, iSlot2 $iSlot2 $iPort2\n"

# Check the link
CheckLink $iHub $iSlot $iPort
CheckLink $iHub2 $iSlot2 $iPort2
              
# Create structures              
struct_new oam_config     NSOAMConfig
struct_new oam_pattern    UChar*[expr $UNIQUE_OAM_PATTERNS * $OAM_PATTERN_SIZE]
struct_new oam_tx_counter NSOAMCounterInfo
struct_new oam_rx_counter NSOAMCounterInfo
struct_new ip             StreamIP
struct_new ext            L3StreamExtension
struct_new tx             NSPortTransmit
struct_new cap_setup 	  NSCaptureSetup
struct_new cap_count      NSCaptureCountInfo
struct_new cap_data       NSCaptureDataInfo


# transmit mode
puts "Transmit single burst mode\n"

# Setup tx params using NS_PORT_TRANSMIT.
set tx(ucTransmitMode)  $SINGLE_BURST_MODE
set tx(ucScheduleMode)  $SCHEDULE_MODE_GAP
set tx(ulInterFrameGap) 96
set tx(uiGapScale)      0
set tx(ulBurstCount)    $BURST_SIZE

LIBCMD HTSetStructure $NS_PORT_TRANSMIT 0 0 0 tx 0 $iHub $iSlot\
		       $iPort
puts "Set up the port transmit\n" 
	       
# Configure OAM parameters using NS_OAM_CONFIG.
set oam_config(ulTotalPatterns)   	$BURST_SIZE
set oam_config(ucCRC8ErrorEnable) 	0
set oam_config(ucOAMEnable)       	1
LIBCMD HTSetStructure $NS_OAM_CONFIG 0 0 0 oam_config 0 $iHub\
       $iSlot $iPort
LIBCMD HTSetStructure $NS_OAM_CONFIG 0 0 0 oam_config 0 $iHub2\
       $iSlot2 $iPort2
puts "Configure OAM on transmit and receive side\n" 

# Configure the OAM pattern using NS_OAM_PATTERN.
for {set i 0} {$i < [expr $UNIQUE_OAM_PATTERNS * $OAM_PATTERN_SIZE]}\
    {incr i} {
    set oam_pattern($i) [expr ($i + 1) % 256]
}
LIBCMD HTSetStructure $NS_OAM_PATTERN 0 0 0 oam_pattern 0 $iHub\
       $iSlot $iPort
puts "Set up the OAM pattern [expr $UNIQUE_OAM_PATTERNS * $OAM_PATTERN_SIZE]\n"

# Create an ip stream using L3_DEFINE_IP_STREAM.
set ip(ucActive)       1
set ip(ucProtocolType) $STREAM_PROTOCOL_IP
set ip(uiFrameLength)  60
set ip(SourceMAC)      {0xAA 0xAA 0xAA 0xAA 0xAA 0xAA}
set ip(DestinationMAC) {0xBB 0xBB 0xBB 0xBB 0xBB 0xBB}
set ip(SourceIP)       {0xCC 0xCC 0xCC 0xCC}
set ip(DestinationIP)  {0xDD 0xDD 0xDD 0xDD}
set ip(Protocol)       4
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 ip 0 $iHub $iSlot\
	$iPort
puts "Create an ip stream with length 60 bytes\n"

# Specify the OAM header type for this stream using
# L3_DEFINE_STREAM_EXTENSION.
set ext(ucOAMHeaderPacketType) $OAM_PACKET_TYPE_NORMAL_OAM
LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 ext 0 $iHub\
	$iSlot $iPort
puts "Specify the OAM header type for this ip stream\n"	

# Setup filtering capturing  on OAM frames only using
# NS_CAPTURE_SETUP.
set cap_setup(ulCaptureMode)   	$CAPTURE_MODE_FILTER_ON_EVENTS
set cap_setup(ulCaptureLength) 	$CAPTURE_LENGTH_ENTIRE_FRAME
set cap_setup(ulCaptureEvents) 	$CAPTURE_EVENTS_OAM_FRAME_ONLY
LIBCMD HTSetStructure $NS_CAPTURE_SETUP 0 0 0 cap_setup 0 $iHub2\
	$iSlot2 $iPort2

#@@ Start capture using NS_CAPTURE_START.
LIBCMD HTSetCommand $NS_CAPTURE_START 0 0 0 "" $iHub2 $iSlot2 $iPort2
puts "Start capture\n"	
	
# Clear counters
LIBCMD HTClearPort $iHub $iSlot $iPort
LIBCMD HTClearPort $iHub2 $iSlot2 $iPort2
puts "Clear counter on Tx and Rx\n"

# Transmit
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

puts "Transmiting...\n"

# wait 4 seconds
after 4000

# Stop capture
LIBCMD HTSetCommand $NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2
puts "Stop catpure\n"
	
#@@ Retrieve and check the OAM counters
LIBCMD HTGetStructure $NS_OAM_COUNTER_INFO 0 0 0 oam_tx_counter 0\
       $iHub $iSlot $iPort
       
puts "Get Tx counters..."
puts "Transmit $oam_tx_counter(u64TxOAMFrames.low) normal type OAM packets \n"  

LIBCMD HTGetStructure $NS_OAM_COUNTER_INFO 0 0 0 oam_rx_counter 0\
       $iHub2 $iSlot2 $iPort2
       
puts "Get Rx counters..."
puts "Receive  $oam_rx_counter(u64RxOAMFrames.low) normal type OAM packets\n"  

# Get capture count 
LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 cap_count 0 $iHub2\
	$iSlot2 $iPort2
puts "Capture count $cap_count(ulCount)\n"	

set pattern_index 0
# Display capture packets
puts "Display captured packets"
for {set index 0 } {$index < $cap_count(ulCount)} {incr index} {
    puts "Packet $index\n"
    set cap_data(ulFrameIndex) $index	
    LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 cap_data 0 $iHub2 $iSlot2 $iPort2
    
    # Display the packet
    for {set i 0} {$i < $cap_data(ulRetrievedLength)} {incr i} {
        if {!($i % 16) && ($i != 0)} {
	    puts ""
	}
        
        set byte $cap_data(ucData.$i._ubyte_)
	puts -nonewline " [format %02X  $byte] "
    }
    set pattern_index [expr $pattern_index + 6]
    puts "\n"
}

# Unset the structure

unset oam_config
unset oam_pattern
unset oam_tx_counter
unset oam_rx_counter
unset ip
unset ext
unset tx
unset cap_data
unset cap_setup
unset cap_count

puts ""
#UnLinking from the chassis
puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"


