##########################################################################################
# L3_V2_HIST_LAT.TCL                                                                     #
#                                                                                        #
# - This program will set up a series of streams (externally by sourcing ipstream.tcl),  #
#   then transmit a burst of packets and display the distribution.                       #
#                                                                                        #
# NOTE: This script works on the following cards:                                        #
#       - L3-67XX                                                                        #
#       - ML-7710                                                                        #
#       - ML-5710                                                                        #
#       - LAN-6101A                                                                      #
#       - LAN-6201A/B                                                                    #
#       - LAN-3300A/3301A                                                                #
#       - LAN-3310A/3311                                                                 #
#       - POS-3505A/3504A                                                                #
#       - POS-6500/6502                                                                  #
#                                                                                        #
##########################################################################################

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


########################################################
# Set Variables                                        #
# iHub iSlot iPort is Tx; iHub2 iSlot2 iPort2 is Rx    #
# NUM_INTERVALS is the number of latency time slots    #
# BURST_SIZE is the number of packets that will be sent#
# INTERVAL_SIZE is the range of each interval in mS    #
########################################################

set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

set NUM_INTERVALS 10
set BURST_SIZE 128
set INTERVAL_SIZE 1
set DATA_LENGTH 60

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2


#set up streams
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $iHub $iSlot $iPort\
-ucActive       1 \
-ucProtocolType $L3_STREAM_IP \
-uiFrameLength  $DATA_LENGTH \
-ucRandomLength 0 \
-ucTagField     1 \
-DestinationMAC {0 0 0 0 1 0} \
-SourceMAC      {0 0 0 0 0 1} \
-TimeToLive     10 \
-DestinationIP  {192 158 100 1} \
-SourceIP       {192 148 100 1} \
-Netmask        {255 255 255 0} \
-Gateway        {192 148 100 1} \
-Protocol       4

struct_new ip StreamIP
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 5 0 ip 0 $iHub $iSlot $iPort \
-DestinationMAC {0 0 0 0 0 3} \
-SourceMAC      {0 0 0 0 0 2} \
-DestinationIP  {0 0 0 1} \
-SourceIP       {0 0 0 1}
unset ip

#############################################
# Check for L3 streams.  Test will not      #
# work if there are no streams transmitting #
# The DEFINED_STREAM_COUNT will return the  #
# total stream count (including the first,  #
# hidden stream, so we have to adjust the   #
# count to show the count of transmitting   #
# streams.                                  #
#############################################

struct_new StreamCount ULong

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort
if {  $StreamCount(ul) < 1 } {
  puts "No L3 streams on card - Aborting Test!"
  exit
} else {
  puts "Testing with [expr $StreamCount(ul) - 1] streams"
}
unset StreamCount


########################################################
# Set L3_HIST_V2_LATENCY with 1 * 1ms or 1mS interval  #
# Since we are transmitting from card 1 to card 2, the # 
# latency test gets set on the Rx card, Card 2.        #
########################################################
struct_new MyL3HistLatency Layer3HistLatency
set MyL3HistLatency(ulInterval) $INTERVAL_SIZE
LIBCMD HTSetCommand $L3_HIST_V2_LATENCY 0 0 0 MyL3HistLatency $iHub2 $iSlot2 $iPort2


############################################################
# Send a single burst of $BURST_SIZE packets. Card 1 is Tx #
############################################################
HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
HTBurstCount $BURST_SIZE $iHub $iSlot $iPort


HTRun $HTRUN $iHub $iSlot $iPort
after 2000

struct_new test_info Layer3HistActiveTest

# Check that the histogram test setup on the port and the number of
# records generated by the test is correct
LIBCMD HTGetStructure $L3_HIST_ACTIVE_TEST_INFO 0 0 0 test_info 0\
                   $iHub2 $iSlot2 $iPort2


puts "Check the histogram test and number of records generated...\n"
if {$test_info(ulTest) != $HIST_LONG_LAT_TIME} {
    puts "6(HIST_LONG_LAT_TIME) $test_info(ulTest) \
    \nHistogram test on the port\
    \nThe histogram test reported is incorrect"
}


##############################################################
# Create structure to hold the latency data and get the data #
# from the Rx card, Card2.  One structure per bucket.        #
##############################################################

struct_new MyLongLatencyInfo Layer3LongLatencyInfo*$test_info(ulRecords)
LIBCMD HTGetStructure $L3_HIST_V2_LATENCY_INFO 0 0 0 MyLongLatencyInfo 0 \
                    $iHub2 $iSlot2 $iPort2

###########################################################
# Print out the test results - first the header           #
###########################################################
puts ""
puts " TEST RESULTS - LATENCY DISTRIBUTION ($BURST_SIZE) FRAMES"
puts "======================================================="
puts " Latency Range	 Number of Frames    % of Total"
puts "======================================================="

########################################################
# Calculate the ranges based on value of INTERVAL_SIZE #
########################################################

for {set i 0} {$i < $test_info(ulRecords)} {incr i} {
    set START_RANGE [format "%2d" [expr $INTERVAL_SIZE * $i]]
    set END_RANGE [format "%2d" [expr $START_RANGE + $INTERVAL_SIZE]]

    ##################################
    # Print out the range in mS      #
    ##################################

    puts -nonewline " $START_RANGE to $END_RANGE mS"

    ###############################################################################
    # If we have packets in the interval, print the number and the % of the whole #
    # format used to set output - BURST_SIZE * 0.1 to force a float               #
    ###############################################################################

    if {$MyLongLatencyInfo($i.ulFrames) > 0} {
        puts -nonewline "  ==>  [format "%3d" $MyLongLatencyInfo($i.ulFrames)] frames "
        puts "        [format "%3.2f" [expr ($MyLongLatencyInfo($i.ulFrames)/($BURST_SIZE * 1.0)) * 100]]%"

        ###############################################
        # No packets in this interval - print nothing #
        ###############################################

     } else {
         puts ""
     }
  puts "-------------------------------------------------------"
}

#Unset the structures
unset test_info
unset MyL3HistLatency
unset MyLongLatencyInfo

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"


