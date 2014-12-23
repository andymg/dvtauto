################################################################################
# ATMTM_ns_his_combo_per_stream.tcl                                             #
#                                                                              #
# - This sample applies to ATM 3451/3453 cards. It uses the first slot in a    #
#   chassis, connected back to back.                                           #
# - This sample creates 1 VC, 10 IP streams with OC3 speed port. The VC is     #
#   bound with the 10 IP streams, and sends out a single burst of 10000 IP     #
#   frames. It then uses histogram to displays latency and sequence            #
#   information                                                                #
#                                                                              #
# NOTE: This script works on the following cards:                              #
#       - ATM-3451/3453   with SmartLib 3.50, TM 3.60.42/TM 4.00               #
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
     set retval [NSSocketLink $ipaddr 16385 $::RESERVE_NONE]  
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit
     }
}

##############################################################################
# Set test constants                                                         #
##############################################################################

set TxHub 0
set TxSlot 0
set TxPort 0

set RxHub 0
set RxSlot 0
set RxPort 1

set num2Add 9

# Set ranges for latency distribution
set R0 1
set R1 2
set R2 3
set R3 4
set R4 5
set R5 6
set R6 8
set R7 10
set R8 50
set R9 100
set R10 500
set R11 1000
set R12 5000
set R13 10000
set R14 50000
set R15 100000

set BurstPerStream  1000
set BurstSize [expr ( 1 + $num2Add ) * $BurstPerStream ]
set DATA_LENGTH 88

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
LIBCMD HTResetPort $::RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $::RESET_FULL $RxHub $RxSlot $RxPort
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

#Configure ATM TX/RX port
LIBCMD HTSetStructure $AT_PORT_CONFIG 0 0 0 - 0 $TxHub $TxSlot $TxPort\
-ucTxClockSource       $AT_INTERNAL_CLOCK

LIBCMD HTSetStructure $AT_PORT_CONFIG 0 0 0 - 0 $RxHub $RxSlot $RxPort\
-ucTxClockSource       $AT_LOOP_TIMED_CLOCK

###########################################################################################
# Config ATM VC.                                                                          #
#    Only one single VC of index 1 is created                                             #
###########################################################################################

puts "Configuring ATM VCs ..."

#Configure VC on ATM TX/RX port
LIBCMD HTSetStructure $AT_VC_CREATE 1 0 0 - 0 $TxHub $TxSlot $TxPort\
-ulTxMode       $SINGLE_BURST_MODE \
-ulBurstCount   $BurstSize \
-ucEncapType    $AT_ENCAP_TYPE_LLC_IPV4

LIBCMD HTSetStructure $AT_VC_CREATE 1 0 0 - 0 $RxHub $RxSlot $RxPort\
-ulTxMode       $SINGLE_BURST_MODE \
-ulBurstCount   $BurstSize \
-ucEncapType    $AT_ENCAP_TYPE_LLC_IPV4

###########################################################################################
# Config streams.                                                        #
###########################################################################################

#set up streams
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $TxHub $TxSlot $TxPort\
-ucActive       1 \
-ucProtocolType $STREAM_PROTOCOL_IP \
-uiFrameLength  $DATA_LENGTH \
-ucRandomLength 0 \
-ucTagField     1 \
-TimeToLive     10 \
-DestinationIP  {192 158 100 1} \
-SourceIP       {192 148 100 1} \
-Netmask        {255 255 255 0} \
-Gateway        {192 148 100 1} \
-Protocol       4

struct_new ip StreamIP
set ip(DestinationIP)  {0 0 0 1}
set ip(SourceIP)       {0 0 0 1}
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 $num2Add 0 ip 0 $TxHub $TxSlot $TxPort \
unset ip

# Calculate frame rate based on the PCR (353207) of the configured port speed OC3
#
# There is only one VC configured, and the VC has PCR 353207, as configured above. This 
# calculation is based on this VC PCR and evenly distributed it to the streams which are
#  bound to the VC - and use its equivalent frame rate as the frame rate of the streams
# NOTE:
# It is not necessary to always set the stream frame rate as as this equivalent VC PCR 
# frame rate as long as the summation of the frame rate of all the streams bound on the 
# VC is equal to or smaller than the allocated VC PCR.
#  
set CellsPerFrame [expr floor(($DATA_LENGTH + 5) / 48) + 1 ]
set PCRPerVC      353207   ;#only one VC configured
set PCRPerStream [expr $PCRPerVC / ($num2Add + 1) ]
set PFRPerStream [expr round( floor($PCRPerStream / $CellsPerFrame)) ]

#set up frame rate of streams

LIBCMD HTSetStructure $L3_DEFINE_STREAM_EXTENSION 0 0 0 - 0 $TxHub $TxSlot $TxPort\
-ulFrameRate       $PFRPerStream

struct_new ext L3StreamExtension
set ext(ulFrameRate)       0
LIBCMD HTSetStructure $L3_DEFINE_MULTI_STREAM_EXTENSION 1 $num2Add 0 ext 0 $TxHub $TxSlot $TxPort
unset ext

###########################################################################
# All streams are bound to VC of index 1on Tx Card.                       #
###########################################################################
puts "Binding streams to VCs ..."

struct_new binding L3StreamBinding
set binding(ucBindMode)       $STREAM_BIND_VC
set binding(uiBindIndex)      1                ;#This is the VC index to be bound
set binding(uiATMFlags)       $AT_CLP_OFF
LIBCMD HTSetStructure $L3_DEFINE_STREAM_BINDING 0 0 0 binding 0 $TxHub $TxSlot $TxPort

set binding(uiBindIndex)      0                ;#This is the delta VC index
LIBCMD HTSetStructure $L3_DEFINE_MULTI_STREAM_BINDING 1 $num2Add 0 binding 0 $TxHub $TxSlot $TxPort

#Unset the structure
unset binding

###########################################################################
# Commit streams to VCs on Tx Card.                                       #
###########################################################################

puts "Committing streams..."

LIBCMD HTSetCommand $NS_COMMIT_CONFIG 0 0 0 0 $TxHub $TxSlot $TxPort
after 2000

#############################################
# Check for L3 streams.  Test will not      #
# work if there are no streams transmitting #
# The DEFINED_STREAM_COUNT will return the  #
# total stream count (including the first,  #
# hidden stream, so we have to adjust the   #
# count to show the count of transmitting   #
# streams.                                  #
#############################################

struct_new DefStreams  ULong

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 DefStreams 0 $TxHub $TxSlot $TxPort

set TOTAL_STREAMS [expr $DefStreams(ul) - 1]
if {  $TOTAL_STREAMS < 2 } {
     puts "No L3 streams on card - Aborting Test!"
     puts "Press ENTER key to exit"

     gets stdin response

     exit
} else {
         puts "Testing with $TOTAL_STREAMS streams"
}

#Unset the structure
unset DefStreams

############################################################################
# Set distribution intervals.                                              #
# - They are set to variables here so the same variables can be referenced #
#   when setting up the display.                                           #
############################################################################

LIBCMD HTSetCommand $NS_HIST_COMBO_PER_STREAM 0 0 0 - $RxHub $RxSlot $RxPort\
-ulInterval.0.ul $R0 \
-ulInterval.1.ul $R1 \
-ulInterval.2.ul $R2 \
-ulInterval.3.ul $R3 \
-ulInterval.4.ul $R4 \
-ulInterval.5.ul $R5 \
-ulInterval.6.ul $R6 \
-ulInterval.7.ul $R7 \
-ulInterval.8.ul $R8 \
-ulInterval.9.ul $R9 \
-ulInterval.10.ul $R10 \
-ulInterval.11.ul $R11 \
-ulInterval.12.ul $R12 \
-ulInterval.13.ul $R13 \
-ulInterval.14.ul $R14 \
-ulInterval.15.ul $R15 

LIBCMD HTSetCommand $NS_HIST_START 0 0 0 NULL $RxHub $RxSlot $RxPort

# Create the group and set to transmit a single burst of 10000 packets
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $TxHub $TxSlot $TxPort
LIBCMD HGAddtoGroup $RxHub $RxSlot $RxPort

###########################################################################
# Transmit packets.                                                       #
###########################################################################
#LIBCMD HTRun $HTRUN $TxHub $TxSlot $TxPort
LIBCMD HGRun $::HTRUN
after 2000

###########################################################################
# Check the histogram setup and number of records generated is correct.   #
###########################################################################
struct_new test_info Layer3HistActiveTest

# Check that the histogram setup on the port and the number of
# records generated is correct
LIBCMD HTGetStructure $NS_HIST_ACTIVE_TEST_INFO 0 0 0 test_info 0 $RxHub $RxSlot $RxPort
   
if {$test_info(ulTest) != $NS_HIST_TEST_COMBO_PER_STREAM} {
   puts "Expected: 16(NS_HIST_COMBO_PER_STREAM)  Actual: $test_info(ulTest) \
       The histogram test reported is incorrect"\
}

if {$test_info(ulRecords) != $TOTAL_STREAMS} {
   puts "Expected: $TOTAL_STREAMS  Actual: $test_info(ulRecords) \
       The number of histogram records generated is incorrect" 
}
	
unset test_info

###########################################################################
# Display histograms.                                                     #
###########################################################################

struct_new HistComboPerStrmInfo NSHistComboPerStreamInfo*$TOTAL_STREAMS
LIBCMD HTGetStructure $NS_HIST_COMBO_PER_STREAM_INFO 0 0 0 HistComboPerStrmInfo 0 $RxHub $RxSlot $RxPort

for {set i 0} {$i < $TOTAL_STREAMS} {incr i} {
      # pull out data from ulStreamID
      #set BOX [expr ($HistComboPerStrmInfo($i.ulStreamID) & 0x0F000000) / 0x010000000]   
      set SLOT [expr ($HistComboPerStrmInfo($i.ulStreamID) & 0x00FF0000) / 0x00010000]
      set STREAM [expr $HistComboPerStrmInfo($i.ulStreamID) & 0x0000FFFF]

      puts "==================================================================="
      puts "SEQUENCE TRACKING - Card [expr $RxSlot +1]"
      #puts "   $HistComboPerStrmInfo($i.u64TotalFrames.low) Frames received from CARD [expr $SLOT + 1], BOX [expr $BOX + 1], STREAM $STREAM"
      puts "   $HistComboPerStrmInfo($i.u64TotalFrames.low) Frames received from CARD [expr $SLOT + 1], STREAM $STREAM"
      puts "		Frames in Sequence => $HistComboPerStrmInfo($i.u64InSequence.low)"
      puts "		Duplicate Frames   => $HistComboPerStrmInfo($i.u64OutOfSequence)"
      #puts "		Lost Frames	   => $HistComboPerStrmInfo($i.ulLost)"
      puts "==================================================================="
      puts "PER STREAM LATENCY"
      puts "	Min Frame Latency for Stream $STREAM => [expr $HistComboPerStrmInfo($i.ulMinLatency) * 0.1] uS"
      puts "	Max Frame Latency for Stream $STREAM => [expr $HistComboPerStrmInfo($i.ulMaxLatency) * 0.1] uS"
      puts "==================================================================="
      puts "LATENCY DISTRIBUTION in 0.1uS"
      puts "========================================================================="
      puts -nonewline "|[format "%7d" $R0] |[format "%7d" $R1] |[format "%7d" $R2] |[format "%7d" $R3] |"
      puts "[format "%7d" $R4] |[format "%7d" $R5] |[format "%7d" $R6] |[format "%7d" $R7] |"
      puts "-------------------------------------------------------------------------"
      puts -nonewline "|"

      for {set j 0} {$j < 8} {incr j}  {
            puts -nonewline "[format "%7d" $HistComboPerStrmInfo($i.u64Frames.$j.low)] |"
      }

      puts ""
      puts "-------------------------------------------------------------------------\n"
      puts "========================================================================="
      puts -nonewline "|[format "%7d" $R8] |[format "%7d" $R9] |[format "%7d" $R10] |[format "%7d" $R11] |"
      puts "[format "%7d" $R12] |[format "%7d" $R13] |[format "%7d" $R14] |[format "%7d" $R15] |"
      puts "-------------------------------------------------------------------------"
      puts -nonewline "|"

      for {set j 8} {$j < 16} {incr j}  {
            puts -nonewline "[format "%7d" $HistComboPerStrmInfo($i.u64Frames.$j.low)] |"
      }

      puts ""
      puts "-------------------------------------------------------------------------"
      puts "Press ENTER key for next stream data"

      gets stdin response
}

#Unset the structure
unset HistComboPerStrmInfo

puts "UnLinking from the chassis now.."
ETUnLink
puts ""
puts "DONE!"

