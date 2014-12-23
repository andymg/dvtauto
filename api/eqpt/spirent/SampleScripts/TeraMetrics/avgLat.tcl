##############################################################################
# avgLat.tcl                                                                 #
#                                                                            #
# - This sample sets up 10 IP streams and uses histogram to obtain latency   #
#   statistics for each stream.                                              #
#                                                                            #
# NOTE: This script works on the following cards:                            #
#       - LAN-3300A/3301A/3302A                                              #
#       - LAN-3310A/3311A                                                    #
#       - POS-3504A/3505A                                                    #
#       - POS-3510A/3511A                                                    #
#       - XLW-3720A/3721A                                                    #
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
# Set test constants                                                         #
##############################################################################

set TxHub 0
set TxSlot 0
set TxPort 0
set RxHub 0
set RxSlot 1
set RxPort 0

set BURST_PER_STREAM 10
set STREAM_COUNT 10
set BURST_SIZE [expr $STREAM_COUNT * $BURST_PER_STREAM]
set LENGTH 128
set option_list [list $NS_TRACK_MIN_LAT $NS_TRACK_TOTAL_LAT]


##############################################################################
# Structures used.                                                           #
##############################################################################

struct_new hist      NSHistLatencyDistPerStream
struct_new hist_info NSHistComboPerStreamInfo*$STREAM_COUNT
struct_new test_info Layer3HistActiveTest
struct_new opt       NSHistLatencyOption
struct_new s         StreamIP*$STREAM_COUNT


##############################################################################
# Make connection to chassis                                                 #
##############################################################################

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


##############################################################################
# Reset cards.                                                               #
##############################################################################

puts "Resetting Tx and Rx cards ..."
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $RESET_FULL $RxHub $RxSlot $RxPort


##############################################################################
# Loop through available latency histogram options                           #
##############################################################################

foreach option $option_list {

   puts "\n***********************************************************"
	if {$option == $NS_TRACK_TOTAL_LAT} {
      set option_string "NS_TRACK_TOTAL_LAT"
   } else {
      set option_string "NS_TRACK_MIN_LAT"
   }
   puts "*              histogram option: $option_string"
   puts "*  number of IP streams created: $STREAM_COUNT"
   puts "*                  frame length: $LENGTH"
   puts "*         burst size per stream: $BURST_PER_STREAM"
   puts "***********************************************************"


   ###########################################################################
   # Define IP streams on Tx Card.                                           #
   ###########################################################################

   # Fill in default values
	LIBCMD HTDefaultStructure $L3_DEFINE_IP_STREAM s 0 $TxHub $TxSlot $TxPort

	# Create stream(s)
	for {set i 0} {$i < $STREAM_COUNT} {incr i}  {
      set s($i.ucActive)       1
      set s($i.ucProtocolType) $STREAM_PROTOCOL_IP
      set s($i.uiFrameLength)  $LENGTH
      set s($i.ucTagField)     1
	}
	LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 s 0 $TxHub $TxSlot $TxPort


   ###########################################################################
   # Prepare transmission.                                                   #
   ###########################################################################

   # Set transmit parameters
	LIBCMD HTTransmitMode $SINGLE_BURST_MODE $TxHub $TxSlot $TxPort
	LIBCMD HTBurstCount $BURST_SIZE $TxHub $TxSlot $TxPort

   # Setup the combination histograms
	for {set i 0} {$i < 16} {incr i} {
      set hist(ulInterval.$i) [expr $i + 1]
   }    
   LIBCMD HTSetCommand $NS_HIST_COMBO_PER_STREAM 0 0 0 hist $RxHub $RxSlot $RxPort

	# Clear histogram records and start histograms
	LIBCMD HTSetCommand $NS_HIST_START 0 0 0 "" $RxHub $RxSlot $RxPort

	# Set histogram option
   set opt(uiOption) $option
   LIBCMD HTSetCommand $NS_HIST_LATENCY_OPTION 0 0 0 opt $RxHub $RxSlot $RxPort


   ###########################################################################
   # Transmit packets.                                                       #
   ###########################################################################

   # Create a group
   LIBCMD HGSetGroup ""
   LIBCMD HGAddtoGroup $TxHub $TxSlot $TxPort
   LIBCMD HGAddtoGroup $RxHub $RxSlot $RxPort

   # Issue a group start
   LIBCMD HGRun $HTRUN

   # Wait for transmission
   after 5000

   # Check that the histogram setup on the port and the number of
   # records generated is correct
   LIBCMD HTGetStructure $L3_HIST_ACTIVE_TEST_INFO 0 0 0 test_info 0 $RxHub $RxSlot $RxPort


   ###########################################################################
   # Display histograms.                                                     #
   ###########################################################################

	# Check the combination histogram results 
   LIBCMD HTGetStructure $NS_HIST_COMBO_PER_STREAM_INFO 0 0 0 hist_info 0 $RxHub $RxSlot $RxPort
      
   for {set i 0} {$i < $STREAM_COUNT} {incr i} {
      puts "\nHistogram results for stream [expr $i + 1]:"
      if {$option == $NS_TRACK_TOTAL_LAT} {
         puts "\tTOTAL LATENCY = $hist_info($i.u64Total.low)"
         puts "\tAVERAGE LATENCY = [expr $hist_info($i.u64Total.low) / $hist_info($i.u64TotalFrames.low)]"
      } else {
         puts "\tMINIMUM LATENCY = $hist_info($i.ulMinLatency)"
      }
	}
};# End foreach option...


##############################################################################
# Unlink from chassis.                                                       #
##############################################################################
NSUnLink   
