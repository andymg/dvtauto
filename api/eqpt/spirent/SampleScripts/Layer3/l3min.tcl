############################################################
# L3Min.tcl                                                #
# - Basic streams set up transmit and capture              #
#                                                          #
# NOTE: This script works on the following cards:          #
#       - L3-67XX                                          #
#       - ML-7710                                          #
#       - ML-5710                                          #
#       - LAN-6101A                                        #
#                                                          #
############################################################

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

set iHub        0
set iSlot       0
set iPort       0

set iHub2       0
set iSlot2      1
set iPort2      0 

set numFrames 5
set dataLength 60
set num2Add 3

# Reserve and reset cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

LIBCMD HTResetPort $::RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $::RESET_FULL $iHub2 $iSlot2 $iPort2	

# set up ip streams - no structure def needed
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $iHub $iSlot $iPort\
-ucActive       1 \
-ucProtocolType $L3_STREAM_IP \
-uiFrameLength  $dataLength \
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

# increment IPs by one and MACs by 2
struct_new ip StreamIP
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 $num2Add 0 ip 0 $iHub $iSlot $iPort \
-DestinationMAC {0 0 0 0 0 2} \
-SourceMAC      {0 0 0 0 0 2} \
-DestinationIP  {0 0 0 1} \
-SourceIP       {0 0 0 1}
unset ip

###########################################################
# start ARPs                                              #
###########################################################

LIBCMD HTSetCommand $L3_START_ARPS 0 0 0 "" $iHub $iSlot $iPort
LIBCMD HTSetCommand $L3_START_ARPS 0 0 0 "" $iHub2 $iSlot2 $iPort2

#######################################################################
# setup transmit - sets to send a single burst of $numFrames packets  #
#######################################################################

LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $numFrames $iHub $iSlot $iPort
LIBCMD HTDataLength $dataLength $iHub $iSlot $iPort

###########################################################
# fill in background data - fill with all AA              #
###########################################################

struct_new filldata Int*$dataLength
for {set i 0} {$i < $dataLength} {incr i} {
      set filldata($i.i) 0xAA
}

LIBCMD HTFillPattern $dataLength filldata $iHub $iSlot $iPort

unset filldata

# capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $iHub2 $iSlot2 $iPort2
unset cap

# start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $iHub2 $iSlot2 $iPort2
after 2000

# send data for two seconds
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
after 2000
LIBCMD HTRun $HTSTOP $iHub $iSlot $iPort

# stop capture
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2

# get capture count - gets number captured (used below)
struct_new capCount NSCaptureCountInfo
struct_new capData NSCaptureDataInfo

LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 capCount 0 $iHub2 $iSlot2 $iPort2
puts "Capture count = $capCount(ulCount)"

# display captured data
for {set i 0} {$i < $capCount(ulCount)} {incr i} {
	puts ""
	puts "---------"
	puts "FRAME $i"
	puts "---------"
	set capData(ulFrameIndex)      $i
	LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 capData 0 $iHub2 $iSlot2 $iPort2
	for {set j 0} {$j < [expr $dataLength + 4]} {incr j} {
		if {[expr $j % 16] == 0} {
			puts ""
			puts -nonewline [format "%4i:   " $j]
		}
        puts -nonewline " [format "%02X" $capData(ucData.$j._ubyte_)]" 
 
	}

	puts ""
	puts "\nPress RETURN key for more"
	gets stdin response

	
}

#Unset the structures
unset capCount
unset capData

puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"



