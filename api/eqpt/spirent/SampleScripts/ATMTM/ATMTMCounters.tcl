####################################################################################
#                                                                                  # 
# ATMTMCounters.tcl                                                    #
#                                                                                  #
# - This sample applies to ATM 3451/3453 cards. It uses the first slot in a        #
#   chassis, connected back to back.                                               #
# - This sample creates 3 VCs, 6 IP streams. Each VC is bound with 2 IP streams.   #
# - For different speeds (OC3/OC12), seven different tests run sequentially to     #
#   display the various counters in AT_PORT_COUNTER_INFO, AT_VC_COUNTER_INFO and   #
#   AT_STREAM_TX_COUNTER_INFO.                                                     #
#                                                                                  #
# NOTE: This script works with SmartLib 3.50, TM 3.60/TM 4.00                      #
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
set TxHub  0
set TxSlot 0
set TxPort 0
set RxHub  0
set RxSlot 1
set RxPort 0

puts "Reserving Tx and Rx cards ..."
LIBCMD HTSlotReserve $TxHub $TxSlot 
LIBCMD HTSlotReserve $RxHub $RxSlot 

puts "Resetting Tx and Rx cards ..."
LIBCMD HTResetPort $::RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $::RESET_FULL $RxHub $RxSlot $RxPort

#declare constants
set VCCount        3
set StrmCountPerVC 2   ;# the number of streams bound on each VC
set StrmCount      [expr $VCCount * $StrmCountPerVC] ;#Total number of streams on the card
set FrameLength    576
set num_of_cells_per_frame [expr $FrameLength /48 + 1] ;#(576/48+1)=13,
                                                         ;# 48 is the size of the cell in bytes
                                                         ;# 48*13 = 576
                                                         ;# + 1 is because the AAL5 trailing bytes
# Get card module
set model ""
set cardtype [LIBCMD HTGetCardModel model $TxHub $TxSlot $TxPort]
puts ""
puts " model $model"
puts ""

switch -- $cardtype \
  $::CM_AT_3451A { set speed_list [list $::AT_SPEED_OC3] } \
  $::CM_AT_3453A { set speed_list [list $::AT_SPEED_OC3 $::AT_SPEED_OC12] } \
  default { puts "Error: WRONG CARD - This sample script is designed only for AT_3451 or AT_3453"}

#Test loop  
foreach speed $speed_list {

  struct_new atmPortCfg_Dft ATPortConfig
  struct_new atmVCCfg_Dft ATVC
  struct_new ip_stream StreamIP*$StrmCount
  struct_new stream_ext L3StreamExtension*$StrmCount
  struct_new streambind L3StreamBinding*$StrmCount
  struct_new portCounter1 ATPortCounterInfo
  struct_new portCounter2 ATPortCounterInfo
  struct_new VCCounter1 ATVCCounterInfo
  struct_new VCCounter2 ATVCCounterInfo
  struct_new StrmCounter ATStreamCounterInfo
  struct_new VCCfg_Modify ATVC
  struct_new stream_ext_CRC L3StreamExtension  

  #set up ATM Port Configurations with default setting
  LIBCMD HTDefaultStructure $::AT_PORT_CONFIG  atmPortCfg_Dft 0 $TxHub $TxSlot $TxPort
  
  # Set up transmit port
  set atmPortCfg_Dft(ucInterfaceSpeed) $speed
  set atmPortCfg_Dft(ulFlags)          $::AT_PORT_ALLOW_ALL_FRAME_SIZES 
  set atmPortCfg_Dft(ucTxClockSource)  $::AT_INTERNAL_CLOCK 
  LIBCMD HTSetStructure $::AT_PORT_CONFIG 0 0 0 atmPortCfg_Dft 0 $TxHub $TxSlot $TxPort
  
  #Set up receive port
  set atmPortCfg_Dft(ucTxClockSource) $::AT_LOOP_TIMED_CLOCK 
  LIBCMD HTSetStructure $::AT_PORT_CONFIG 0 0 0 atmPortCfg_Dft 0 $RxHub $RxSlot $RxPort

                                               
  if {$speed == $::AT_SPEED_OC3} {
     set speedString "AT_SPEED_OC3" 
     set Maximum_PCR  353207
     set LineCellRate 353207
  } else {
     set speedString "AT_SPEED_OC12"
     set Maximum_PCR  1412830
     set LineCellRate 1412830

  }
  set LineFrameRate [expr $LineCellRate / $num_of_cells_per_frame]
  set FrameRate     [expr $LineCellRate / $num_of_cells_per_frame /$StrmCount]
  set BurstCount    20
  #################################################################################################
  #
  #    Test Case 1
  #    Checking the transmit/receive frame/cell counters
  #################################################################################################
  
  puts "---------------------------------------"
  puts " "
  puts "Test Case 1 (Speed: $speedString)"
  puts "Number of TX/RX Frames/Cells for ATPortCounters, ATVCCounters, and ATStreamCounters"
  puts "  "

  # Set up VCs
  # First fill up the ATVC struct with default setting from smartlib.dft
  # Set TX mode to single burst mode to check the frame/cell count with the burst count
  LIBCMD HTDefaultStructure $::AT_VC_CREATE  atmVCCfg_Dft 0 $TxHub $TxSlot $TxPort
  set atmVCCfg_Dft(ulTxMode)     $::SINGLE_BURST_MODE
  set atmVCCfg_Dft(ulBurstCount) $BurstCount
  set atmVCCfg_Dft(ulPCR)     $Maximum_PCR
  LIBCMD HTSetStructure $::AT_VC_CREATE 0 $VCCount 0 atmVCCfg_Dft 0 $TxHub $TxSlot $TxPort
  LIBCMD HTSetStructure $::AT_VC_CREATE 0 $VCCount 0 atmVCCfg_Dft 0 $RxHub $RxSlot $RxPort
  
  # Config the streams
  for {set i 0} {$i < $StrmCount} {incr i} { 
     LIBCMD HTDefaultStructure $::L3_DEFINE_IP_STREAM ip_stream($i) 0 $TxHub $TxSlot $TxPort          
     set ip_stream($i.uiFrameLength)        $FrameLength          
     set ip_stream($i.Protocol)             4	    
     set ip_stream($i.TypeOfService)        28 ; #low delay,high thruput and reliability     
  }
  LIBCMD HTSetStructure $::L3_DEFINE_IP_STREAM 0 0 0 ip_stream 0 $TxHub $TxSlot $TxPort

  #Set frame rate from stream extension 
  for {set i 0} {$i < $StrmCount} {incr i} { 
     LIBCMD HTDefaultStructure $::L3_DEFINE_STREAM_EXTENSION stream_ext($i) 0 $TxHub $TxSlot $TxPort          
     set stream_ext($i.ulFrameRate)        $FrameRate

  }
  LIBCMD HTSetStructure $::L3_DEFINE_STREAM_EXTENSION 0 0 0 stream_ext 0 $TxHub $TxSlot $TxPort
  
  #bind streams to VC's
  for {set i 0; set j 0} {$i < $StrmCount } {incr i} {
     if { $i % $StrmCountPerVC == 0 && $i != 0 } {
       incr j
     }     
     set streambind($i.ucBindMode)  $::STREAM_BIND_VC
     set streambind($i.uiBindIndex) $j;	# This is the VC index, which is to be bound in this loop
     set streambind($i.uiATMFlags)  $::AT_CLP_OFF
  }   
  LIBCMD HTSetStructure $::L3_DEFINE_STREAM_BINDING 0 0 0 streambind 0 $TxHub $TxSlot $TxPort

  #commit the configuration
  LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort
  
  #Run the test
  HTRun $::HTRUN $TxHub $TxSlot $TxPort
  after 2000
  HTRun $::HTSTOP $TxHub $TxSlot $TxPort

  #Check the port counters
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter1 0 $TxHub $TxSlot $TxPort
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter2 0 $RxHub $RxSlot $RxPort
  
  puts "  "  
  puts "Port counters"
  puts "                   Frames        Cells        Bytes"
  puts [format "Transmitted: %12d %12d %12d" $portCounter1(u64TxAAL5Frames.low)  $portCounter1(u64TxAssignedCells.low) $portCounter1(u64TxAAL5FrameBytes.low)]
  puts [format "   Received: %12d %12d %12d" $portCounter2(u64RxAAL5Frames.low)  $portCounter2(u64RxCells.low) $portCounter2(u64RxAAL5FrameBytes.low)]

  #Check the VC counters
  puts ""
  puts "VC counters:"
  puts "                   Frames        Cells      VCIndex"
  for {set i 0} {$i < $VCCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_VC_COUNTER_INFO $i 0 0 VCCounter1 0 $TxHub $TxSlot $TxPort
    LIBCMD HTGetStructure $::AT_VC_COUNTER_INFO $i 0 0 VCCounter2 0 $RxHub $RxSlot $RxPort   
  
  puts [format "Transmitted: %12d %12d %12d" $VCCounter1(u64TxAAL5Frames.low) $VCCounter1(u64TxCells.low) $i]
  puts [format "   Received: %12d %12d %12d" $VCCounter2(u64RxAAL5Frames.low) $VCCounter2(u64RxCells.low) $i]
  puts " "
  }
  
  #Check the stream counters
  puts ""
  puts "Stream counters:"
  puts "                   Frames      StreamIndex"
  for {set i 1} {$i <= $StrmCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_STREAM_TX_COUNTER_INFO $i 0 0 StrmCounter 0 $TxHub $TxSlot $TxPort
    puts [format "Transmitted: %12d %12d" $StrmCounter(u64TxFrameCount.low) $i]
    puts " "
  }
  
  #################################################################################################
  #    Test Case 2
  #    Checking the transmit/receive rate
  #################################################################################################
  puts "---------------------------------------"
  puts " "
  puts "Test Case 2 (Speed: $speedString)"
  puts "TX/RX Cell Rate for ATPortCounters"
  puts " "

  # Change the TX mode to continuous mode in order to get the non-zero rate during transmitting
  for {set i 0} {$i < $VCCount} {incr i} {
  
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
    set VCCfg_Modify(ulTxMode) $::CONTINUOUS_PACKET_MODE
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort 
     
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
    set VCCfg_Modify(ulTxMode) $::CONTINUOUS_PACKET_MODE
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
  }
  
  LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

  # Clear the counters on both the ports
  LIBCMD HTClearPort $TxHub $TxSlot $TxPort
  LIBCMD HTClearPort $RxHub $RxSlot $RxPort

  HTRun $::HTRUN $TxHub $TxSlot $TxPort
  after 2000
  
  #Get the rate during transmit. Otherwise the rate will be zero (if not retrieve during transmitting)
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter1 0 $TxHub $TxSlot $TxPort
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter2 0 $RxHub $RxSlot $RxPort

  HTRun $::HTSTOP $TxHub $TxSlot $TxPort

  puts "  "
  puts "Port counters"
  puts "                 CellRate"
  puts [format "Transmitted: %12d " $portCounter1(ulTxCellRate)]
  puts [format "   Received: %12d " $portCounter2(ulRxCellRate)]
  puts " "

  #################################################################################################
  #    Test Case 3
  #    Checking RX TaggedCell Number by set the CLP bit
  #################################################################################################
  puts "---------------------------------------"
  puts " "
  puts "Test Case 3 (Speed: $speedString)"
  puts "RX TaggedCell Number for ATPortCounters"
  puts " "

  #Set VC to single burst mode so that we can compare the cell number with burst value
  for {set i 0} {$i < $VCCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
    set VCCfg_Modify(ulTxMode) $::SINGLE_BURST_MODE
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
    
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
    set VCCfg_Modify(ulTxMode) $::SINGLE_BURST_MODE
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
  }
  
  #bind streams to VC's
  for {set i 0; set j 0} {$i < $StrmCount } {incr i} {
     if { $i % $StrmCountPerVC == 0 && $i != 0 } {
        incr j
     }     
     set streambind($i.ucBindMode)  $::STREAM_BIND_VC
     set streambind($i.uiBindIndex) $j  ;# This is the to-be-bound VC index
     set streambind($i.uiATMFlags)  $::AT_CLP_ON
  }
  LIBCMD HTSetStructure $::L3_DEFINE_STREAM_BINDING 0 0 0 streambind 0 $TxHub $TxSlot $TxPort
  
  #commit the config    
  LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

  # Clear the counters on both the ports
  LIBCMD HTClearPort $TxHub $TxSlot $TxPort
  LIBCMD HTClearPort $RxHub $RxSlot $RxPort

  #Run the test
  HTRun $::HTRUN $TxHub $TxSlot $TxPort
  after 2000 
  HTRun $::HTSTOP $TxHub $TxSlot $TxPort

  #Get counters and check the tagged cell counter
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter1 0 $TxHub $TxSlot $TxPort
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter2 0 $RxHub $RxSlot $RxPort
  puts " "
  puts "Port counters"
  puts "                             Cells"
  puts [format "         Transmitted: %12d " $portCounter1(u64TxAssignedCells.low)]
  puts [format "            Received: %12d " $portCounter2(u64RxCells.low)]
  puts [format "TaggedCells Received: %12d " $portCounter2(u64RxCells.low)]
  puts " "

  #################################################################################################
  # Test Case 4
  # Checking the RX TaggedCell Rate by set the TX mode to CONTINUOUS mode
  # and with CLP bit on (already set in Test Case 3 above)
  #################################################################################################
  puts "---------------------------------------"
  puts " "
  puts "Test Case 4 (Speed: $speedString)"
  puts "TaggedCell Rate for ATPortCounters"
  puts " "
 
  #Set VC to continuous mode since non-rate can only be retrieved during transmit  
  for {set i 0} {$i < $VCCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
    set VCCfg_Modify(ulTxMode) $::CONTINUOUS_PACKET_MODE
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
  
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
    set VCCfg_Modify(ulTxMode) $::CONTINUOUS_PACKET_MODE
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
  }

  LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

  # Clear the counters on both TX/RX ports
  LIBCMD HTClearPort $TxHub $TxSlot $TxPort
  LIBCMD HTClearPort $RxHub $RxSlot $RxPort

  #run the test
  HTRun $::HTRUN $TxHub $TxSlot $TxPort
  after 2000   

  #retrieve counters
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter1 0 $TxHub $TxSlot $TxPort
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter2 0 $RxHub $RxSlot $RxPort

  #stop the test
  HTRun $::HTSTOP $TxHub $TxSlot $TxPort
  
  puts " "
  puts "Port counters"
  puts "                             CellRate"
  puts [format "            Transmitted: %12d " $portCounter1(ulTxCellRate)]
  puts [format "               Received: %12d " $portCounter2(ulRxCellRate)]
  puts [format "Received TaggedCellRate: %12d " $portCounter2(ulRxTaggedCellRate)]
  puts " "
  
  #bind streams to VC's
  for {set i 0; set j 0} {$i < $StrmCount } {incr i} {
     if { $i % $StrmCountPerVC == 0 && $i != 0 } {
        incr j
     }
     set streambind($i.ucBindMode)  $::STREAM_BIND_VC
     set streambind($i.uiBindIndex) $j   ;# This is the to-be-bound VC index
     set streambind($i.uiATMFlags)  $::AT_CLP_OFF
  }
  LIBCMD HTSetStructure $::L3_DEFINE_STREAM_BINDING 0 0 0 streambind 0 $TxHub $TxSlot $TxPort
    
  #################################################################################################
  #                                                                                               
  # Test Case 5
  # Checking the u64RxCongestedCells by set the ucPTI to AT_USRDATA_CONGESTED
  #                                             TX mode to SINGLEBURST mode 
  #
  #################################################################################################
  puts "---------------------------------------"
  puts " "
  puts "Test Case 5 (Speed: $speedString)"
  puts "CongestedCell Number for ATPortCounters"
  puts " "
 
  #Set VC to Continuous Mode
  for {set i 0} {$i < $VCCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
    set VCCfg_Modify(ulTxMode) $::SINGLE_BURST_MODE
    set VCCfg_Modify(ucPTI) $::AT_USRDATA_CONGESTED
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort

    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
    set VCCfg_Modify(ulTxMode) $::SINGLE_BURST_MODE
    set VCCfg_Modify(ucPTI) $::AT_USRDATA_CONGESTED
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
  }

  #commit the config
  LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

  #clear the counters on both TX/RX ports
  LIBCMD HTClearPort $TxHub $TxSlot $TxPort
  LIBCMD HTClearPort $RxHub $RxSlot $RxPort

  #run the test
  HTRun $::HTRUN $TxHub $TxSlot $TxPort
  after 200   
  HTRun $::HTSTOP $TxHub $TxSlot $TxPort

  #retrieve counters and check the congested cell count
  after 2000
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter1 0 $TxHub $TxSlot $TxPort
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter2 0 $RxHub $RxSlot $RxPort

  puts "  "
  puts "Port counters"
  puts "                                Cells"
  puts [format "            Transmitted: %12d " $portCounter1(u64TxAssignedCells.low)]
  puts [format "               Received: %12d " $portCounter2(u64RxCells.low)]
  puts [format "Received CongestedCells: %12d " $portCounter2(u64RxCongestedCells.low)]
  puts " "

  #################################################################################################
  #
  # Test Case 6
  # Checking the ulRxCongestedCellRate by set the ucPTI to AT_USRDATA_CONGESTED_SDU_0
  #                                             TX mode to CONTINUOUS mode 
  #
  #################################################################################################
  puts "---------------------------------------"
  puts " "
  puts "Test Case 6 (Speed: $speedString)"
  puts "CongestedCell Rate for ATPortCounters"
  puts " "
 
  #Set VC to continuous mode and set the PTI to congested SDU 0
  for {set i 0} {$i < $VCCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
    set VCCfg_Modify(ulTxMode) $::CONTINUOUS_PACKET_MODE
    set VCCfg_Modify(ucPTI) $::AT_USRDATA_CONGESTED
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
 
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
    set VCCfg_Modify(ulTxMode) $::CONTINUOUS_PACKET_MODE
    set VCCfg_Modify(ucPTI) $::AT_USRDATA_CONGESTED
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
  }

  #commit the config
  LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

  # clear the counters on both TX/RX ports
  LIBCMD HTClearPort $TxHub $TxSlot $TxPort
  LIBCMD HTClearPort $RxHub $RxSlot $RxPort
 
  #run the test
  HTRun $::HTRUN $TxHub $TxSlot $TxPort
  after 2000   ;# 20 is not enough to retrieve the counters

  #retrieve counter during transmit
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter1 0 $TxHub $TxSlot $TxPort
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter2 0 $RxHub $RxSlot $RxPort

  #stop test
  HTRun $::HTSTOP $TxHub $TxSlot $TxPort
  
  puts " "
  puts "Port counters"
  puts "                                  CellRate"
  puts [format "                 Transmitted: %12d " $portCounter1(ulTxCellRate)]
  puts [format "                    Received: %12d " $portCounter2(ulRxCellRate)]
  puts [format "Received Congested Cell Rate: %12d " $portCounter2(ulRxCongestedCellRate)]
  puts " "

  #################################################################################################
  #
  # Test Case 7
  # Checking the u64RxCRCErredAAL5Frames by enable CRC in L3 stream extension
  #                                         TX mode to CONTINUOUS mode 
  #
  #################################################################################################
  puts "---------------------------------------"
  puts " "
  puts "Test Case 7 (Speed: $speedString)"
  puts "u64RxCRCErredAAL5Frames Number for ATPortCounters, ATVCCounters and ATStreamCounters"
  puts " "
 
  #Set VC to Continuous Mode
  for {set i 0} {$i < $VCCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
    set VCCfg_Modify(ulTxMode) $::SINGLE_BURST_MODE
    set VCCfg_Modify(ucPTI) $::AT_USRDATA_NOT_CONGESTED
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $TxHub $TxSlot $TxPort
  
    LIBCMD HTGetStructure $::AT_VC_INFO $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
    set VCCfg_Modify(ulTxMode) $::SINGLE_BURST_MODE
    set VCCfg_Modify(ucPTI) $::AT_USRDATA_NOT_CONGESTED
    LIBCMD HTSetStructure $::AT_VC_MODIFY $i 0 0 VCCfg_Modify 0 $RxHub $RxSlot $RxPort
  }

  #Enable CRC in stream extension
  set stream_ext_CRC(ucCRCErrorEnable)   1
  set stream_ext_CRC(ulFrameRate)   $FrameRate  
  for {set i 1} {$i <= $StrmCount} {incr i} { 
    LIBCMD HTSetStructure $::L3_MOD_STREAM_EXTENSION $i 0 0 stream_ext_CRC 0 $TxHub $TxSlot $TxPort     
  }

  #commit config
  LIBCMD HTSetCommand $::NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort

  # clear the counters on both TX/RX ports
  LIBCMD HTClearPort $TxHub $TxSlot $TxPort
  LIBCMD HTClearPort $RxHub $RxSlot $RxPort

  #run the test
  HTRun $::HTRUN $TxHub $TxSlot $TxPort
  after 2000   
  HTRun $::HTSTOP $TxHub $TxSlot $TxPort
  
  #retrieve counter  
  after 2000
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter1 0 $TxHub $TxSlot $TxPort
  LIBCMD HTGetStructure $::AT_PORT_COUNTER_INFO 0 0 0 portCounter2 0 $RxHub $RxSlot $RxPort
  
  puts " "
  puts "Port counters"
  puts "                                 Frames"
  puts [format "              Transmitted: %12d " $portCounter1(u64TxAAL5Frames.low)]
  puts [format "Received CRC error frames: %12d " $portCounter2(u64RxCRCErredAAL5Frames.low)]

  puts " "
  puts "VC counters"
  puts "                                 Frames      VCIndex"

  for {set i 0} {$i < $VCCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_VC_COUNTER_INFO $i 0 0 VCCounter1 0 $TxHub $TxSlot $TxPort
    LIBCMD HTGetStructure $::AT_VC_COUNTER_INFO $i 0 0 VCCounter2 0 $RxHub $RxSlot $RxPort
    puts [format "              Transmitted: %12d %12d" $VCCounter1(u64TxAAL5Frames.low) $i]
    puts [format "Received CRC error frames: %12d %12d" $VCCounter2(u64RxCRCErredAAL5Frames.low) $i]
    puts " "

  }
  #Check the stream counters
  puts ""
  puts "Stream counters:"
  puts "                   Frames      StreamIndex"
  for {set i 1} {$i <= $StrmCount} {incr i} { 
    LIBCMD HTGetStructure $::AT_STREAM_TX_COUNTER_INFO $i 0 0 StrmCounter 0 $TxHub $TxSlot $TxPort
    puts [format "Transmitted: %12d %12d" $StrmCounter(u64TxFrameCount.low) $i]
    puts " "
  }
  puts " "
  
  unset atmPortCfg_Dft
  unset atmVCCfg_Dft
  unset ip_stream
  unset stream_ext
  unset streambind
  unset VCCounter1
  unset VCCounter2
  unset portCounter1
  unset portCounter2
  unset StrmCounter
  unset VCCfg_Modify
  unset stream_ext_CRC
   
  LIBCMD HTSetCommand $::AT_VC_DELETE_ALL 0 0 0 0 $TxHub $TxSlot $TxPort
  LIBCMD HTSetCommand $::AT_VC_DELETE_ALL 0 0 0 0 $RxHub $RxSlot $RxPort

}

# Release the slot
LIBCMD HTSlotRelease $TxHub $TxSlot
LIBCMD HTSlotRelease $RxHub $RxSlot

#Unlink Chassis
puts "UnLinking from the chassis now.."
LIBCMD ETUnLink


