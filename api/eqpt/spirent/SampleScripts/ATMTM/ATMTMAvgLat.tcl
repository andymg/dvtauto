################################################################################
# ATMTMAvgLat.tcl                                                              #
#                                                                              #
# - This sample applies to ATM 3451/3453 cards. It uses the first slot in a    #
#   chassis, connected back to back.                                           #
# - This sample creates 4 VCs, 12 IP streams with OC3 speed port. Each VC      #
#   is bound with 3 IP streams, and sends out a single burst of 300 IP frames. #
#   It then uses histogram to obtain latency statistics for each stream.       #
#                                                                              #
# NOTE: This script works on the following cards:                              #
#       - ATM-3451/3453  with SmartLib 3.50, TM 3.60.42/TM 4.00                #
#                                                                              #
################################################################################

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

set TxHub  0
set TxSlot 0
set TxPort 0
set RxHub  0
set RxSlot 0
set RxPort 1

set STREAM_PER_VC 3
set VC_COUNT      4
set STREAM_COUNT  [expr $VC_COUNT * $STREAM_PER_VC ]

set BURST_PER_STREAM 1000
set BURST_PER_VC     [expr $BURST_PER_STREAM * $STREAM_PER_VC]
set PACKET_COUNT     [expr $VC_COUNT * $BURST_PER_VC]

set ATM_FLAG    $AT_CLP_OFF

set LENGTH 128
set option_list [list $NS_TRACK_MIN_LAT $NS_TRACK_TOTAL_LAT]



##############################################################################
# Structures used.                                                           #
##############################################################################
struct_new AtPort ATPortConfig
struct_new AtVC   ATVC
struct_new hist      NSHistLatencyDistPerStream
struct_new hist_info NSHistComboPerStreamInfo*$STREAM_COUNT
struct_new test_info Layer3HistActiveTest
struct_new opt       NSHistLatencyOption
struct_new s         StreamIP*$STREAM_COUNT
struct_new ext       L3StreamExtension*$STREAM_COUNT
struct_new binding   L3StreamBinding*$STREAM_COUNT


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
   
   # Since TX/RX slots are the same, only call HTSlotReserve for one of them
   LIBCMD HTSlotReserve $TxHub $TxSlot
}


##############################################################################
# Reset cards.                                                               #
##############################################################################

puts "Resetting Tx and Rx cards ..."
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $RESET_FULL $RxHub $RxSlot $RxPort
after 2000

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
   puts "*             burst size per VC: $BURST_PER_VC"
   puts "*         number of VCs created: $VC_COUNT"
   puts "*   number of IP streams per VC: $STREAM_PER_VC"
   puts "*  number of IP streams created: $STREAM_COUNT"
   puts "*                  frame length: $LENGTH"
   puts "***********************************************************"

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

   # Fill in default values
   LIBCMD HTDefaultStructure $AT_PORT_CONFIG AtPort 0 $TxHub $TxSlot $TxPort
   
   # Configure the TX/RX ports
   set AtPort(ucTxClockSource)             $AT_INTERNAL_CLOCK
   LIBCMD HTSetStructure $AT_PORT_CONFIG 0 0 0 AtPort 0 $TxHub $TxSlot $TxPort
   set AtPort(ucTxClockSource)             $AT_LOOP_TIMED_CLOCK
   LIBCMD HTSetStructure $AT_PORT_CONFIG 0 0 0 AtPort 0 $RxHub $RxSlot $RxPort	

   ###########################################################################################
   # Config ATM VCs.                                                        #
   ###########################################################################################

   puts "Configuring ATM VCs ..."

   # Fill in default values
   LIBCMD HTDefaultStructure $AT_VC_CREATE AtVC 0 $TxHub $TxSlot $TxPort

   set AtVC(ucEncapType)       $AT_ENCAP_TYPE_LLC_IPV4
   set AtVC(ulPCR)             [expr 353207/$VC_COUNT]
   set AtVC(ulTxMode)          $SINGLE_BURST_MODE
   set AtVC(ulBurstCount)      $BURST_PER_VC
   LIBCMD HTSetStructure $AT_VC_CREATE 1 $VC_COUNT 0 AtVC 0 $TxHub $TxSlot $TxPort
   LIBCMD HTSetStructure $AT_VC_CREATE 1 $VC_COUNT 0 AtVC 0 $RxHub $RxSlot $RxPort

   ###########################################################################
   # Define IP streams on Tx Card.                                           #
   ###########################################################################
   
   puts "Defining streams ..."
   
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
   # Define stream frame rate on Tx Card.                                           #
   ###########################################################################
   
   puts "Specifying frame rate via stream extension ..."

   # Fill in default values
   LIBCMD HTDefaultStructure $L3_DEFINE_STREAM_EXTENSION ext 0 $TxHub $TxSlot $TxPort
   
   # Specify frame rate of stream(s)
   for {set i 0} {$i < $STREAM_COUNT} {incr i}  {
      set ext($i.ulFrameRate)       1
   }
   LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 ext 0 $TxHub $TxSlot $TxPort

   ###########################################################################
   # Bind streams to VCs on Tx Card.                                         #
   ###########################################################################
   
   puts "Binding streams to VCs ..."
   
   # Bind stream(s) to VC
   for {set i 0; set j 1} {$i < $STREAM_COUNT} {incr i}  {
      if { $i % $STREAM_PER_VC == 0 && $i != 0 } {
         incr j
      }
      set binding($i.ucBindMode)       $STREAM_BIND_VC
      set binding($i.uiBindIndex)      $j                ;#This is the VC index to be bound
      set binding($i.uiATMFlags)       $ATM_FLAG
   }
   LIBCMD HTSetStructure $L3_DEFINE_STREAM_BINDING 0 0 0 binding 0 $TxHub $TxSlot $TxPort

   ###########################################################################
   # Commit streams to VCs on Tx Card.                                           #
   ###########################################################################
   
   puts "Committing streams..."
   LIBCMD HTSetCommand $NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

   ###########################################################################
   # Prepare transmission.                                                   #
   ###########################################################################

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

   # Wait for transmission (2 seconds delay)
   after 2000
   
   ###########################################################################
   # Check the histogram setup and number of records generated is correct.   #
   ###########################################################################

   # Check that the histogram setup on the port and the number of
   # records generated is correct
   LIBCMD HTGetStructure $L3_HIST_ACTIVE_TEST_INFO 0 0 0 test_info 0 $RxHub $RxSlot $RxPort
   
   if {$test_info(ulTest) != $NS_HIST_TEST_COMBO_PER_STREAM} {
      puts "Expected: 16(NS_HIST_TEST_COMBO_PER_STREAM)  Actual: $test_info(ulTest) \
            The histogram test reported is incorrect"\
   }

   if {$test_info(ulRecords) != $STREAM_COUNT} {
      puts "Expected: $STREAM_COUNT  Actual: $test_info(ulRecords) \
            The number of histogram records generated is incorrect" 
	}

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

   ###########################################################################
   # Delete all the VCs on the TX/RX port.                                                     #
   ###########################################################################
	
	LIBCMD HTSetCommand $AT_VC_DELETE_ALL 0 0 0 0 $TxHub $TxSlot $TxPort
	LIBCMD HTSetCommand $AT_VC_DELETE_ALL 0 0 0 0 $RxHub $RxSlot $RxPort

};# End foreach option...


##############################################################################
# Unlink from chassis.                                                       #
##############################################################################
puts "UnLinking from the chassis now.."
NSUnLink

puts ""
puts "DONE."
