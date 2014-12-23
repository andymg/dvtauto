###################################################################
# L3_HIST_RAW_TAGS.TCL                                            #
#                                                                 #
# - This program will set up a series of streams (externally      #
#   by sourcing ipstream.tcl), then transmit a burst of packets   #
#   and display the distribution.                                 #
#                                                                 #
# NOTE: This script works on the following cards:                 #
#       - L3-67XX                                                 #
#       - ML-7710                                                 #
#       - ML-5710                                                 #
#       - LAN-6101A                                               #
#       - LAN-3300A/3301A                                         #
#       - LAN-3310A/3311A                                         #
#       - POS-6500/6502                                           #
#       - POS-3505A/3504                                          #
#                                                                 #
###################################################################

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
########################################################

set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

set BURST_SIZE 30
set num2Add 9
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
-Protocol 4

struct_new ip StreamIP
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 $num2Add 0 ip 0 $iHub $iSlot $iPort \
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

struct_new StreamCount  ULong
LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort

set TXStreams $StreamCount(ul)
if {  $TXStreams < 1 } {
     puts "No L3 streams on card - Aborting Test!"
     exit
} else {
         puts "Testing with [expr $StreamCount(ul) - 1] streams"
}

unset StreamCount

########################################################
# Set L3_HIST_RAW_TAGS (no related structure)          #
########################################################

LIBCMD HTSetCommand $L3_HIST_RAW_TAGS 0 0 0 NULL $iHub2 $iSlot2 $iPort2

########################################
# set group of TX and RX cards         #
########################################

LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2
LIBCMD HGStop

############################################################
# Send a single burst of $BURST_SIZE packets. Card 1 is Tx #
############################################################

LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

after 1000

##############################################################
# Create structure to hold the tag data and get the data     #
# from the Rx card, Card2.  One structure per tag.           #
##############################################################

struct_new MyL3HistTagInfo Layer3HistTagInfo*$BURST_SIZE

LIBCMD HTGetStructure $L3_HIST_RAW_TAGS_INFO 0 $TXStreams 0 MyL3HistTagInfo 0 $iHub2 $iSlot2 $iPort2

for {set i 0} {$i < $BURST_SIZE} {incr i} {
	puts "Stream $MyL3HistTagInfo($i.ulStream)"
	puts "  TX time  $MyL3HistTagInfo($i.ulTransmitTime)"
	puts "  RX time  $MyL3HistTagInfo($i.ulReceiveTime)"
	puts "Latency TX to RX is [expr $MyL3HistTagInfo($i.ulReceiveTime) - $MyL3HistTagInfo($i.ulTransmitTime)] 1/10 uS"
	puts ""
	puts " Press ENTER to continue"
	gets stdin response
}

unset MyL3HistTagInfo

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
