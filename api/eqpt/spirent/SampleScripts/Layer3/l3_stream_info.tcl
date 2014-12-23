#########################################################################
#L3_STREAM_INFO.TCL                                                     #
#                                                                       #
# - Sets up 1 IP stream on a L3 Card and then reads back and displays   #
#   the card data on a ML-7710.                                         #
#                                                                       #
# NOTE: This script works on the following cards:                       #
#       - L3-67XX                                                       #
#       - ML-7710                                                       #
#       - ML-5710                                                       #
#       - LAN-6101A                                                     #
#       - LAN-6201A                                                     #
#       - LAN-3300A/3301A                                               #
#       - LAN-3310A/3311A                                               #
#       - POS-6500/6502                                                 #
#       - POS-3505A/3504As                                              #
#                                                                       #
#########################################################################

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

set iHub 0
set iSlot 0
set iPort 0

set STREAM 1

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

#######################################################################
# Set up base IP stream with L3_DEFINE_IP_STREAM                      #
#                                                                     #
# - Numbers are chosen to make the data field locations               #
#   more obvious in the display.  Dest MAC is 06 07 05 04 03 02       #
# - Source MAC is 05 04 03 02 01 00 and so on.                        #
#                                                                     #
#######################################################################


# Set card at $iHub $iSlot $iPort

LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $iHub $iSlot $iPort \
-ucActive        1 \
-ucProtocolType  $L3_STREAM_IP \
-uiFrameLength   100 \
-ucRandomLength  1 \
-ucTagField      1 \
-DestinationMAC  {6 7 5 4 3 2} \
-SourceMAC       {5 3 3 2 1 0} \
-TimeToLive      10 \
-DestinationIP   {0x11 0x22 0x33 0x44} \
-SourceIP        {0x55 0x66 0x77 0x88} \
-Netmask       {0xAA 0xBB 0xCC 0} \
-Gateway         {0xDD 0xEE 0xFF 0} \
-Protocol        4

#####################################
# Check for number of streams       #
# using L3_DEFINED_STREAM_COUNT_INFO#
# This program only sets up only one#
# stream.                           #
# There is one non-transmitting     #
# stream always on the card         #
# used to hold card data so the     #
# count of transmitting streams will#
# always be one less than the total #
# reported.                         #
#####################################

struct_new StreamCount  ULong

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort
if { $StreamCount(ul)  < 2 } {
     puts "No streams on card"
}

 unset StreamCount

############################################
# set up a SmartBits type structure to hold#
# card configuration data.                 #
# All streams use the SmartBits type for   #
# the L3_STREAM_INFO command               #
############################################

struct_new SB StreamSmartBits

############################################
# Get stream data for stream 1 count 1     #
# Stream 0 is the "hidden" stream          #
############################################

LIBCMD HTGetStructure $L3_STREAM_INFO $STREAM 0 0 SB 0 $iHub $iSlot $iPort


puts ""
puts "Stream $STREAM"

puts -nonewline " Stream type is "
	switch $SB(ucProtocolType) {
	0 { puts "SmartBits"}
	2 { puts "IP"}
	3 { puts "IPX"}
	4 { puts "UDP"}
	5 { puts "ARP"}
	8 { puts "TCP"}
	default {puts "unknown"}
	}
puts " Frame length is $SB(uiFrameLength) bytes"

################################################
# ProtocolHeader area will contain the ENet and#
# IP data fields.                              #
################################################
puts ""
puts "-----------------------------------------"
puts "       Protocol Data     "
puts "-----------------------------------------"
for {set i 0} {$i < 64} {incr i} {
	if { [expr $i % 16] == 0 } {
		puts ""
	}
	set MyByte $SB(ProtocolHeader.$i)
	puts -nonewline " [format %02X  $MyByte] "
}
puts ""
unset SB

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
